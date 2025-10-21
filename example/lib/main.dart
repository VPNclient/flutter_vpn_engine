import 'package:flutter/material.dart';
import 'package:vpnclient_engine/vpnclient_engine.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VPN Client Engine Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const VpnExamplePage(),
    );
  }
}

class VpnExamplePage extends StatefulWidget {
  const VpnExamplePage({super.key});

  @override
  State<VpnExamplePage> createState() => _VpnExamplePageState();
}

class _VpnExamplePageState extends State<VpnExamplePage> {
  final _engine = VpnClientEngine.instance;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _log = '';
  ConnectionStats _stats = const ConnectionStats();

  @override
  void initState() {
    super.initState();
    _setupEngine();
  }

  void _setupEngine() {
    // Set callbacks
    _engine.setStatusCallback((status) {
      setState(() {
        _status = status;
      });
    });

    _engine.setLogCallback((level, message) {
      setState(() {
        _log = '[$level] $message\n$_log';
      });
    });

    _engine.setStatsCallback((stats) {
      setState(() {
        _stats = stats;
      });
    });

    // Listen to ping results
    _engine.onPingResult.listen((result) {
      _addLog('Ping result: ${result.latencyInMs}ms');
    });
  }

  void _addLog(String message) {
    setState(() {
      _log = '$message\n$_log';
    });
  }

  Future<void> _connectWithConfig() async {
    // Example: Connect with SingBox + HevSocks5
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
            "uuid": "your-uuid-here",
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

    await _engine.initialize(config);
    await _engine.connect();
  }

  Future<void> _connectWithSubscription() async {
    // Example: Connect using subscription
    _engine.clearSubscriptions();
    _engine.addSubscription(
      subscriptionURL: 'https://example.com/subscription',
      name: 'My Subscription',
    );

    final updated = await _engine.updateSubscription(subscriptionIndex: 0);
    if (updated) {
      _addLog('Subscription updated successfully');

      // Ping first server
      await _engine.pingServer(subscriptionIndex: 0, serverIndex: 0);

      // Connect to first server
      await _engine.connectToServer(subscriptionIndex: 0, serverIndex: 0);
    }
  }

  Future<void> _connectWithV2RayURL() async {
    // Example: Parse V2Ray URL and connect
    const v2rayShareLink =
        'vless://uuid@server:port?encryption=none&security=reality&sni=example.com#ServerName';

    final v2rayUrl = parseV2RayURL(v2rayShareLink);
    if (v2rayUrl != null) {
      final config = VpnEngineConfig(
        core: CoreConfig(
          type: CoreType.v2ray,
          configJson: v2rayUrl.getFullConfiguration(),
        ),
        driver: DriverConfig(
          type: DriverType.hevSocks5,
        ),
      );

      await _engine.initialize(config);
      await _engine.connect();
    }
  }

  Future<void> _disconnect() async {
    await _engine.disconnect();
  }

  String _getStatusText() {
    switch (_status) {
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.disconnecting:
        return 'Disconnecting...';
      case ConnectionStatus.error:
        return 'Error';
    }
  }

  Color _getStatusColor() {
    switch (_status) {
      case ConnectionStatus.disconnected:
        return Colors.grey;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.disconnecting:
        return Colors.orange;
      case ConnectionStatus.error:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('VPN Client Engine Example'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Status:',
                            style: TextStyle(fontSize: 16)),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getStatusColor(),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(_getStatusText(),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('↓ ${_stats.formattedBytesReceived}'),
                        Text('↑ ${_stats.formattedBytesSent}'),
                        Text('${_stats.latencyMs}ms'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Connection Buttons
            const Text('Connect Methods:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _status == ConnectionStatus.disconnected
                  ? _connectWithConfig
                  : null,
              icon: const Icon(Icons.settings),
              label: const Text('Connect with Config'),
            ),
            ElevatedButton.icon(
              onPressed: _status == ConnectionStatus.disconnected
                  ? _connectWithSubscription
                  : null,
              icon: const Icon(Icons.subscriptions),
              label: const Text('Connect with Subscription'),
            ),
            ElevatedButton.icon(
              onPressed: _status == ConnectionStatus.disconnected
                  ? _connectWithV2RayURL
                  : null,
              icon: const Icon(Icons.link),
              label: const Text('Connect with V2Ray URL'),
            ),
            ElevatedButton.icon(
              onPressed: _status == ConnectionStatus.connected ||
                      _status == ConnectionStatus.connecting
                  ? _disconnect
                  : null,
              icon: const Icon(Icons.stop),
              label: const Text('Disconnect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Logs
            const Text('Logs:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                reverse: true,
                child: Text(
                  _log.isEmpty ? 'No logs yet...' : _log,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }
}

