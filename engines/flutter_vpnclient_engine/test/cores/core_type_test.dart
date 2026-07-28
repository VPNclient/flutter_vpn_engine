import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/cores/core_type.dart';

void main() {
  test('needsExternalDriver matches the real EngineManager.requiresDriver behavior', () {
    expect(CoreType.singbox.needsExternalDriver, isFalse);
    expect(CoreType.libxray.needsExternalDriver, isTrue);
    expect(CoreType.v2ray.needsExternalDriver, isTrue);
    expect(CoreType.wireguard.needsExternalDriver, isFalse);
  });

  test('toNativeString/fromString round-trip (ported, unchanged)', () {
    for (final core in CoreType.values) {
      expect(CoreType.fromString(core.toNativeString()), core);
    }
  });
}
