# Understanding: Subscription Management

> Server subscription handling and V2Ray URL parsing for multi-server VPN configuration.

## Phase: SYNTHESIZING

## Hypothesis

Subsystem for managing VPN server subscriptions with automatic URL fetching, V2Ray protocol parsing, and server latency testing.

## Sources

> Files/directories that inform this understanding

- `lib/src/subscription_manager.dart` - Core subscription logic (270 lines)
- `lib/src/v2ray_url_parser.dart` - V2Ray URL parsing (400 lines)

## Validated Understanding

### SubscriptionManager

Manages collections of VPN server subscriptions:

```dart
class SubscriptionManager {
    List<Subscription> _subscriptions;
    StreamController<PingResult> _pingResultController;

    // Subscription CRUD
    void addSubscription({required String subscriptionURL, String? name});
    void clearSubscriptions();
    List<Subscription> get subscriptions;

    // Server updates
    Future<bool> updateSubscription({required int subscriptionIndex});

    // Server selection
    ServerConfig? getServer({required int subscriptionIndex, required int serverIndex});

    // Latency testing
    Future<void> pingServer({...});
    Stream<PingResult> get onPingResult;
}
```

### Subscription Model

```dart
class Subscription {
    final String url;           // Subscription URL
    final String? name;         // Display name
    final DateTime? lastUpdate; // Last fetch time
    List<ServerConfig> servers; // Parsed servers
}
```

### ServerConfig Model

```dart
class ServerConfig {
    final String url;       // Original share URL
    final String remark;    // Server name/alias
    final String protocol;  // vmess, vless, etc.
    final String address;   // Server IP/hostname
    final int port;         // Server port
    int? latencyMs;         // Ping result
}
```

### V2Ray URL Parser

Supports multiple protocols via abstract base class:

```dart
abstract class V2RayURL {
    String get remark;
    String getFullConfiguration();
    Map<String, dynamic> parse();
    String toShareUrl();
}

V2RayURL? parseV2RayURL(String url) {
    switch (protocol) {
        case 'vmess':  return VmessURL(url: url);
        case 'vless':  return VlessURL(url: url);
        case 'trojan': return TrojanURL(url: url);
        case 'ss':     return ShadowsocksURL(url: url);
        case 'socks':  return SocksURL(url: url);
        default:       return null;
    }
}
```

### URL Format Support

| Protocol | Format | Key Fields |
|----------|--------|------------|
| VMess | `vmess://base64(json)` | add, port, id, aid, net, tls, sni |
| VLess | `vless://uuid@host:port?params#remark` | encryption, flow, security, sni, fp, pbk, sid |
| Trojan | `trojan://password@host:port?params#remark` | sni, type, security |
| Shadowsocks | `ss://base64(method:password)@host:port#remark` | method, password |
| Socks | `socks://user:pass@host:port#remark` | username, password |

### Configuration Generation

Each parser generates V2Ray-compatible JSON config:

```dart
String getFullConfiguration() {
    return json.encode({
        'log': {'loglevel': 'info'},
        'inbounds': [{
            'port': 1080,
            'protocol': 'socks',
            'settings': {'udp': true}
        }],
        'outbounds': [{
            'protocol': 'vless', // or vmess, trojan, etc.
            'settings': {...},
            'streamSettings': {...}
        }]
    });
}
```

## Children Identified

| Child | Hypothesis | Status |
|-------|------------|--------|
| (none - leaf node) | - | - |

## Dependencies

- **Uses**: data-models (via ServerConfig), http package (for subscription fetching)
- **Used by**: flutter-api-layer (VpnClientEngine integrates subscription methods)

## Key Insights

1. **Base64 Subscription Format**: Standard subscription URLs return base64-encoded server lists
2. **V2Ray URL Standards**: Supports common V2Ray share URL formats
3. **REALITY Support**: VLess parser handles REALITY transport (fp, pbk, sid)
4. **Simple Ping**: TCP socket connect for latency measurement (TODO: proxy-through ping)
5. **JSON Config Generation**: Parsers output V2Ray-compatible configuration for cores

## ADR Candidates

- ADR-005: V2Ray URL protocol support (vmess, vless, trojan, ss, socks)

## Flow Recommendation

- **Type**: SDD
- **Confidence**: high
- **Rationale**: Utility module with clear parsing contracts and data models

## Synthesis

### Combined Understanding

The Subscription Management subsystem provides:
1. **Subscription Fetching**: Download and parse base64-encoded server lists
2. **V2Ray URL Parsing**: Support for 5 protocol formats (vmess, vless, trojan, ss, socks)
3. **Server Selection**: Index-based access to subscription servers
4. **Latency Testing**: TCP-based ping with result streaming
5. **Config Generation**: Convert share URLs to V2Ray JSON configuration

### Data Flow

```
Subscription URL
      |
      v
HTTP GET + Base64 Decode
      |
      v
Line-by-line V2RayURL parsing
      |
      v
ServerConfig list
      |
      v
User selects server
      |
      v
getFullConfiguration() -> Core config
```

## Bubble Up

> Summary to pass to parent during EXITING

- SubscriptionManager handles server list fetching and management
- V2RayURLParser supports 5 protocols: vmess, vless, trojan, ss, socks
- Generates V2Ray-compatible JSON configs from share URLs
- Simple TCP-based ping for latency measurement

---

*Phase: SYNTHESIZING | Depth: 1 | Parent: root*
