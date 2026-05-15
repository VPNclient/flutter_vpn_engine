
import 'flutter_h2_platform_interface.dart';

class FlutterH2 {
  Future<String?> getPlatformVersion() {
    return FlutterH2Platform.instance.getPlatformVersion();
  }
}
