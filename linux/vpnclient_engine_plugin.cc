#include "vpnclient_engine_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>
#include <memory>
#include <string>

#include "../include/vpnclient_engine.h"

#define VPNCLIENT_ENGINE_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), vpnclient_engine_plugin_get_type(), \
                               VpnclientEnginePlugin))

struct _VpnclientEnginePlugin {
  GObject parent_instance;
  FlMethodChannel* channel;
  std::unique_ptr<vpnclient_engine::VPNClientEngine>* engine;
};

G_DEFINE_TYPE(VpnclientEnginePlugin, vpnclient_engine_plugin, g_object_get_type())

// Forward declarations
static FlMethodResponse* handle_method_call(VpnclientEnginePlugin* self,
                                            FlMethodCall* method_call);

// Convert Dart map to CoreConfig
vpnclient_engine::CoreConfig fl_value_to_core_config(FlValue* value) {
  vpnclient_engine::CoreConfig config;
  
  FlValue* type_value = fl_value_lookup_string(value, "type");
  if (type_value != nullptr && fl_value_get_type(type_value) == FL_VALUE_TYPE_STRING) {
    const gchar* type_str = fl_value_get_string(type_value);
    if (g_strcmp0(type_str, "singbox") == 0) {
      config.type = vpnclient_engine::CoreType::SINGBOX;
    } else if (g_strcmp0(type_str, "libxray") == 0) {
      config.type = vpnclient_engine::CoreType::LIBXRAY;
    } else if (g_strcmp0(type_str, "v2ray") == 0) {
      config.type = vpnclient_engine::CoreType::V2RAY;
    } else if (g_strcmp0(type_str, "wireguard") == 0) {
      config.type = vpnclient_engine::CoreType::WIREGUARD;
    }
  }
  
  FlValue* config_json_value = fl_value_lookup_string(value, "configJson");
  if (config_json_value != nullptr && fl_value_get_type(config_json_value) == FL_VALUE_TYPE_STRING) {
    config.config_json = fl_value_get_string(config_json_value);
  }
  
  return config;
}

// Convert Dart map to DriverConfig
vpnclient_engine::DriverConfig fl_value_to_driver_config(FlValue* value) {
  vpnclient_engine::DriverConfig config;
  
  FlValue* type_value = fl_value_lookup_string(value, "type");
  if (type_value != nullptr && fl_value_get_type(type_value) == FL_VALUE_TYPE_STRING) {
    const gchar* type_str = fl_value_get_string(type_value);
    if (g_strcmp0(type_str, "none") == 0) {
      config.type = vpnclient_engine::DriverType::NONE;
    } else if (g_strcmp0(type_str, "hevSocks5") == 0) {
      config.type = vpnclient_engine::DriverType::HEV_SOCKS5;
    } else if (g_strcmp0(type_str, "tun2socks") == 0) {
      config.type = vpnclient_engine::DriverType::TUN2SOCKS;
    }
  }
  
  FlValue* mtu_value = fl_value_lookup_string(value, "mtu");
  if (mtu_value != nullptr && fl_value_get_type(mtu_value) == FL_VALUE_TYPE_INT) {
    config.mtu = static_cast<uint16_t>(fl_value_get_int(mtu_value));
  }
  
  return config;
}

// Callbacks
static void on_status_changed(VpnclientEnginePlugin* self, vpnclient_engine::ConnectionStatus status) {
  const gchar* status_str;
  switch (status) {
    case vpnclient_engine::ConnectionStatus::DISCONNECTED:
      status_str = "disconnected";
      break;
    case vpnclient_engine::ConnectionStatus::CONNECTING:
      status_str = "connecting";
      break;
    case vpnclient_engine::ConnectionStatus::CONNECTED:
      status_str = "connected";
      break;
    case vpnclient_engine::ConnectionStatus::DISCONNECTING:
      status_str = "disconnecting";
      break;
    case vpnclient_engine::ConnectionStatus::ERROR:
      status_str = "error";
      break;
    default:
      status_str = "unknown";
  }
  
  g_autoptr(FlValue) result = fl_value_new_string(status_str);
  fl_method_channel_invoke_method(self->channel, "onStatusChanged", result, nullptr, nullptr, nullptr);
}

static void on_stats_updated(VpnclientEnginePlugin* self, const vpnclient_engine::ConnectionStats& stats) {
  g_autoptr(FlValue) stats_map = fl_value_new_map();
  fl_value_set_string_take(stats_map, "bytesSent", fl_value_new_int(stats.bytes_sent));
  fl_value_set_string_take(stats_map, "bytesReceived", fl_value_new_int(stats.bytes_received));
  fl_value_set_string_take(stats_map, "packetsSent", fl_value_new_int(stats.packets_sent));
  fl_value_set_string_take(stats_map, "packetsReceived", fl_value_new_int(stats.packets_received));
  fl_value_set_string_take(stats_map, "latencyMs", fl_value_new_int(stats.latency_ms));
  
  fl_method_channel_invoke_method(self->channel, "onStatsUpdated", stats_map, nullptr, nullptr, nullptr);
}

