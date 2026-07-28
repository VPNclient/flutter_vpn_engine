import '../subscription.dart';

/// Ported verbatim from `flutter_vpnclient_engine_mock`'s `SubscriptionStore`
/// (anton, Resolved Decision 2 in flows/sdd-flutter-vpnclient-engine/
/// 01-requirements.md — pure `shared_preferences` I/O, nothing mock-specific,
/// so porting it here is reusing already-written, already-tested code).
abstract class SubscriptionStore {
  Future<List<Subscription>> load();

  Future<void> save(List<Subscription> subscriptions);
}
