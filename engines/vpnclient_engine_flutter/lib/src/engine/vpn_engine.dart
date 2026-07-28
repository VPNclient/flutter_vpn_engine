import 'dart:async';

import 'package:flutter/services.dart';

import '../core/engine_manager.dart';
import '../cores/core_type.dart';
import '../drivers/driver_type.dart';
import '../models/config.dart';
import '../models/connection_stats.dart' as native;
import '../models/connection_status.dart' as native;
import '../platform/vpn_engine_platform.dart';
import '../subscriptions/server.dart';
import '../subscriptions/server_definition.dart';
import '../v2ray_url_parser.dart';
import 'connection_state.dart';
import 'connection_stats.dart';

/// Real, FFI-backed connect/disconnect/stats — matches
/// `flutter_vpnclient_engine_mock`'s `VpnEngine` shape for the portable
/// subset only. No `EngineCapabilities` constructor param (Gap — not built);
/// no core/driver priority or enable/disable API (Gap — not built).
///
/// Wraps the real, unchanged `VpnEnginePlatform`/`VpnEngineBindings` (FFI to
/// the native `vpnclient_engine_*` C ABI) — ported from the original
/// `VpnClientEngine` (V1, the one with real working connect/disconnect;
/// V2's own native start/stop was stubbed and is archived, unused, in
/// `lib/src/legacy_v2/`). Also ports V1's real `MethodChannel`
/// `onStatusChanged`/`onStatsUpdated` handling for native-pushed async
/// updates, alongside its own optimistic local updates around connect/
/// disconnect.
class VpnEngine {
  VpnEngine() : _platform = VpnEnginePlatform() {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  static const MethodChannel _channel = MethodChannel('vpnclient_engine');

  final VpnEnginePlatform _platform;

  // --- Connection lifecycle ---

  VpnConnectionState _state = const Disconnected();
  final _stateController = StreamController<VpnConnectionState>.broadcast();

  VpnConnectionState get state => _state;
  Stream<VpnConnectionState> get stateStream => _stateController.stream;

  void _setState(VpnConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Connects using [server]'s definition.
  ///
  /// [coreOverride] is nullable in the signature to match the mock's shape,
  /// but is **required** in practice: this engine has no core-priority/
  /// default-selection concept to fall back to (the real engine never had
  /// one either — `VpnEngineConfig.core.type` was always a required,
  /// explicit field before this port existed).
  ///
  /// Only [ShareLinkDefinition] servers can be connected to: assembling a
  /// config JSON from a typed [FullConfigDefinition] has no existing real
  /// implementation to port from (the real parser only ever goes
  /// share-link → JSON, never the other direction).
  Future<void> connect(
    Server server, {
    CoreType? coreOverride,
    DriverType? driverOverride,
  }) async {
    if (coreOverride == null) {
      throw ArgumentError(
        'coreOverride is required — this engine has no core-priority/'
        'default-selection concept',
      );
    }
    final definition = server.definition;
    if (definition is! ShareLinkDefinition) {
      throw UnsupportedError(
        'Only share-link-defined servers can be connected to — assembling a '
        'config JSON from a typed ProtocolConfig has no existing real '
        'implementation to port from',
      );
    }

    final v2rayUrl = parseV2RayURL(definition.raw);
    if (v2rayUrl == null) {
      throw FormatException('Failed to parse server share-link: ${definition.raw}');
    }
    final configJson = v2rayUrl.getFullConfiguration();
    final driver = driverOverride ?? EngineManager.getRecommendedDriver(coreOverride);

    final config = VpnEngineConfig(
      core: CoreConfig(type: coreOverride, configJson: configJson),
      driver: DriverConfig(type: driver ?? DriverType.none),
    );

    _setState(const Connecting());

    bool connected;
    try {
      final initialized = _platform.initialize(config);
      connected = initialized && await _platform.connect();
    } catch (_) {
      connected = false;
    }

    if (!connected) {
      final nativeErrorCode = _bestEffortNativeErrorCode();
      _setState(ConnectionFailed(
        'Native engine reported an error',
        nativeErrorCode: nativeErrorCode,
      ));
      return;
    }

    _setState(Connected(DateTime.now()));
    _startStatsPolling();
  }

  Future<void> disconnect() async {
    _setState(const Disconnecting());
    _stopStatsPolling();
    try {
      _platform.disconnect();
    } catch (_) {
      // Real disconnect() is otherwise void/best-effort — matches V1.
    }
    _setState(const Disconnected());
  }

  /// One best-effort extra call to the real (previously-unused-by-V1)
  /// `getStatus()` binding, purely to populate `ConnectionFailed
  /// .nativeErrorCode` with a real raw status int. V1 itself never called
  /// this for its own connect() failures (see 02-specifications.md's v1.1
  /// correction) — this is a thin, justified extension of already-real
  /// capability, not new business logic. Returns null if the call itself
  /// throws.
  int? _bestEffortNativeErrorCode() {
    try {
      return _platform.getStatus().index;
    } catch (_) {
      return null;
    }
  }

  // --- Stats ---

  ConnectionStats? _stats;
  final _statsController = StreamController<ConnectionStats>.broadcast();
  Timer? _statsTimer;
  int _previousBytesSent = 0;
  int _previousBytesReceived = 0;

  ConnectionStats? get stats => _stats;
  Stream<ConnectionStats> get statsStream => _statsController.stream;

  void _startStatsPolling() {
    _previousBytesSent = 0;
    _previousBytesReceived = 0;
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) => _pollStats());
  }

  void _pollStats() {
    native.ConnectionStats raw;
    try {
      raw = _platform.getStats();
    } catch (_) {
      return;
    }
    final stats = ConnectionStats(
      bytesSentTotal: raw.bytesSent,
      bytesReceivedTotal: raw.bytesReceived,
      currentUploadBytesPerSecond: (raw.bytesSent - _previousBytesSent).toDouble(),
      currentDownloadBytesPerSecond: (raw.bytesReceived - _previousBytesReceived).toDouble(),
      latency: Duration(milliseconds: raw.latencyMs),
    );
    _previousBytesSent = raw.bytesSent;
    _previousBytesReceived = raw.bytesReceived;
    _stats = stats;
    _statsController.add(stats);
  }

  void _stopStatsPolling() {
    _statsTimer?.cancel();
    _statsTimer = null;
    _stats = null;
  }

  // --- Real MethodChannel callbacks (native-pushed async updates) ---
  // Ported from V1's `_setupMethodCallHandler`.

  Future<void> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onStatusChanged':
        final status = native.ConnectionStatus.fromString(call.arguments as String);
        _setState(vpnConnectionStateFromStatus(status));
        break;
      case 'onStatsUpdated':
        final map = Map<String, dynamic>.from(call.arguments as Map);
        final raw = native.ConnectionStats.fromMap(map);
        final stats = ConnectionStats(
          bytesSentTotal: raw.bytesSent,
          bytesReceivedTotal: raw.bytesReceived,
          currentUploadBytesPerSecond: (raw.bytesSent - _previousBytesSent).toDouble(),
          currentDownloadBytesPerSecond: (raw.bytesReceived - _previousBytesReceived).toDouble(),
          latency: Duration(milliseconds: raw.latencyMs),
        );
        _previousBytesSent = raw.bytesSent;
        _previousBytesReceived = raw.bytesReceived;
        _stats = stats;
        _statsController.add(stats);
        break;
    }
  }

  Future<void> dispose() async {
    _stopStatsPolling();
    await _stateController.close();
    await _statsController.close();
    _platform.dispose();
  }
}
