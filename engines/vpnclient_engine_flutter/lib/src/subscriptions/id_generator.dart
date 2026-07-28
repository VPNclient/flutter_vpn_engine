import 'dart:math';

/// Generates a globally-unique-enough string id. Ported from
/// `flutter_vpnclient_engine_mock`'s helper of the same name/shape.
String generateId(String prefix) {
  final random = Random();
  final suffix = List.generate(8, (_) => random.nextInt(16).toRadixString(16)).join();
  return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$suffix';
}
