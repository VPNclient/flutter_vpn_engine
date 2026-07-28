import 'server.dart';

/// Matches `flutter_vpnclient_engine_mock`'s `SubscriptionParser` interface.
abstract class SubscriptionParser {
  const SubscriptionParser();

  bool canParse(String rawBody);

  List<Server> parse(String rawBody);
}
