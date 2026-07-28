import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../subscription.dart';
import 'subscription_store.dart';

/// Ported from `flutter_vpnclient_engine_mock`'s
/// `SharedPrefsSubscriptionStore` — default persistent store, a single JSON
/// blob in `shared_preferences` under [_key].
class SharedPrefsSubscriptionStore implements SubscriptionStore {
  static const _key = 'vpnclient_engine.subscriptions.v1';

  @override
  Future<List<Subscription>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> save(List<Subscription> subscriptions) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(subscriptions.map((s) => s.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}