static void on_log(VpnclientEnginePlugin* self, const std::string& level, const std::string& message) {
  g_autoptr(FlValue) log_map = fl_value_new_map();
  fl_value_set_string_take(log_map, "level", fl_value_new_string(level.c_str()));
  fl_value_set_string_take(log_map, "message", fl_value_new_string(message.c_str()));
  
  fl_method_channel_invoke_method(self->channel, "onLog", log_map, nullptr, nullptr, nullptr);
}

// Method call handler
static void vpnclient_engine_plugin_handle_method_call(
    VpnclientEnginePlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);
  
  if (strcmp(method, "initialize") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGUMENT", "Arguments must be a map", nullptr));
    } else {
      vpnclient_engine::Config config;
      
      FlValue* core_value = fl_value_lookup_string(args, "core");
      if (core_value != nullptr && fl_value_get_type(core_value) == FL_VALUE_TYPE_MAP) {
        config.core = fl_value_to_core_config(core_value);
      }
      
      FlValue* driver_value = fl_value_lookup_string(args, "driver");
      if (driver_value != nullptr && fl_value_get_type(driver_value) == FL_VALUE_TYPE_MAP) {
        config.driver = fl_value_to_driver_config(driver_value);
      }
      
      // Create engine
      if (self->engine == nullptr) {
        self->engine = new std::unique_ptr<vpnclient_engine::VPNClientEngine>();
      }
      *self->engine = vpnclient_engine::VPNClientEngine::create(config);
      
      if (*self->engine) {
        // Set callbacks
        (*self->engine)->set_status_callback([self](vpnclient_engine::ConnectionStatus status) {
          on_status_changed(self, status);
        });
        (*self->engine)->set_stats_callback([self](const vpnclient_engine::ConnectionStats& stats) {
          on_stats_updated(self, stats);
        });
        (*self->engine)->set_log_callback([self](const std::string& level, const std::string& message) {
          on_log(self, level, message);
        });
        
        g_autoptr(FlValue) result = fl_value_new_bool(true);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INIT_FAILED", "Failed to initialize VPN engine", nullptr));
      }
    }
  } else if (strcmp(method, "connect") == 0) {
    if (self->engine == nullptr || !(*self->engine)) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "NOT_INITIALIZED", "Engine not initialized", nullptr));
    } else {
      bool success = (*self->engine)->connect();
      g_autoptr(FlValue) result = fl_value_new_bool(success);
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
  } else if (strcmp(method, "disconnect") == 0) {
    if (self->engine == nullptr || !(*self->engine)) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "NOT_INITIALIZED", "Engine not initialized", nullptr));
    } else {
      (*self->engine)->disconnect();
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    }
  } else if (strcmp(method, "getCoreName") == 0) {
    if (self->engine == nullptr || !(*self->engine)) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "NOT_INITIALIZED", "Engine not initialized", nullptr));
    } else {
      std::string name = (*self->engine)->get_core_name();
      g_autoptr(FlValue) result = fl_value_new_string(name.c_str());
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
  } else if (strcmp(method, "getCoreVersion") == 0) {
    if (self->engine == nullptr || !(*self->engine)) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "NOT_INITIALIZED", "Engine not initialized", nullptr));
    } else {
      std::string version = (*self->engine)->get_core_version();
      g_autoptr(FlValue) result = fl_value_new_string(version.c_str());
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
  } else if (strcmp(method, "getDriverName") == 0) {
    if (self->engine == nullptr || !(*self->engine)) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "NOT_INITIALIZED", "Engine not initialized", nullptr));
    } else {
      std::string name = (*self->engine)->get_driver_name();
      g_autoptr(FlValue) result = fl_value_new_string(name.c_str());
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
  } else if (strcmp(method, "testConnection") == 0) {
    if (self->engine == nullptr || !(*self->engine)) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "NOT_INITIALIZED", "Engine not initialized", nullptr));
    } else {
      bool success = (*self->engine)->test_connection();
      g_autoptr(FlValue) result = fl_value_new_bool(success);
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    }
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void vpnclient_engine_plugin_dispose(GObject* object) {
  VpnclientEnginePlugin* self = VPNCLIENT_ENGINE_PLUGIN(object);
  
  if (self->engine != nullptr) {
    delete self->engine;
    self->engine = nullptr;
  }
  
  G_OBJECT_CLASS(vpnclient_engine_plugin_parent_class)->dispose(object);
}

static void vpnclient_engine_plugin_class_init(VpnclientEnginePluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = vpnclient_engine_plugin_dispose;
}

static void vpnclient_engine_plugin_init(VpnclientEnginePlugin* self) {
  self->engine = nullptr;
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                          gpointer user_data) {
  VpnclientEnginePlugin* plugin = VPNCLIENT_ENGINE_PLUGIN(user_data);
  vpnclient_engine_plugin_handle_method_call(plugin, method_call);
}

void vpnclient_engine_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  VpnclientEnginePlugin* plugin = VPNCLIENT_ENGINE_PLUGIN(
      g_object_new(vpnclient_engine_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                           "vpnclient_engine",
                           FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(plugin->channel, method_call_cb,
                                           g_object_ref(plugin),
                                           g_object_unref);

  g_object_unref(plugin);
}

