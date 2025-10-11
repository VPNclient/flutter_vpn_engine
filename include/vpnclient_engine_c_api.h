#ifndef VPNCLIENT_ENGINE_C_API_H
#define VPNCLIENT_ENGINE_C_API_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdbool.h>

// Forward declaration
typedef void* VPNClientEngineInstance;

// Configuration structure
typedef struct {
    int32_t core_type;      // 0=SINGBOX, 1=LIBXRAY, 2=V2RAY, 3=WIREGUARD
    int32_t driver_type;    // 0=NONE, 1=HEV_SOCKS5, 2=TUN2SOCKS
    const char* config_json;
} VPNClientEngineConfig;

// Statistics structure
typedef struct {
    uint64_t bytes_sent;
    uint64_t bytes_received;
    uint64_t packets_sent;
    uint64_t packets_received;
    uint32_t latency_ms;
} VPNClientEngineStats;

// API functions
VPNClientEngineInstance vpnclient_engine_create(const VPNClientEngineConfig* config);
bool vpnclient_engine_connect(VPNClientEngineInstance instance);
void vpnclient_engine_disconnect(VPNClientEngineInstance instance);
int32_t vpnclient_engine_get_status(VPNClientEngineInstance instance);
bool vpnclient_engine_get_stats(VPNClientEngineInstance instance, VPNClientEngineStats* stats);
void vpnclient_engine_destroy(VPNClientEngineInstance instance);

#ifdef __cplusplus
}
#endif

#endif // VPNCLIENT_ENGINE_C_API_H





