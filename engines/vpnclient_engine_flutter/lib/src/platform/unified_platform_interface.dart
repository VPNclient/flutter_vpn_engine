import '../models/tun_options.dart';
import '../models/platform_tun_handle.dart';

/// Единый интерфейс для работы с TUN интерфейсом на всех платформах
/// Абстрагирует платформо-специфичные детали открытия и управления TUN
abstract class UnifiedPlatformInterface {
  /// Открыть TUN интерфейс с заданными опциями
  /// Возвращает handle для работы с TUN
  Future<PlatformTunHandle> openTun(TunOptions options);

  /// Закрыть TUN интерфейс
  Future<void> closeTun(PlatformTunHandle handle);

  /// Настроить маршруты для TUN интерфейса
  Future<void> setupRoutes(TunOptions options);

  /// Проверить наличие необходимых привилегий для работы с TUN
  Future<bool> checkPrivileges();

  /// Настроить per-app proxy (поддерживается только на Android)
  /// [packages] - список package names приложений
  /// [mode] - 'include' или 'exclude'
  Future<void> setupPerAppProxy({
    required List<String> packages,
    required String mode, // 'include' or 'exclude'
  });

  /// Очистить DNS кеш (если поддерживается платформой)
  Future<void> clearDNSCache();

  /// Получить список сетевых интерфейсов (для отладки)
  Future<List<NetworkInterfaceInfo>> getNetworkInterfaces();

  /// Освободить ресурсы
  void dispose();
}

/// Информация о сетевом интерфейсе
class NetworkInterfaceInfo {
  final String name;
  final String address;
  final int index;
  final int mtu;
  final bool isUp;

  const NetworkInterfaceInfo({
    required this.name,
    required this.address,
    required this.index,
    required this.mtu,
    required this.isUp,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'index': index,
      'mtu': mtu,
      'isUp': isUp,
    };
  }
}

