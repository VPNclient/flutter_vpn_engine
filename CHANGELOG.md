# Changelog

## [1.0.0] - 2025-10-21

### 🎉 Initial Release

Полная переработка VPN движка с унификацией всех компонентов.

### ✨ Features

#### Поддержка платформ
- ✅ Android (API 21+)
- ✅ iOS (12.0+)
- ✅ Windows (NEW!)
- ✅ Linux (NEW!)
- ✅ macOS

#### VPN Cores (Ядра)
- ✅ SingBox - современное VPN ядро
- ✅ LibXray - Xray-core обертка
- ✅ V2Ray - классический V2Ray
- ✅ WireGuard - быстрый и безопасный протокол

#### Drivers (Драйверы)
- ✅ HevSocks5 - hev-socks5-tunnel для туннелирования
- ✅ Tun2Socks - альтернативный драйвер туннелирования
- ✅ None - прямое подключение без драйвера

#### API Features
- ✅ **Subscription Management**: Работа с подписками серверов
  - Добавление/удаление подписок
  - Автоматическое обновление
  - Парсинг server lists
  
- ✅ **V2Ray URL Parser**: Полная поддержка V2Ray share links
  - VMess (`vmess://`)
  - VLess (`vless://`)
  - Trojan (`trojan://`)
  - Shadowsocks (`ss://`)
  - Socks (`socks://`)
  
- ✅ **Ping & Latency**: Измерение задержки серверов
  - Асинхронный ping
  - Stream с результатами
  - Сортировка по latency
  
- ✅ **Connection Stats**: Детальная статистика
  - Отправлено/получено байт
  - Отправлено/получено пакетов
  - Latency в реальном времени
  - Форматированный вывод (KB, MB, GB)
  
- ✅ **Callbacks & Streams**: Реактивное API
  - Status callbacks
  - Stats callbacks
  - Log callbacks
  - Stream-based API для всех событий

#### Обратная совместимость
- ✅ Legacy API для миграции с `vpnclient_engine_flutter`
- ✅ Алиас классов (`VpnclientEngineFlutter`)
- ✅ Совместимые enum'ы

### 📦 Architecture

```
flutter_vpn_engine/
├── lib/
│   ├── src/
│   │   ├── models/          # Модели данных
│   │   ├── platform/        # Platform interfaces
│   │   ├── subscription_manager.dart
│   │   ├── v2ray_url_parser.dart
│   │   ├── vpnclient_engine.dart
│   │   └── legacy_api.dart  # Обратная совместимость
│   └── vpnclient_engine.dart
├── android/                 # Android platform code
├── ios/                     # iOS platform code
├── windows/                 # Windows platform code (NEW!)
├── linux/                   # Linux platform code (NEW!)
├── src/                     # C++ engine implementation
│   ├── core/               # Main engine
│   ├── cores/              # VPN cores
│   └── drivers/            # Tunnel drivers
├── include/                # C++ headers
└── example/                # Example app
```

### 🔄 Migration

Для миграции с предыдущих версий см. [MIGRATION.md](MIGRATION.md).

### 📚 Documentation

- [README.md](README.md) - Основная документация
- [MIGRATION.md](MIGRATION.md) - Гайд по миграции
- [BUILD.md](BUILD.md) - Инструкции по сборке

### 🐛 Bug Fixes

- Исправлены memory leaks в C++ коде
- Улучшена стабильность на iOS
- Исправлены race conditions в subscription manager

### 🔧 Technical Details

#### Dependencies
- `ffi: ^2.1.0` - FFI для нативного кода
- `plugin_platform_interface: ^2.1.7` - Platform interface
- `http: ^1.2.0` - HTTP requests для subscriptions

#### Build Requirements
- **Android**: Gradle 7.0+, NDK 25+
- **iOS**: Xcode 14+, Swift 5.5+
- **Windows**: Visual Studio 2019+, CMake 3.10+
- **Linux**: GCC 9+, CMake 3.10+, GTK 3.0+

### 📝 Notes

Это мажорный релиз с breaking changes. Рекомендуется тщательное тестирование перед продакшн деплоем.

### 👥 Contributors

VPNclient Team

### 📄 License

MIT License - см. [LICENSE](LICENSE)

