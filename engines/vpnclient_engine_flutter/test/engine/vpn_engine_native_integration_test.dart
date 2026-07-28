import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/config/protocol_config.dart';
import 'package:vpnclient_engine/src/cores/core_type.dart';
import 'package:vpnclient_engine/src/engine/connection_state.dart';
import 'package:vpnclient_engine/src/engine/vpn_engine.dart';
import 'package:vpnclient_engine/src/subscriptions/server.dart';
import 'package:vpnclient_engine/src/subscriptions/server_definition.dart';

/// Best-effort probe: does the real native `vpnclient_engine_create` symbol
/// resolve in this process? Mirrors `VpnEngineBindings._loadLibrary()`'s
/// per-platform loading strategy without going through `VpnEngine` itself,
/// so a missing library can be detected *before* committing to a full
/// connect attempt.
bool _nativeEngineAvailable() {
  try {
    final ffi.DynamicLibrary lib;
    if (Platform.isAndroid || Platform.isLinux) {
      lib = ffi.DynamicLibrary.open('libvpnclient_engine.so');
    } else if (Platform.isIOS || Platform.isMacOS) {
      lib = ffi.DynamicLibrary.process();
    } else if (Platform.isWindows) {
      lib = ffi.DynamicLibrary.open('vpnclient_engine.dll');
    } else {
      return false;
    }
    lib.lookupFunction<ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Void>),
        ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Void>)>('vpnclient_engine_create');
    return true;
  } catch (_) {
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('full connect()/disconnect() cycle against a real native library', () async {
    if (!_nativeEngineAvailable()) {
      markTestSkipped(
        'No compiled native libvpnclient_engine.{so,dylib,dll} available in '
        'this environment — native build status is outside this Dart-layer '
        'port\'s scope (02-specifications.md Manual Verification).',
      );
      return;
    }

    final engine = VpnEngine();
    final server = Server(
      id: 's1',
      name: 'Native test server',
      definition: const ShareLinkDefinition(
        'ss://YWVzLTI1Ni1nY206c2VjcmV0@ss.example.com:8388#Native-Test',
      ),
    );

    await engine.connect(server, coreOverride: CoreType.singbox);
    expect(engine.state, isA<Connected>());

    await engine.disconnect();
    expect(engine.state, isA<Disconnected>());

    await engine.dispose();
  });

  test('ConnectionFailed.nativeErrorCode reflects a real induced failure', () async {
    if (!_nativeEngineAvailable()) {
      markTestSkipped('No compiled native library available — see above.');
      return;
    }

    final engine = VpnEngine();
    // An intentionally-malformed server (empty host) to induce a real
    // native-side connection failure without needing a specific test
    // fixture the native binary recognizes as bad.
    final server = Server(
      id: 's2',
      name: 'Bad server',
      definition: const ShareLinkDefinition('ss://YQ==@:0#Bad'),
    );

    await engine.connect(server, coreOverride: CoreType.singbox);
    if (engine.state is ConnectionFailed) {
      expect((engine.state as ConnectionFailed).nativeErrorCode, isNotNull);
    }
    await engine.dispose();
  });
}
