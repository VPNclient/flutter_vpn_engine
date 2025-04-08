# VPNclient Engine

**VPNclient Engine** is a powerful, cross-platform VPN client core library that provides the low-level functionality to create VPN connections and tunnels. It’s designed for ultimate flexibility, supporting multiple VPN protocols (Xray:VMess,VLESS,Reality;OpenVPN;WireGuard) and network drivers in a single unified engine. The engine can be embedded into apps on various platforms (iOS, Android, Windows, macOS, Unix) to enable advanced VPN features without reinventing the wheel for each platform.



## 🚀 Key Features
- **Multi-Protocol Support:** Out-of-the-box integration with **Xray** core (supporting VMess, VLESS, Reality, and other protocols from the V2Ray ecosystem), **WireGuard**, and **OpenVPN**. This means the engine can handle anything from secure proxies to full VPN protocols, allowing easy migration from or combination of different VPN technologies.
- **Modular Architecture:** The engine is built with a plugin-like architecture, separating “drivers” (network I/O mechanisms) from “cores” (VPN protocol implementations). This modular design means you can tailor it to your needs—for example, using a TUN interface driver for full-device VPN, or a SOCKS5 driver for proxy mode; using Xray for advanced protocols or falling back to OpenVPN, etc.
- **Native Platform-Specific Implementations (Swift/Kotlin):**Platform-specific VPN functionalities, such as network interfaces or background service management, are written natively in Swift for iOS and Kotlin for Android. These implementations ensure proper integration with OS-specific networking features and provide better control over system resources, such as network extension APIs on iOS and VPN service management on Android.
- **High Performance GoLang Core for Xray**:Xray, the core VPN protocol handler, is implemented in GoLang for efficient and concurrent networking performance, enabling high throughput and scalability, particularly in handling various tunneling protocols.
- **High Performance C++ Core:** Implemented in C++ for efficiency and speed, with careful consideration for memory and battery usage (important on mobile). It strives to achieve native-level performance comparable to dedicated clients.
- **Cross-Platform Compatibility:** The same engine code runs on **iOS, Android, macOS, Windows, and Linux**. Platform-specific adaptations (like using Network Extension on iOS, or WinTun on Windows) are built-in. This ensures consistent behavior and capability across devices, making it ideal for applications that target multiple environments.
- **Ease of Integration:** For developers, VPNclient Engine exposes a clear API (in multiple languages: Swift, Kotlin/Java, C++) to start/stop the VPN and configure options. It can be included as a library (.aar for Android, CocoaPod/Framework for iOS, static or dynamic libs for desktop). This makes it straightforward to integrate into your own app or system.
- **Use Cases:** VPNclient Engine can power a typical VPN client app (like the VPNclient App above), but it’s flexible enough for other uses: building a secure proxy service into an app, creating a custom enterprise VPN solution, or academic/research projects experimenting with network tunneling.

## 🏗️ Architecture Overview

```mermaid
graph TD
  style C fill:#e06377
  C[VPNclient Engine] --> D[Drivers]
  C --> E[Cores]

  style D fill:#c83349
  D --> F[VPNclient Driver]
  D --> G[tun2socks]
  D --> H[hev5-socks]
  D --> I[WinTun]
  D --> J[No driver]

  style E fill:#5b9aa0
  E --> K[VPNclient Xray Wrapper]
  E --> L[libXray]
  E --> M[sing-box]
  E --> N[WireGuard]
  E --> O[OpenVPN]
  E --> P[No core]
``` 

```mermaid
graph TD
  style C fill:#e06377
  C[VPNclient Engine] --> D[Drivers]
  C --> E[Cores]

  style D fill:#c83349
  D --> F[VPNclient Driver]
  D --> G[tun2socks]
  D --> H[hev5-socks]
  D --> I[WinTun]
  D --> J[No driver]

  style E fill:#5b9aa0
  E --> K[VPNclient Xray Wrapper]
  E --> L[libXray]
  E --> M[sing-box]
  E --> N[WireGuard]
  E --> O[OpenVPN]
  E --> P[No core]
``` 

## Quick Start

### Prerequisites
- For Android: Android SDK, NDK
- For iOS: Xcode with Swift support
- For Desktop: CMake, platform-specific build tools

### Installation

#### Android (Kotlin)
Add to your `build.gradle`:
```kotlin
dependencies {
    implementation("click.vpnclient:engine:1.0.0")
}
```

#### iOS (Swift)
Add to your `Podfile`:
```ruby
pod 'VPNclientEngine', '~> 1.0.0'
```

#### C++ (Cross-platform)
Add as a subproject or include the prebuilt libraries.

## API Usage

### Common Engine Initialization

