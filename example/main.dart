import 'package:flutter/material.dart';
import 'package:vpnclient_engine/vpnclient_engine.dart';

void main() {
  runApp(const VpnEngineExampleApp());
}

class VpnEngineExampleApp extends StatelessWidget {
  const VpnEngineExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VPN Engine Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
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
  final VpnClientEngine _engine = VpnClientEngine.instance;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStats _stats = const ConnectionStats();
  List<String> _logs = [];

  CoreType _selectedCore = CoreType.singbox;
  DriverType _selectedDriver = DriverType.hevSocks5;

  final TextEditingController _serverController = TextEditingController();
  final TextEditingController _portController = TextEditingController(
    text: '443',
  );
  final TextEditingController _uuidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
  }

  void _setupCallbacks() {
    _engine.statusStream.listen((status) {
      setState(() => _status = status);
      _addLog('Status changed: $status');
    });

    _engine.statsStream.listen((stats) {
      setState(() => _stats = stats);
    });

    _engine.logStream.listen((log) {
      _addLog('[${log['level']}] ${log['message']}');
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
      if (_logs.length > 50) {
        _logs.removeAt(0);
      }
    });
  }

  Future<void> _connect() async {
    if (_serverController.text.isEmpty) {
      _showError('Please enter server address');
      return;
    }

    final port = int.tryParse(_portController.text);
    if (port == null || port <= 0 || port > 65535) {
      _showError('Invalid port');
      return;
    }

    if (_uuidController.text.isEmpty) {
      _showError('Please enter UUID');
      return;
    }

    // Create configuration
    final config = VpnEngineConfig(
      core: CoreConfig(
        type: _selectedCore,
        configJson: _buildConfig(),
        serverAddress: _serverController.text,
        serverPort: port,
        enableLogging: true,
      ),
      driver: DriverConfig(
        type: _selectedDriver,
        mtu: 1500,
        enableLogging: true,
      ),
    );

    // Initialize
    final initialized = await _engine.initialize(config);
    if (!initialized) {
      _showError('Failed to initialize engine');
      return;
    }

    // Connect
    final connected = await _engine.connect();
    if (!connected) {
      _showError('Failed to connect');
    }
  }

  String _buildConfig() {
    final server = _serverController.text;
    final port = _portController.text;
    final uuid = _uuidController.text;

    // Example SingBox configuration
    return '''
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
    "server": "$server",
    "server_port": $port,
    "uuid": "$uuid",
    "flow": "xtls-rprx-vision",
    "tls": {
      "enabled": true,
      "server_name": "$server"
    }
  }]
}
''';
  }

  Future<void> _disconnect() async {
    await _engine.disconnect();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VPN Engine Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          if (_status == ConnectionStatus.connected) _buildStatsCard(),
          if (_status == ConnectionStatus.disconnected) _buildConfigCard(),
          const SizedBox(height: 16),
          _buildConnectButton(),
          const SizedBox(height: 16),
          _buildLogsCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    String statusText;

    switch (_status) {
      case ConnectionStatus.connected:
        statusColor = Colors.green;
        statusText = 'Connected';
        break;
      case ConnectionStatus.connecting:
        statusColor = Colors.orange;
        statusText = 'Connecting...';
        break;
      case ConnectionStatus.disconnecting:
        statusColor = Colors.orange;
        statusText = 'Disconnecting...';
        break;
      case ConnectionStatus.error:
        statusColor = Colors.red;
        statusText = 'Error';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Disconnected';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              statusText,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('↓ Download', _stats.formattedBytesReceived),
                _buildStatItem('↑ Upload', _stats.formattedBytesSent),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Latency', '${_stats.latencyMs} ms'),
                _buildStatItem('Total', _stats.formattedTotalBytes),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CoreType>(
              value: _selectedCore,
              decoration: const InputDecoration(
                labelText: 'VPN Core',
                border: OutlineInputBorder(),
              ),
              items: CoreType.values.map((core) {
                return DropdownMenuItem(
                  value: core,
                  child: Text(core.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedCore = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DriverType>(
              value: _selectedDriver,
              decoration: const InputDecoration(
                labelText: 'Tunnel Driver',
                border: OutlineInputBorder(),
              ),
              items: DriverType.values.map((driver) {
                return DropdownMenuItem(
                  value: driver,
                  child: Text(driver.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedDriver = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _serverController,
              decoration: const InputDecoration(
                labelText: 'Server Address',
                border: OutlineInputBorder(),
                hintText: 'example.com',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _uuidController,
              decoration: const InputDecoration(
                labelText: 'UUID',
                border: OutlineInputBorder(),
                hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectButton() {
    return ElevatedButton(
      onPressed:
          _status == ConnectionStatus.connecting ||
              _status == ConnectionStatus.disconnecting
          ? null
          : _status == ConnectionStatus.connected
          ? _disconnect
          : _connect,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: _status == ConnectionStatus.connected
            ? Colors.red
            : Colors.green,
      ),
      child: Text(
        _status == ConnectionStatus.connected
            ? 'DISCONNECT'
            : _status == ConnectionStatus.connecting
            ? 'CONNECTING...'
            : 'CONNECT',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLogsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Logs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => setState(() => _logs.clear()),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: Text(
                      _logs[index],
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _serverController.dispose();
    _portController.dispose();
    _uuidController.dispose();
    _engine.dispose();
    super.dispose();
  }
}
