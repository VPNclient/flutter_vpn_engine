import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_h2_method_channel.dart';

abstract class FlutterH2Platform extends PlatformInterface {
  /// Constructs a FlutterH2Platform.
  FlutterH2Platform() : super(token: _token);

  static final Object _token = Object();

  static FlutterH2Platform _instance = MethodChannelFlutterH2();

  /// The default instance of [FlutterH2Platform] to use.
  ///
  /// Defaults to [MethodChannelFlutterH2].
  static FlutterH2Platform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterH2Platform] when
  /// they register themselves.
  static set instance(FlutterH2Platform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
