import 'package:meta/meta.dart';

/// Ported from the real `subscription_manager.dart`'s `PingResult`
/// (`subscriptionIndex`/`serverIndex` → stable string ids, matching this
/// package's id-addressed `Subscription`/`Server`). The real
/// `Socket.connect`+`Stopwatch` timing behind `SubscriptionManager.pingServer`
/// is unchanged — only the addressing scheme moved.
@immutable
class PingResult {
  const PingResult({
    required this.subscriptionId,
    required this.serverId,
    required this.latencyMs,
    required this.success,
    this.error,
  });

  final String subscriptionId;
  final String serverId;

  /// -1 when [success] is false.
  final int latencyMs;
  final bool success;
  final String? error;
}
