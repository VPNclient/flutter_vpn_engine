# VPN Client Engine

**Единый интерфейс для работы с различными VPN ядрами и драйверами туннелирования.**

Полностью кроссплатформенное решение для Android, iOS, Windows, Linux и macOS.

## 🚀 Возможности

- ✅ **Множество VPN ядер**: SingBox, LibXray, V2Ray, WireGuard
- ✅ **Драйверы туннелирования**: HevSocks5, Tun2Socks
- ✅ **Кроссплатформенность**: Android, iOS, Windows, Linux, macOS
- ✅ **Subscription API**: Поддержка подписок с автообновлением
- ✅ **V2Ray URL Parser**: Парсинг vmess://, vless://, trojan://, ss://, socks://
- ✅ **Ping & Latency**: Измерение задержки серверов
- ✅ **Статистика**: Отслеживание трафика и соединения
- ✅ **Обратная совместимость**: Легаси API для миграции

## Архитектура

```
┌─────────────────────────────────────┐
│     VPNclient-green-app (Flutter)   │
└─────────────────┬───────────────────┘
                  │
        ┌─────────▼──────────┐
        │  flutter_vpn_engine │ ← Единая точка входа
        └─────────┬───────────┘
                  │
         ┌────────┴────────┐
         │                 │
    ┌────▼─────┐     ┌─────▼──────┐
    │ Drivers  │     │   Cores    │
    └────┬─────┘     └─────┬──────┘
         │                 │
    ┌────┼────┐       ┌────┼─────┬────────┐
    │    │    │       │    │     │        │
┌───▼┐ ┌─▼───┐   ┌───▼┐ ┌─▼───┐ ┌─▼─────┐
│Hev │ │Tun2 │   │Sing│ │LibX │ │V2Ray  │
│5   │ │Socks│   │Box │ │ray  │ │       │
└────┘ └─────┘   └────┘ └─────┘ └───────┘
```

## Основные компоненты

### 1. Драйверы (Drivers)
Драйверы отвечают за туннелирование трафика:
- **HevSocks5** - hev-socks5-tunnel
- **Tun2Socks** - tun2socks

### 2. Ядра (Cores)
Ядра отвечают за VPN протоколы:
- **SingBox** - sing-box
- **LibXray** - libxray
- **V2Ray** - v2ray

## Использование

### Установка

Добавьте в `pubspec.yaml`:

```yaml
dependencies:
  vpnclient_engine:
    path: ../flutter_vpn_engine
```

### Базовое использование

```dart
import 'package:vpnclient_engine/vpnclient_engine.dart';

// Создание конфигурации
final config = VpnEngineConfig(
  core: CoreConfig(
    type: CoreType.singbox,
    configJson: '''
    {
      "server": "example.com",
      "port": 443,
      "protocol": "vless"
    }
    ''',
  ),
  driver: DriverConfig(
    type: DriverType.hevSocks5,
    mtu: 1500,
  ),
);

// Получение экземпляра движка
final engine = VpnClientEngine.instance;

// Инициализация
await engine.initialize(config);

// Установка callbacks
engine.setStatusCallback((status) {
  print('VPN Status: $status');
});

engine.setLogCallback((level, message) {
  print('[$level] $message');
});

// Подключение
await engine.connect();

// Отключение
await engine.disconnect();
```

### Работа со streams

```dart
// Подписка на изменения статуса
engine.statusStream.listen((status) {
  print('Status changed: $status');
});

// Подписка на статистику
engine.statsStream.listen((stats) {
  print('Traffic: ${stats.formattedTotalBytes}');
  print('Latency: ${stats.latencyMs}ms');
});

// Подписка на логи
engine.logStream.listen((log) {
  print('[${log['level']}] ${log['message']}');
});
```

### Выбор ядра

```dart
// Использование SingBox
final config1 = VpnEngineConfig(
  core: CoreConfig(type: CoreType.singbox, configJson: '...'),
);

// Использование LibXray
final config2 = VpnEngineConfig(
  core: CoreConfig(type: CoreType.libxray, configJson: '...'),
);

// Использование V2Ray
final config3 = VpnEngineConfig(
  core: CoreConfig(type: CoreType.v2ray, configJson: '...'),
);
```

### Выбор драйвера

```dart
// Без драйвера (прямое подключение)
final config1 = VpnEngineConfig(
  core: CoreConfig(type: CoreType.singbox, configJson: '...'),
  driver: DriverConfig(type: DriverType.none),
);

// С HevSocks5
final config2 = VpnEngineConfig(
  core: CoreConfig(type: CoreType.singbox, configJson: '...'),
  driver: DriverConfig(
    type: DriverType.hevSocks5,
    mtu: 1500,
    tunAddress: '10.0.0.2',
  ),
);

// С Tun2Socks
final config3 = VpnEngineConfig(
  core: CoreConfig(type: CoreType.singbox, configJson: '...'),
  driver: DriverConfig(
    type: DriverType.tun2socks,
    mtu: 1500,
  ),
);
```

### Получение информации

```dart
// Имя ядра
final coreName = await engine.getCoreName();
print('Core: $coreName');

// Версия ядра
final coreVersion = await engine.getCoreVersion();
print('Version: $coreVersion');

// Имя драйвера
final driverName = await engine.getDriverName();
print('Driver: $driverName');

// Текущий статус
final status = engine.status;
print('Status: $status');

// Статистика
await engine.updateStats();
final stats = engine.stats;
print('Sent: ${stats.formattedBytesSent}');
print('Received: ${stats.formattedBytesReceived}');
```

## Примеры конфигураций

### SingBox + HevSocks5

```dart
final config = VpnEngineConfig(
  core: CoreConfig(
    type: CoreType.singbox,
    configJson: '''
    {
      "log": {"level": "info"},
      "inbounds": [{
        "type": "tun",
        "tag": "tun-in",
        "inet4_address": "172.19.0.1/30",
        "auto_route": true,
        "strict_route": true,
        "sniff": true
      }],
      "outbounds": [{
        "type": "vless",
        "server": "example.com",
        "server_port": 443,
        "uuid": "your-uuid",
        "flow": "xtls-rprx-vision",
        "tls": {
          "enabled": true,
          "server_name": "example.com"
        }
      }]
    }
    ''',
  ),
  driver: DriverConfig(
    type: DriverType.hevSocks5,
    mtu: 1500,
  ),
);
```

### LibXray + Tun2Socks

```dart
final config = VpnEngineConfig(
  core: CoreConfig(
    type: CoreType.libxray,
    configJson: '''
    {
      "log": {"loglevel": "info"},
      "inbounds": [{
        "port": 1080,
        "protocol": "socks",
        "settings": {"udp": true}
      }],
      "outbounds": [{
        "protocol": "vless",
        "settings": {
          "vnext": [{
            "address": "example.com",
            "port": 443,
            "users": [{
              "id": "your-uuid",
              "flow": "xtls-rprx-vision",
              "encryption": "none"
            }]
          }]
        },
        "streamSettings": {
          "network": "tcp",
          "security": "tls"
        }
      }]
    }
    ''',
  ),
  driver: DriverConfig(
    type: DriverType.tun2socks,
    mtu: 1500,
  ),
);
```

## Лицензия

MIT License - см. LICENSE файл

## Авторы

VPNclient Team
