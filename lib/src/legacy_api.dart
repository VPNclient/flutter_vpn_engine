import 'dart:async';
import 'vpnclient_engine.dart';
import 'subscription_manager.dart';

/// Legacy API wrapper for backward compatibility with vpnclient_engine_flutter
/// Provides static methods matching the old API
class VPNclientEngine {
  static final VpnClientEngine _engine = VpnClientEngine.instance;

  /// Clear all subscriptions
  static void ClearSubscriptions() {
    _engine.clearSubscriptions();
  }

  /// Add subscription
  static void addSubscription({required String subscriptionURL, String? name}) {
    _engine.addSubscription(subscriptionURL: subscriptionURL, name: name);
  }

  /// Update subscription
  static Future<bool> updateSubscription({required int subscriptionIndex}) {
    return _engine.updateSubscription(subscriptionIndex: subscriptionIndex);
  }

  /// Ping server
  static Future<void> pingServer({
    required int subscriptionIndex,
    required int index,
  }) {
    return _engine.pingServer(
      subscriptionIndex: subscriptionIndex,
      serverIndex: index,
    );
  }

  /// Stream of ping results
  static Stream<PingResult> get onPingResult => _engine.onPingResult;

  /// Connect to server
  static Future<void> connect({
    required int subscriptionIndex,
    required int serverIndex,
  }) async {
    await _engine.connectToServer(
      subscriptionIndex: subscriptionIndex,
      serverIndex: serverIndex,
    );
  }

  /// Disconnect
  static Future<void> disconnect() async {
    await _engine.disconnect();
  }

  /// Get engine instance for direct access
  static VpnClientEngine get instance => _engine;
}

/// Legacy class name for backward compatibility
class VpnclientEngineFlutter {
  static VpnClientEngine get instance => VpnClientEngine.instance;
}
