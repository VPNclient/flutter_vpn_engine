import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_h2/flutter_h2.dart';
import 'package:flutter_h2/flutter_h2_platform_interface.dart';
import 'package:flutter_h2/flutter_h2_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterH2Platform
    with MockPlatformInterfaceMixin
    implements FlutterH2Platform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterH2Platform initialPlatform = FlutterH2Platform.instance;

  test('$MethodChannelFlutterH2 is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterH2>());
  });

  test('getPlatformVersion', () async {
    FlutterH2 flutterH2Plugin = FlutterH2();
    MockFlutterH2Platform fakePlatform = MockFlutterH2Platform();
    FlutterH2Platform.instance = fakePlatform;

    expect(await flutterH2Plugin.getPlatformVersion(), '42');
  });
}
