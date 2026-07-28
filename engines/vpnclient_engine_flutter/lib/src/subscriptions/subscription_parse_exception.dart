/// Thrown when no registered `SubscriptionParser` recognizes a fetched
/// subscription body. In practice unreachable while `ShareLinkListParser` is
/// the only registered parser (its `canParse` always returns `true`) — kept
/// for shape parity with `flutter_vpnclient_engine_mock` and in case a
/// future parser is registered with real rejection behavior.
class SubscriptionParseException implements Exception {
  SubscriptionParseException(this.message);

  final String message;

  @override
  String toString() => 'SubscriptionParseException: $message';
}
