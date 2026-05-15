import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_h2_platform_interface.dart';

/// An implementation of [FlutterH2Platform] that uses method channels.
class MethodChannelFlutterH2 extends FlutterH2Platform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_h2');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