#### Swift (iOS/macOS)
```swift
import VPNclientEngine

let engine = VPNClientEngine()
engine.setDriver(type: .vpnclient_driver)
engine.setCore(type: .vpnclient_xray_wrapper)

let config = """
{
    "inbounds": [...],
    "outbounds": [...]
}
"""

engine.start(config: config) { success, error in
    if success {
        print("VPN started successfully")
    } else {
        print("Error starting VPN: \(error?.localizedDescription ?? "Unknown error")")
    }
}
```

#### Kotlin (Android)
```kotlin
import com.vpnclient.engine.VPNClientEngine

val engine = VPNClientEngine()
engine.setDriver(DriverType.VPNCLIENT_DRIVER)
engine.setCore(CoreType.VPNCLIENT_XRAY_WRAPPER)

val config = """
{
    "inbounds": [...],
    "outbounds": [...]
}
""".trimIndent()

engine.start(config) { success, error ->
    if (success) {
        println("VPN started successfully")
    } else {
        println("Error starting VPN: ${error ?: "Unknown error"}")
    }
}
```

#### C++ (Windows/Linux)
```cpp
#include <vpnclient_engine.h>

int main() {
    VPNClientEngine engine;
    engine.setDriver(DriverType::VPNCLIENT_DRIVER);
    engine.setCore(CoreType::VPNCLIENT_XRAY_WRAPPER);
    
    const std::string config = R"({
        "inbounds": [...],
        "outbounds": [...]
    })";
    
    engine.start(config, [](bool success, const std::string& error) {
        if (success) {
            std::cout << "VPN started successfully" << std::endl;
        } else {
            std::cerr << "Error starting VPN: " << error << std::endl;
        }
    });
    
    return 0;
}
```

## API Reference

### Core Methods

1. **setDriver**
   ```swift
   func setDriver(type: DriverType)
   ```
   ```kotlin
   fun setDriver(type: DriverType)
   ```
   ```cpp
   void setDriver(DriverType type);
   ```
   
   Available drivers:
   - VPNCLIENT_DRIVER
   - TUN2SOCKS
   - HEV_SOCKS5
   - WINTUN
   - NONE

2. **setCore**
   ```swift
   func setCore(type: CoreType)
   ```
   ```kotlin
   fun setCore(type: CoreType)
   ```
   ```cpp
   void setCore(CoreType type);
   ```
   
   Available cores:
   - VPNCLIENT_XRAY_WRAPPER
   - LIBXRAY
   - SING_BOX
   - WIREGUARD
   - OPENVPN
   - NONE

3. **start**
   ```swift
   func start(config: String, completion: @escaping (Bool, Error?) -> Void)
   ```
   ```kotlin
   fun start(config: String, callback: (Boolean, String?) -> Unit)
   ```
   ```cpp
   void start(const std::string& config, std::function<void(bool, const std::string&)> callback);
   ```

4. **stop**
   ```swift
   func stop(completion: @escaping (Bool, Error?) -> Void)
   ```
   ```kotlin
   fun stop(callback: (Boolean, String?) -> Unit)
   ```
   ```cpp
   void stop(std::function<void(bool, const std::string&)> callback);
   ```

5. **getStatus**
   ```swift
   func getStatus() -> VPNStatus
   ```
   ```kotlin
   fun getStatus(): VPNStatus
   ```
   ```cpp
   VPNStatus getStatus();
   ```

## Platform-Specific Notes

### Android
- Requires VPN permission:
  ```xml
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  ```

### iOS
- Add VPN entitlements in your project settings
- Include the following in your Info.plist:
  ```xml
  <key>click.vpnclient.engine</key>
  <array>
      <string>allow-vpn</string>
  </array>
  ```

### Windows
- Requires TUN/TAP drivers installed for some configurations
- Admin privileges may be needed for certain drivers

## Example Configurations

### Xray Core Configuration
```json
{
    "inbounds": [
        {
            "port": 1080,
            "protocol": "socks",
            "settings": {
                "auth": "noauth"
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "vmess",
            "settings": {
                "vnext": [
                    {
                        "address": "your.server.com",
                        "port": 443,
                        "users": [
                            {
                                "id": "your-uuid",
                                "alterId": 0
                            }
                        ]
                    }
                ]
            }
        }
    ]
}
```

### WireGuard Configuration
```json
{
    "interface": {
        "privateKey": "your_private_key",
        "addresses": ["10.0.0.2/32"],
        "dns": ["1.1.1.1"]
    },
    "peer": {
        "publicKey": "server_public_key",
        "endpoint": "your.server.com:51820",
        "allowedIPs": ["0.0.0.0/0"]
    }
}
```

## 🤝 Contributing
We welcome contributions! Please fork the repository and submit pull requests.

## 📜 License

This project is licensed under the **VPNclient Extended GNU General Public License v3 (GPL v3)**. See [LICENSE.md](LICENSE.md) for details.

⚠️ **Note:** By using this software, you agree to comply with additional conditions outlined in the [VPNсlient Extended GNU General Public License v3 (GPL v3)](LICENSE.md)

## 💬 Support
For issues or questions, please open an issue on our GitHub repository.
