# Understanding: Platform Integration

> Platform-specific VPN service implementations for Android and iOS.

## Phase: SYNTHESIZING

## Hypothesis

Native platform layers implementing OS-specific VPN APIs (Android VPNService, iOS Network Extension) to establish and manage TUN interfaces.

## Sources

> Files/directories that inform this understanding

- `android/app/src/main/java/click/vpnclient/engine/service/VPNService.kt` - Android VPN service
- `android/app/src/main/java/click/vpnclient/engine/VPNManager.kt` - Android VPN manager
- `ios/PacketTunnelProvider.swift` - iOS packet tunnel provider
- `lib/src/platform/android_platform_interface.dart` - Android Dart interface
- `lib/src/platform/ios_platform_interface.dart` - iOS Dart interface
- `lib/src/platform/unified_platform_interface.dart` - Cross-platform interface

## Validated Understanding

### Android Implementation

**VPNService.kt** - Android VPN service extending `android.net.VpnService`:

```kotlin
class VPNService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    var isRunning = false; private set

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        setupVPN()
        isRunning = true
        return START_NOT_STICKY
    }

    private fun setupVPN() {
        vpnInterface = Builder()
            .setSession("VPNClient")
            // .addAddress() .addRoute() .addDnsServer()
            .establish()
    }

    override fun onDestroy() {
        vpnInterface?.close()
        isRunning = false
    }
}
```

### iOS Implementation

**PacketTunnelProvider.swift** - iOS Network Extension:

```swift
class PacketTunnelProvider: NEPacketTunnelProvider {
    private var isTunnelRunning = false
    private var hevTunnel: HevSocks5Tunnel?

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // Parse configuration from providerConfiguration
        guard let tunAddr = providerConfig["tunAddr"],
              let tunMask = providerConfig["tunMask"],
              let tunDns = providerConfig["tunDns"],
              let socks5Proxy = providerConfig["socks5Proxy"] else { ... }

        // Configure network settings
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: socks5Address)
        settings.mtu = 1500
        settings.ipv4Settings = NEIPv4Settings(addresses: [tunAddr], subnetMasks: [tunMask])
        settings.dnsSettings = NEDNSSettings(servers: [tunDns])

        setTunnelNetworkSettings(settings) { error in
            // Start HevSocks5Tunnel
            self.startHevSocks5Tunnel(withConfig: config)
            self.handlePackets()
        }
    }

    func handlePackets() {
        packetFlow.readPackets { packets, protocols in
            for (packet, protocol) in zip(packets, protocols) {
                hevTunnel?.inputPacket(packet)
            }
            self.handlePackets() // Continue reading
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        hevTunnel?.stop()
        isTunnelRunning = false
        completionHandler()
    }
}
```

### UnifiedPlatformInterface (Dart)

```dart
abstract class UnifiedPlatformInterface {
    Future<PlatformTunHandle> openTun(TunOptions options);
    Future<void> closeTun(PlatformTunHandle handle);
    Future<void> setupRoutes(TunOptions options);
    Future<bool> checkPrivileges();
    Future<void> setupPerAppProxy({required List<String> packages, required String mode});
    Future<void> clearDNSCache();
    Future<List<NetworkInterfaceInfo>> getNetworkInterfaces();
    void dispose();
}
```

### Platform-Specific APIs

| Platform | API | Key Components |
|----------|-----|----------------|
| Android | VpnService | Builder.establish(), ParcelFileDescriptor |
| iOS | NEPacketTunnelProvider | NEPacketTunnelNetworkSettings, packetFlow |
| Linux | Native TUN | ioctl(), /dev/net/tun |
| Windows | WinTUN | wintun.dll API |
| macOS | utun | Network Extension or utun device |

### iOS HevSocks5Tunnel Integration

The iOS implementation wraps `hev-socks5-tunnel` library:

```swift
self.hevTunnel = HevSocks5Tunnel(packetTunnel: self)
let result = hevTunnel.start(configPtr, configLen)

// Packet handling loop
for packet in packets {
    hevTunnel.inputPacket(packet, packet.count)
}
```

## Children Identified

| Child | Hypothesis | Status |
|-------|------------|--------|
| (none - leaf node) | - | - |

## Dependencies

- **Uses**: driver-abstraction (HevSocks5 on iOS), configuration-system (TUN parameters)
- **Used by**: native-bridge (platform factory), flutter-api-layer (permission checks)

## Key Insights

1. **Android VPNService**: Standard Android VPN API with Builder pattern
2. **iOS Network Extension**: NEPacketTunnelProvider with explicit packet handling
3. **HevSocks5 iOS**: Direct integration of hev-socks5-tunnel library
4. **Packet Loop**: iOS requires explicit packet read/write loop
5. **Per-App Proxy**: Android supports per-app VPN routing (not implemented in iOS)

## ADR Candidates

- (Platform integration follows OS conventions, no architectural decision)

## Flow Recommendation

- **Type**: SDD
- **Confidence**: high
- **Rationale**: Platform-specific implementations with clear OS API boundaries

## Synthesis

### Combined Understanding

The Platform Integration provides:
1. **Android VPNService**: Builder-based TUN interface creation
2. **iOS NEPacketTunnelProvider**: Network Extension with HevSocks5 integration
3. **Packet Handling**: iOS explicit loop, Android implicit
4. **Configuration Passing**: Through Intent extras (Android) or providerConfiguration (iOS)
5. **Unified Interface**: Abstract Dart interface for cross-platform operations

### Platform Lifecycle

**Android:**
```
Activity -> startService(Intent)
    -> VPNService.onStartCommand()
    -> Builder.establish()
    -> ParcelFileDescriptor (TUN FD)
```

**iOS:**
```
App -> NETunnelProviderManager.connection.startVPNTunnel()
    -> PacketTunnelProvider.startTunnel()
    -> setTunnelNetworkSettings()
    -> HevSocks5Tunnel.start()
    -> handlePackets() loop
```

## Bubble Up

> Summary to pass to parent during EXITING

- Android uses VPNService with Builder.establish() for TUN creation
- iOS uses NEPacketTunnelProvider with HevSocks5Tunnel for packet handling
- Configuration passed via Intent extras (Android) or providerConfiguration (iOS)
- iOS requires explicit packet read/write loop

---

*Phase: SYNTHESIZING | Depth: 1 | Parent: root*
