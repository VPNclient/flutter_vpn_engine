# Migration Guide

## Миграция с vpnclient_engine_flutter на flutter_vpn_engine

Этот гайд поможет вам мигрировать с GitHub версии `vpnclient_engine_flutter` на унифицированный `flutter_vpn_engine`.

### Шаг 1: Обновите pubspec.yaml

**Старая версия:**
```yaml
dependencies:
  vpnclient_engine_flutter:
    git:
      url: https://github.com/VPNclient/VPNclient-engine-flutter.git
      ref: <commit-hash>
```

**Новая версия:**
```yaml
dependencies:
  vpnclient_engine:
    path: ../flutter_vpn_engine
    # или
    # git:
    #   url: https://github.com/yourorg/flutter_vpn_engine.git
```

### Шаг 2: Обновите импорты

**Старая версия:**
```dart
import 'package:vpnclient_engine_flutter/vpnclient_engine_flutter.dart';
```

**Новая версия:**
```dart
import 'package:vpnclient_engine/vpnclient_engine.dart';
```

### Шаг 3: Обновите использование API

#### Legacy API (обратная совместимость)

Если вы хотите минимальные изменения, используйте legacy API:

```dart
// Subscription management
VPNclientEngine.ClearSubscriptions();
VPNclientEngine.addSubscription(
  subscriptionURL: "https://example.com/subscription",
);
await VPNclientEngine.updateSubscription(subscriptionIndex: 0);

// Ping server
VPNclientEngine.pingServer(subscriptionIndex: 0, index: 1);
VPNclientEngine.onPingResult.listen((result) {
  print("Ping: ${result.latencyInMs}ms");
});

// Connect/Disconnect
await VPNclientEngine.connect(
  subscriptionIndex: 0,
  serverIndex: 1,
);
await VPNclientEngine.disconnect();
```

#### Modern API (рекомендуется)

Для новых проектов используйте современный API:

```dart
// Get engine instance
final engine = VpnClientEngine.instance;

// Initialize with configuration
final config = VpnEngineConfig(
  core: CoreConfig(
    type: CoreType.singbox,
    configJson: '{"server": "example.com", ...}',
  ),
  driver: DriverConfig(
    type: DriverType.hevSocks5,
    mtu: 1500,
  ),
);
await engine.initialize(config);

// Set callbacks
engine.setStatusCallback((status) {
  print('Status: $status');
});

engine.setLogCallback((level, message) {
  print('[$level] $message');
});

// Connect/Disconnect
await engine.connect();
await engine.disconnect();

// Subscription API
engine.addSubscription(subscriptionURL: "https://...");
await engine.updateSubscription(subscriptionIndex: 0);
await engine.pingServer(subscriptionIndex: 0, serverIndex: 1);

// Listen to ping results
engine.onPingResult.listen((result) {
  print("Ping: ${result.latencyInMs}ms");
});

// Connect to specific server
await engine.connectToServer(
  subscriptionIndex: 0,
  serverIndex: 1,
);
```

### Шаг 4: Обновите обработку статусов

**Старая версия:**
```dart
VpnclientEngineFlutter.instance.setStatusCallback((status) {
  // ConnectionStatus from vpnclient_engine_flutter
  switch (status) {
    case ConnectionStatus.disconnected: ...
    case ConnectionStatus.connecting: ...
    // ...
  }
});
```

**Новая версия (Legacy):**
```dart
// Используйте VpnclientEngineFlutter для обратной совместимости
VpnclientEngineFlutter.instance.setStatusCallback((status) {
  // Тот же ConnectionStatus
  switch (status) {
    case ConnectionStatus.disconnected: ...
    case ConnectionStatus.connecting: ...
    // ...
  }
});
```

**Новая версия (Modern):**
```dart
import 'package:vpnclient_engine/vpnclient_engine.dart' as vpn;

vpn.VpnClientEngine.instance.setStatusCallback((status) {
  // vpn.ConnectionStatus
  switch (status) {
    case vpn.ConnectionStatus.disconnected: ...
    case vpn.ConnectionStatus.connecting: ...
    // ...
  }
});
```

