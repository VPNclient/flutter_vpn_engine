import '../subscription.dart';
import 'subscription_store.dart';

/// Ported from `flutter_vpnclient_engine_mock`'s `InMemorySubscriptionStore` —
/// for tests, no disk/plugin dependency.
class InMemorySubscriptionStore implements SubscriptionStore {
  List<Subscription> _subscriptions = const [];

  @override
  Future<List<Subscription>> load() async => List.of(_subscriptions);

  @override
  Future<void> save(List<Subscription> subscriptions) async {
    _subscriptions = List.of(subscriptions);
  }
}
