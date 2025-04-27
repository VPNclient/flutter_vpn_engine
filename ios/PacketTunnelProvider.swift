import NetworkExtension

import os.log


class PacketTunnelProvider: NEPacketTunnelProvider {
    private var isTunnelRunning = false
    private var hevTunnel: HevSocks5Tunnel?

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        os_log(.debug, "PacketTunnelProvider: Starting tunnel with options: %@", String(describing: options))

        // Check if the tunnel is already running
        if isTunnelRunning {
            os_log(.error, "PacketTunnelProvider: Tunnel is already running")
            completionHandler(NSError(domain: "PacketTunnelProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: "Tunnel is already running"]))
            return
        }
        guard let protocolConfiguration = protocolConfiguration as? NETunnelProviderProtocol,
              let providerConfig = protocolConfiguration.providerConfiguration,
              let tunAddr = providerConfig["tunAddr"] as? String,
              let tunMask = providerConfig["tunMask"] as? String,
              let tunDns = providerConfig["tunDns"] as? String,
              let socks5Proxy = providerConfig["socks5Proxy"] as? String else {
            os_log(.error, "PacketTunnelProvider: Failed to load provider configuration")
            completionHandler(NSError(domain: "PacketTunnelProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing provider configuration"]))
            return
           
        }

        os_log(.debug, "PacketTunnelProvider: Config - tunAddr: %@, tunMask: %@, tunDns: %@, socks5Proxy: %@", tunAddr, tunMask, tunDns, socks5Proxy)

        let proxyComponents = socks5Proxy.components(separatedBy: ":")
        guard proxyComponents.count == 2,
              let socks5Address = proxyComponents.first,
              let socks5Port = UInt16(proxyComponents.last ?? "1080") else {
            os_log(.error, "PacketTunnelProvider: Invalid SOCKS5 proxy format: %@", socks5Proxy)
            completionHandler(NSError(domain: "PacketTunnelProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid SOCKS5 proxy format"]))
            return
        }

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: socks5Address)
        settings.mtu = 1500

        let ipv4Settings = NEIPv4Settings(addresses: [tunAddr], subnetMasks: [tunMask])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4Settings

        let dnsSettings = NEDNSSettings(servers: [tunDns])
        settings.dnsSettings = dnsSettings

        os_log(.debug, "PacketTunnelProvider: Applying tunnel network settings...")
        setTunnelNetworkSettings(settings) { error in
            if let error = error {
                os_log(.error, "PacketTunnelProvider: Failed to set tunnel network settings: %@", error.localizedDescription)
                completionHandler(error)
                return
            }

            os_log(.info, "PacketTunnelProvider: Tunnel network settings applied successfully")

            let config = """
             tunnel:
               name: tun0
               mtu: 1500
             log_level: 2
             dns:
               address: "\(tunDns)"
               port: 53
             socks5:
              address: "\(socks5Address)"
              port: \(socks5Port)
            """

            os_log(.debug, "PacketTunnelProvider: Starting hev-socks5-tunnel with config: %@", config)
            DispatchQueue.global().async {
                self.startHevSocks5Tunnel(withConfig: config)
               }

              // Set tunnel running flag
             self.isTunnelRunning = true

            
           self.monitorTunnelActivity()
            os_log(.debug, "PacketTunnelProvider: Calling completion handler with success")
            completionHandler(nil)
        }
    }

    func startHevSocks5Tunnel(withConfig config: String) {
        os_log(.debug, "PacketTunnelProvider: Starting hev-socks5-tunnel...")

        guard let configData = config.data(using: .utf8) else {
            os_log(.error, "PacketTunnelProvider: Failed to convert config to UTF-8 data")
            return
        }
        let configLen = UInt32(configData.count)
        
        self.hevTunnel = HevSocks5Tunnel(packetTunnel: self)
                guard let hevTunnel = self.hevTunnel else {
                    os_log(.error, "Failed to initialize HevSocks5Tunnel")
                    return
                }
        
        // Start the HevSocks5Tunnel
        let result = configData.withUnsafeBytes { configPtr in
                    return hevTunnel.start(configPtr.baseAddress!, configLen)
                }
        
            if result != 0 {
                os_log(.error, "PacketTunnelProvider: Failed to start HevSocks5Tunnel. Result code: %d", result)
              return
            }

            os_log(.info, "PacketTunnelProvider: HevSocks5Tunnel started successfully")
    
         // Start handling packets
         self.handlePackets()
     }
    
    
    
    func handlePackets() {
        guard isTunnelRunning else {
                os_log(.error, "PacketTunnelProvider: Tunnel is not running, cannot handle packets")
                return
            }
        
        // Check if the packet flow is available
                guard let flow = self.packetFlow else {
                    os_log(.error, "PacketTunnelProvider: Packet flow is nil")
                    return
                }
        
        // Read packets from the packet flow
              flow.readPackets { [weak self] packets, protocols in
                  guard let self = self else { return }
                  // Check if the tunnel is still running before processing packets
                  guard self.isTunnelRunning else {
                      os_log(.info, "PacketTunnelProvider: Tunnel is stopping, ceasing packet handling")
                      return
                  }
        
                  // Process each packet
                  for (packet, protocol) in zip(packets, protocols) {
                      os_log(.debug, "PacketTunnelProvider: Received packet of size %d, protocol: %@", packet.count, protocol.description)
                      // Handle the packet using HevSocks5Tunnel (if needed)
                      if let hevTunnel = self.hevTunnel {
                            let result = packet.withUnsafeBytes { packetPtr in
                                return hevTunnel.inputPacket(packetPtr.baseAddress!, UInt32(packet.count))
                            }
                            os_log(.debug, "PacketTunnelProvider:inputPacket result = %d", result)
                      }
                  }
        
                  // Continue handling packets
                  self.handlePackets()
              }
    }

   // Method for monitoring tunnel activity
    func monitorTunnelActivity() {
            // Create a global asynchronous queue
            DispatchQueue.global().async {
                // Continue monitoring as long as the tunnel is running
                while self.isTunnelRunning {
                    // Pause for 1 second
                    usleep(1000000)
                    os_log(.debug, "PacketTunnelProvider: Tunnel still active, checking packets...")
                }
            }
    }

    // Method to stop the tunnel
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        os_log(.debug, "PacketTunnelProvider: Stopping tunnel with reason: %@", reason.rawValue.description)
        
        // Stop the tunnel and close the flow
        isTunnelRunning = false
        hevTunnel?.stop()
        hevTunnel = nil
        
        
        
        // Call the completion handler to indicate that the tunnel has stopped
        completionHandler()
    }
}
