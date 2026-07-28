import 'dart:io';
import 'unified_platform_interface.dart';
import 'android_platform_interface.dart';
import 'ios_platform_interface.dart';
import 'linux_platform_interface.dart';
import 'macos_platform_interface.dart';
import 'windows_platform_interface.dart';

/// Фабрика для создания платформо-специфичных реализаций UnifiedPlatformInterface
class PlatformInterfaceFactory {
  /// Создать экземпляр UnifiedPlatformInterface для текущей платформы
  static UnifiedPlatformInterface create() {
    if (Platform.isAndroid) {
      return AndroidPlatformInterface();
    } else if (Platform.isIOS) {
      return IOSPlatformInterface();
    } else if (Platform.isLinux) {
      return LinuxPlatformInterface();
    } else if (Platform.isMacOS) {
      return MacOSPlatformInterface();
    } else if (Platform.isWindows) {
      return WindowsPlatformInterface();
    } else {
      throw UnsupportedError(
        'Unsupported platform: ${Platform.operatingSystem}',
      );
    }
  }
}

