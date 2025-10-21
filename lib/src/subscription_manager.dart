import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'v2ray_url_parser.dart';

/// Subscription data model
class Subscription {
  final String url;
  final String? name;
  final DateTime? lastUpdate;
  List<ServerConfig> servers;
  
  Subscription({
    required this.url,
    this.name,
    this.lastUpdate,
    this.servers = const [],
  });
  
  Map<String, dynamic> toJson() => {
    'url': url,
    'name': name,
    'lastUpdate': lastUpdate?.toIso8601String(),
    'servers': servers.map((s) => s.toJson()).toList(),
  };
  
  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    url: json['url'] as String,
    name: json['name'] as String?,
    lastUpdate: json['lastUpdate'] != null 
        ? DateTime.parse(json['lastUpdate'] as String) 
        : null,
    servers: (json['servers'] as List?)
        ?.map((s) => ServerConfig.fromJson(s as Map<String, dynamic>))
        .toList() ?? [],
  );
}

/// Server configuration model
class ServerConfig {
  final String url;
  final String remark;
  final String protocol;
  final String address;
  final int port;
  int? latencyMs;
  
  ServerConfig({
    required this.url,
    required this.remark,
    required this.protocol,
    required this.address,
    required this.port,
    this.latencyMs,
  });
  
  Map<String, dynamic> toJson() => {
    'url': url,
    'remark': remark,
    'protocol': protocol,
    'address': address,
    'port': port,
    'latencyMs': latencyMs,
  };
  
  factory ServerConfig.fromJson(Map<String, dynamic> json) => ServerConfig(
    url: json['url'] as String,
    remark: json['remark'] as String,
    protocol: json['protocol'] as String,
    address: json['address'] as String,
    port: json['port'] as int,
    latencyMs: json['latencyMs'] as int?,
  );
  
  factory ServerConfig.fromV2RayURL(V2RayURL v2rayUrl) {
    final config = v2rayUrl.parse();
    return ServerConfig(
      url: v2rayUrl.url,
      remark: v2rayUrl.remark,
      protocol: v2rayUrl.url.split('://')[0],
      address: config['address'] as String? ?? '',
      port: config['port'] as int? ?? 0,
    );
  }
}

/// Ping result model
class PingResult {
  final int subscriptionIndex;
  final int serverIndex;
  final int latencyInMs;
  final bool success;
  final String? error;
  
  PingResult({
    required this.subscriptionIndex,
    required this.serverIndex,
    required this.latencyInMs,
    required this.success,
    this.error,
  });
}

/// Subscription manager
class SubscriptionManager {
  final List<Subscription> _subscriptions = [];
  final StreamController<PingResult> _pingResultController = 
      StreamController<PingResult>.broadcast();
  
  Stream<PingResult> get onPingResult => _pingResultController.stream;
  
  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);
  
  /// Add subscription
  void addSubscription({required String subscriptionURL, String? name}) {
    final subscription = Subscription(
      url: subscriptionURL,
      name: name,
    );
    _subscriptions.add(subscription);
  }
  
  /// Clear all subscriptions
  void clearSubscriptions() {
    _subscriptions.clear();
  }
  
  /// Update subscription by downloading and parsing
  Future<bool> updateSubscription({required int subscriptionIndex}) async {
    if (subscriptionIndex < 0 || subscriptionIndex >= _subscriptions.length) {
      return false;
    }
    
    final subscription = _subscriptions[subscriptionIndex];
    
    try {
      final response = await http.get(Uri.parse(subscription.url));
      
      if (response.statusCode != 200) {
        return false;
      }
      
      // Decode base64 subscription content
      String content;
      try {
        content = utf8.decode(base64.decode(response.body));
      } catch (_) {
        content = response.body;
      }
      
      // Parse servers from subscription
      final lines = content.split('\n');
      final servers = <ServerConfig>[];
      
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        
        final v2rayUrl = parseV2RayURL(trimmed);
        if (v2rayUrl != null) {
          servers.add(ServerConfig.fromV2RayURL(v2rayUrl));
        }
      }
      
      // Update subscription
      _subscriptions[subscriptionIndex] = Subscription(
        url: subscription.url,
        name: subscription.name,
        lastUpdate: DateTime.now(),
        servers: servers,
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Ping server
  Future<void> pingServer({
    required int subscriptionIndex,
    required int serverIndex,
    String testUrl = 'https://www.google.com/generate_204',
  }) async {
    if (subscriptionIndex < 0 || subscriptionIndex >= _subscriptions.length) {
      _pingResultController.add(PingResult(
        subscriptionIndex: subscriptionIndex,
        serverIndex: serverIndex,
        latencyInMs: -1,
        success: false,
        error: 'Invalid subscription index',
      ));
      return;
    }
    
    final subscription = _subscriptions[subscriptionIndex];
    if (serverIndex < 0 || serverIndex >= subscription.servers.length) {
      _pingResultController.add(PingResult(
        subscriptionIndex: subscriptionIndex,
        serverIndex: serverIndex,
        latencyInMs: -1,
        success: false,
        error: 'Invalid server index',
      ));
      return;
    }
    
    final server = subscription.servers[serverIndex];
    
    try {
      final stopwatch = Stopwatch()..start();
      
      // Simple TCP connection test
      // TODO: Implement proper proxy-through ping
      final socket = await Socket.connect(
        server.address,
        server.port,
        timeout: const Duration(seconds: 5),
      );
      
      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;
      
      await socket.close();
      
      // Update server latency
      server.latencyMs = latency;
      
      _pingResultController.add(PingResult(
        subscriptionIndex: subscriptionIndex,
        serverIndex: serverIndex,
        latencyInMs: latency,
        success: true,
      ));
    } catch (e) {
      _pingResultController.add(PingResult(
        subscriptionIndex: subscriptionIndex,
        serverIndex: serverIndex,
        latencyInMs: -1,
        success: false,
        error: e.toString(),
      ));
    }
  }
  
  /// Get server configuration
  ServerConfig? getServer({
    required int subscriptionIndex,
    required int serverIndex,
  }) {
    if (subscriptionIndex < 0 || subscriptionIndex >= _subscriptions.length) {
      return null;
    }
    
    final subscription = _subscriptions[subscriptionIndex];
    if (serverIndex < 0 || serverIndex >= subscription.servers.length) {
      return null;
    }
    
    return subscription.servers[serverIndex];
  }
  
  /// Dispose resources
  void dispose() {
    _pingResultController.close();
  }
}