### Шаг 5: V2Ray URL Parsing

Теперь встроен парсинг V2Ray URL:

```dart
import 'package:vpnclient_engine/vpnclient_engine.dart';

// Parse V2Ray share link
final url = "vless://uuid@server:port?...";
final v2rayUrl = parseV2RayURL(url);

if (v2rayUrl != null) {
  print('Server: ${v2rayUrl.remark}');
  
  // Get V2Ray config JSON
  final configJson = v2rayUrl.getFullConfiguration();
  
  // Use in engine
  final config = VpnEngineConfig(
    core: CoreConfig(
      type: CoreType.v2ray,
      configJson: configJson,
    ),
  );
}
```

### Шаг 6: Убедитесь в наличии зависимостей

Добавьте `http` в pubspec.yaml, если используете subscription API:

```yaml
dependencies:
  http: ^1.2.0
```

### Платформенные изменения

#### Android

Нативный код теперь поддерживает все ядра. Убедитесь, что:
- AndroidManifest.xml имеет необходимые разрешения
- Минимальная версия SDK: 21+

#### iOS

- Добавлена поддержка Network Extensions
- Минимальная версия iOS: 12.0+

#### Windows & Linux

- Новая поддержка Windows и Linux!
- Требуется C++ компилятор
- CMake 3.10+

## Полный пример миграции

### До:

```dart
import 'package:vpnclient_engine_flutter/vpnclient_engine_flutter.dart';

class VpnProvider {
  void connect() async {
    VPNclientEngine.ClearSubscriptions();
    VPNclientEngine.addSubscription(
      subscriptionURL: "https://example.com/sub",
    );
    await VPNclientEngine.updateSubscription(subscriptionIndex: 0);
    await VPNclientEngine.connect(
      subscriptionIndex: 0,
      serverIndex: 0,
    );
  }
  
  void disconnect() async {
    await VPNclientEngine.disconnect();
  }
}
```

### После (Legacy API):

```dart
import 'package:vpnclient_engine/vpnclient_engine.dart';

class VpnProvider {
  void connect() async {
    VPNclientEngine.ClearSubscriptions();
    VPNclientEngine.addSubscription(
      subscriptionURL: "https://example.com/sub",
    );
    await VPNclientEngine.updateSubscription(subscriptionIndex: 0);
    await VPNclientEngine.connect(
      subscriptionIndex: 0,
      serverIndex: 0,
    );
  }
  
  void disconnect() async {
    await VPNclientEngine.disconnect();
  }
}
```

### После (Modern API):

```dart
import 'package:vpnclient_engine/vpnclient_engine.dart';

class VpnProvider {
  final _engine = VpnClientEngine.instance;
  
  void connect() async {
    _engine.clearSubscriptions();
    _engine.addSubscription(
      subscriptionURL: "https://example.com/sub",
    );
    await _engine.updateSubscription(subscriptionIndex: 0);
    await _engine.connectToServer(
      subscriptionIndex: 0,
      serverIndex: 0,
    );
  }
  
  void disconnect() async {
    await _engine.disconnect();
  }
}
```

## Troubleshooting

### Проблема: "ConnectionStatus не найден"

**Решение:** Используйте alias для импорта:
```dart
import 'package:vpnclient_engine/vpnclient_engine.dart' as vpn;

vpn.ConnectionStatus status = vpn.ConnectionStatus.disconnected;
```

### Проблема: "VpnclientEngineFlutter.instance не существует"

**Решение:** Используйте новый API:
```dart
// Вместо:
VpnclientEngineFlutter.instance

// Используйте:
VpnClientEngine.instance
// или legacy:
VpnclientEngineFlutter.instance  // Теперь доступен!
```

### Проблема: Ошибки компиляции на Windows/Linux

**Решение:** Убедитесь что:
1. Установлен CMake 3.10+
2. Установлен C++ компилятор (MSVC на Windows, GCC на Linux)
3. На Linux установлены GTK development libraries

## Поддержка

Если у вас возникли проблемы с миграцией, создайте issue в репозитории с описанием проблемы и примером кода.

