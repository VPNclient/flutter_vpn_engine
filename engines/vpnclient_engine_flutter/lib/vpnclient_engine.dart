/// VPN Client Engine - unified interface for VPN cores and drivers
library vpnclient_engine;

// Основной API (старая версия - для обратной совместимости)
export 'src/vpnclient_engine.dart';

// Новая версия API (рекомендуется для новых проектов)
export 'src/vpnclient_engine_v2.dart';

// Модели данных
export 'src/models/config.dart';
export 'src/models/connection_status.dart';
export 'src/models/connection_stats.dart';
export 'src/models/core_type.dart';
export 'src/models/driver_type.dart';
export 'src/models/tun_options.dart';
export 'src/models/platform_tun_handle.dart';

// Core компоненты
export 'src/core/engine_manager.dart';
export 'src/core/engine_config.dart';

// Platform Interface
export 'src/platform/unified_platform_interface.dart';
export 'src/platform/platform_interface_factory.dart';

// Утилиты
export 'src/subscription_manager.dart';
export 'src/v2ray_url_parser.dart';
export 'src/legacy_api.dart';
