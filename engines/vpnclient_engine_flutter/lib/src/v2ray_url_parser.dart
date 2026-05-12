import 'dart:convert';

/// Base class for V2Ray URL parsers
abstract class V2RayURL {
  final String url;

  V2RayURL({required this.url});

  /// Get remark/alias
  String get remark;

  /// Get full V2Ray configuration JSON
  String getFullConfiguration();

  /// Parse URL and extract configuration
  Map<String, dynamic> parse();

  /// Convert to share URL format
  String toShareUrl();
}

/// Parse V2Ray URL from share link
V2RayURL? parseV2RayURL(String url) {
  final protocol = url.split('://')[0].toLowerCase();

  switch (protocol) {
    case 'vmess':
      return VmessURL(url: url);
    case 'vless':
      return VlessURL(url: url);
    case 'trojan':
      return TrojanURL(url: url);
    case 'ss':
      return ShadowsocksURL(url: url);
    case 'socks':
      return SocksURL(url: url);
    default:
      return null;
  }
}

/// VMess URL parser
class VmessURL extends V2RayURL {
  late Map<String, dynamic> _config;

  VmessURL({required super.url}) {
    _config = parse();
  }

  @override
  String get remark => _config['ps'] ?? 'VMess Server';

  @override
  Map<String, dynamic> parse() {
    try {
      final base64Part = url.replaceFirst('vmess://', '');
      final decoded = utf8.decode(base64.decode(base64Part));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  @override
  String getFullConfiguration() {
    return json.encode({
      'log': {'loglevel': 'info'},
      'inbounds': [
        {
          'port': 1080,
          'protocol': 'socks',
          'settings': {'udp': true}
        }
      ],
      'outbounds': [
        {
          'protocol': 'vmess',
          'settings': {
            'vnext': [
              {
                'address': _config['add'],
                'port':
                    int.tryParse(_config['port']?.toString() ?? '443') ?? 443,
                'users': [
                  {
                    'id': _config['id'],
                    'alterId':
                        int.tryParse(_config['aid']?.toString() ?? '0') ?? 0,
                    'security': _config['scy'] ?? 'auto',
                  }
                ]
              }
            ]
          },
          'streamSettings': {
            'network': _config['net'] ?? 'tcp',
            'security': _config['tls'] ?? 'none',
            if (_config['sni'] != null)
              'tlsSettings': {'serverName': _config['sni']},
          }
        }
      ]
    });
  }

  @override
  String toShareUrl() => url;
}

/// VLess URL parser
class VlessURL extends V2RayURL {
  late Map<String, dynamic> _config;

  VlessURL({required super.url}) {
    _config = parse();
  }

  @override
  String get remark => Uri.decodeComponent(_config['remark'] ?? 'VLess Server');

  @override
  Map<String, dynamic> parse() {
    try {
      final uri = Uri.parse(url);
      final params = uri.queryParameters;

      return {
        'uuid': uri.userInfo,
        'address': uri.host,
        'port': uri.port,
        'encryption': params['encryption'] ?? 'none',
        'flow': params['flow'] ?? '',
        'security': params['security'] ?? 'none',
        'sni': params['sni'] ?? '',
        'fp': params['fp'] ?? '',
        'pbk': params['pbk'] ?? '',
        'sid': params['sid'] ?? '',
        'type': params['type'] ?? 'tcp',
        'remark': uri.fragment,
      };
    } catch (e) {
      return {};
    }
  }

  @override
  String getFullConfiguration() {
    return json.encode({
      'log': {'loglevel': 'info'},
      'inbounds': [
        {
          'port': 1080,
          'protocol': 'socks',
          'settings': {'udp': true}
        }
      ],
      'outbounds': [
        {
          'protocol': 'vless',
          'settings': {
            'vnext': [
              {
                'address': _config['address'],
                'port': _config['port'],
                'users': [
                  {
                    'id': _config['uuid'],
                    'flow': _config['flow'],
                    'encryption': _config['encryption'],
                  }
                ]
              }
            ]
          },
          'streamSettings': {
            'network': _config['type'],
            'security': _config['security'],
            if (_config['security'] == 'reality')
              'realitySettings': {
                'serverName': _config['sni'],
                'fingerprint': _config['fp'],
                'publicKey': _config['pbk'],
                'shortId': _config['sid'],
              }
            else if (_config['security'] == 'tls')
              'tlsSettings': {
                'serverName': _config['sni'],
              }
          }
        }
      ]
    });
  }

  @override
  String toShareUrl() => url;
}

/// Trojan URL parser
class TrojanURL extends V2RayURL {
  late Map<String, dynamic> _config;

  TrojanURL({required super.url}) {
    _config = parse();
  }

  @override
  String get remark =>
      Uri.decodeComponent(_config['remark'] ?? 'Trojan Server');

  @override
  Map<String, dynamic> parse() {
    try {
      final uri = Uri.parse(url);
      final params = uri.queryParameters;

      return {
        'password': uri.userInfo,
        'address': uri.host,
        'port': uri.port,
        'sni': params['sni'] ?? uri.host,
        'type': params['type'] ?? 'tcp',
        'security': params['security'] ?? 'tls',
        'remark': uri.fragment,
      };
    } catch (e) {
      return {};
    }
  }

  @override
  String getFullConfiguration() {
    return json.encode({
      'log': {'loglevel': 'info'},
      'inbounds': [
        {
          'port': 1080,
          'protocol': 'socks',
          'settings': {'udp': true}
        }
      ],
      'outbounds': [
        {
          'protocol': 'trojan',
          'settings': {
            'servers': [
              {
                'address': _config['address'],
                'port': _config['port'],
                'password': _config['password'],
              }
            ]
          },
          'streamSettings': {
            'network': _config['type'],
            'security': _config['security'],
            'tlsSettings': {
              'serverName': _config['sni'],
            }
          }
        }
      ]
    });
  }

  @override
  String toShareUrl() => url;
}

/// Shadowsocks URL parser
class ShadowsocksURL extends V2RayURL {
  late Map<String, dynamic> _config;

  ShadowsocksURL({required super.url}) {
    _config = parse();
  }

  @override
  String get remark =>
      Uri.decodeComponent(_config['remark'] ?? 'Shadowsocks Server');

  @override
  Map<String, dynamic> parse() {
    try {
      final uri = Uri.parse(url);
      final userInfo = utf8.decode(base64.decode(uri.userInfo));
      final parts = userInfo.split(':');

      return {
        'method': parts[0],
        'password': parts[1],
        'address': uri.host,
        'port': uri.port,
        'remark': uri.fragment,
      };
    } catch (e) {
      return {};
    }
  }

  @override
  String getFullConfiguration() {
    return json.encode({
      'log': {'loglevel': 'info'},
      'inbounds': [
        {
          'port': 1080,
          'protocol': 'socks',
          'settings': {'udp': true}
        }
      ],
      'outbounds': [
        {
          'protocol': 'shadowsocks',
          'settings': {
            'servers': [
              {
                'address': _config['address'],
                'port': _config['port'],
                'method': _config['method'],
                'password': _config['password'],
              }
            ]
          }
        }
      ]
    });
  }

  @override
  String toShareUrl() => url;
}

/// Socks URL parser
class SocksURL extends V2RayURL {
  late Map<String, dynamic> _config;

  SocksURL({required super.url}) {
    _config = parse();
  }

  @override
  String get remark => Uri.decodeComponent(_config['remark'] ?? 'Socks Server');

  @override
  Map<String, dynamic> parse() {
    try {
      final uri = Uri.parse(url);
      final userInfo = uri.userInfo.split(':');

      return {
        'username': userInfo.isNotEmpty ? userInfo[0] : '',
        'password': userInfo.length > 1 ? userInfo[1] : '',
        'address': uri.host,
        'port': uri.port,
        'remark': uri.fragment,
      };
    } catch (e) {
      return {};
    }
  }

  @override
  String getFullConfiguration() {
    return json.encode({
      'log': {'loglevel': 'info'},
      'inbounds': [
        {
          'port': 1080,
          'protocol': 'socks',
          'settings': {'udp': true}
        }
      ],
      'outbounds': [
        {
          'protocol': 'socks',
          'settings': {
            'servers': [
              {
                'address': _config['address'],
                'port': _config['port'],
                if (_config['username']?.isNotEmpty == true)
                  'users': [
                    {
                      'user': _config['username'],
                      'pass': _config['password'],
                    }
                  ]
              }
            ]
          }
        }
      ]
    });
  }

  @override
  String toShareUrl() => url;
}
