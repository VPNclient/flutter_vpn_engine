import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'id_generator.dart';
import 'parsers/share_link_list_parser.dart';
import 'ping_result.dart';
import 'server.dart';
import 'server_definition.dart';
import 'storage/subscription_store.dart';
import 'subscription.dart';
import 'subscription_parse_exception.dart';
import 'subscription_parser.dart';

/// Owns `List<Subscription>`, each owning `List<Server>`. Matches
/// `flutter_vpnclient_engine_mock`'s `SubscriptionManager` shape.
///
/// Real behavior ported from the original `subscription_manager.dart`:
/// `refreshSubscription` uses a real `http.Client` fetch (was
/// `updateSubscription`), `pingServer` uses a real `Socket.connect` +
/// `Stopwatch` timing (unchanged). CRUD/persistence bookkeeping
/// (`addRemoteSubscription`, etc.) is pure in-memory/storage logic with no
/// native or network dependency either way, so it matches the mock's shape
/// directly rather than porting from a real-but-differently-shaped
/// equivalent.
///
/// Default `parsers` is `[ShareLinkListParser()]` only — **not** the mock's
/// 3-parser default. No real precedent exists in this package for a
/// JSON-array or sing-box-config subscription parser (genuine gap, not built
/// here).
class SubscriptionManager {
  SubscriptionManager({
    required SubscriptionStore store,
    List<SubscriptionParser> parsers = const [ShareLinkListParser()],
    http.Client? httpClient,
  })  : _store = store,
        _parsers = parsers,
        _httpClient = httpClient ?? http.Client() {
    _ready = _load();
  }

  final SubscriptionStore _store;
  final List<SubscriptionParser> _parsers;
  final http.Client _httpClient;

  late final Future<void> _ready;
  Future<void> get ready => _ready;

  List<Subscription> _subscriptions = [];
  final _subscriptionsController = StreamController<List<Subscription>>.broadcast();

  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);
  Stream<List<Subscription>> get subscriptionsStream => _subscriptionsController.stream;

  final _pingResultController = StreamController<PingResult>.broadcast();
  Stream<PingResult> get onPingResult => _pingResultController.stream;

  Future<void> _load() async {
    _subscriptions = await _store.load();
    _subscriptionsController.add(subscriptions);
  }

  Future<void> _persist() async {
    await _store.save(_subscriptions);
    _subscriptionsController.add(subscriptions);
  }

  // Serializes mutations so concurrent calls don't race on a read-modify-write
  // of the full subscriptions list — one in-flight save at a time.
  Future<void> _lock = Future.value();

  Future<T> _guarded<T>(Future<T> Function() action) {
    final result = _lock.then((_) => action());
    _lock = result.then((_) {}, onError: (_) {});
    return result;
  }

  // --- Subscription CRUD ---

  Future<Subscription> addRemoteSubscription({
    required String name,
    required Uri url,
    Duration? refreshInterval,
  }) {
    return _guarded(() async {
      await ready;
      final subscription = Subscription(
        id: generateId('sub'),
        name: name,
        url: url,
        refreshInterval: refreshInterval,
        servers: const [],
      );
      _subscriptions = [..._subscriptions, subscription];
      await _persist();
      return subscription;
    });
  }

  Future<Subscription> addLocalSubscription({required String name}) {
    return _guarded(() async {
      await ready;
      final subscription = Subscription(
        id: generateId('sub'),
        name: name,
        url: null,
        servers: const [],
      );
      _subscriptions = [..._subscriptions, subscription];
      await _persist();
      return subscription;
    });
  }

  Future<void> removeSubscription(String id) {
    return _guarded(() async {
      await ready;
      _subscriptions = _subscriptions.where((s) => s.id != id).toList();
      await _persist();
    });
  }

  Future<void> renameSubscription(String id, String name) {
    return _guarded(() async {
      await ready;
      final index = _indexOfSubscriptionOrThrow(id);
      final updated = List.of(_subscriptions);
      updated[index] = updated[index].copyWith(name: name);
      _subscriptions = updated;
      await _persist();
    });
  }

  // --- Refresh (remote subscriptions only) — real HTTP fetch ---

  Future<void> refreshSubscription(String id) {
    return _guarded(() async {
      await ready;
      final index = _indexOfSubscriptionOrThrow(id);
      final subscription = _subscriptions[index];
      if (subscription.isLocal) {
        throw StateError('Subscription is local; nothing to fetch');
      }

      final response = await _httpClient.get(subscription.url!);
      final body = response.body;
      final parser = _parsers.firstWhere(
        (p) => p.canParse(body),
        orElse: () =>
            throw SubscriptionParseException('No parser recognized the subscription body'),
      );
      final servers = parser.parse(body);

      final updated = List.of(_subscriptions);
      updated[index] = subscription.copyWith(servers: servers, lastUpdatedAt: DateTime.now());
      _subscriptions = updated;
      await _persist();
    });
  }

  Future<void> refreshAll() async {
    await ready;
    for (final subscription in List.of(_subscriptions)) {
      if (subscription.isLocal) continue;
      await refreshSubscription(subscription.id);
    }
  }

  // --- Server CRUD (local subscriptions only) ---

  Future<Server> addServer(
    String subscriptionId,
    ServerDefinition definition, {
    String? name,
  }) {
    return _guarded(() async {
      await ready;
      final index = _indexOfSubscriptionOrThrow(subscriptionId);
      final subscription = _requireLocal(_subscriptions[index]);

      final server = Server(
        id: generateId('srv'),
        name: name ?? definition.resolve().address,
        definition: definition,
      );
      final updated = List.of(_subscriptions);
      updated[index] = subscription.copyWith(servers: [...subscription.servers, server]);
      _subscriptions = updated;
      await _persist();
      return server;
    });
  }

  Future<void> updateServer(
    String subscriptionId,
    String serverId,
    ServerDefinition definition,
  ) {
    return _guarded(() async {
      await ready;
      final index = _indexOfSubscriptionOrThrow(subscriptionId);
      final subscription = _requireLocal(_subscriptions[index]);

      final serverIndex = subscription.servers.indexWhere((s) => s.id == serverId);
      if (serverIndex == -1) {
        throw ArgumentError('No server with id $serverId in subscription $subscriptionId');
      }
      final updatedServers = List.of(subscription.servers);
      updatedServers[serverIndex] = updatedServers[serverIndex].copyWith(definition: definition);

      final updated = List.of(_subscriptions);
      updated[index] = subscription.copyWith(servers: updatedServers);
      _subscriptions = updated;
      await _persist();
    });
  }

  Future<void> removeServer(String subscriptionId, String serverId) {
    return _guarded(() async {
      await ready;
      final index = _indexOfSubscriptionOrThrow(subscriptionId);
      final subscription = _requireLocal(_subscriptions[index]);

      final updatedServers = subscription.servers.where((s) => s.id != serverId).toList();
      final updated = List.of(_subscriptions);
      updated[index] = subscription.copyWith(servers: updatedServers);
      _subscriptions = updated;
      await _persist();
    });
  }

  Future<Server> cloneServerTo(
    String serverId, {
    required String targetLocalSubscriptionId,
  }) {
    return _guarded(() async {
      await ready;
      Server? found;
      for (final subscription in _subscriptions) {
        for (final server in subscription.servers) {
          if (server.id == serverId) {
            found = server;
            break;
          }
        }
        if (found != null) break;
      }
      if (found == null) {
        throw ArgumentError('No server with id $serverId');
      }

      final targetIndex = _indexOfSubscriptionOrThrow(targetLocalSubscriptionId);
      final target = _requireLocal(_subscriptions[targetIndex]);

      final clone = Server(id: generateId('srv'), name: found.name, definition: found.definition);
      final updated = List.of(_subscriptions);
      updated[targetIndex] = target.copyWith(servers: [...target.servers, clone]);
      _subscriptions = updated;
      await _persist();
      return clone;
    });
  }

  // --- Ping — real Socket.connect + Stopwatch, ported from the original
  // subscription_manager.dart's pingServer verbatim (only id-addressing
  // changed from int index to string id). Fire-and-forget: results arrive
  // via onPingResult, matching the real engine's existing convention; a
  // successful ping also updates and persists lastPingMs, which normal UI
  // (watching subscriptionsStream) picks up without consuming onPingResult.

  void pingServer(String subscriptionId, String serverId) {
    unawaited(_performPing(subscriptionId, serverId));
  }

  Future<void> _performPing(String subscriptionId, String serverId) async {
    await ready;
    final subIndex = _subscriptions.indexWhere((s) => s.id == subscriptionId);
    if (subIndex == -1) {
      _pingResultController.add(PingResult(
        subscriptionId: subscriptionId,
        serverId: serverId,
        latencyMs: -1,
        success: false,
        error: 'No subscription with id $subscriptionId',
      ));
      return;
    }
    final subscription = _subscriptions[subIndex];
    final serverIndex = subscription.servers.indexWhere((s) => s.id == serverId);
    if (serverIndex == -1) {
      _pingResultController.add(PingResult(
        subscriptionId: subscriptionId,
        serverId: serverId,
        latencyMs: -1,
        success: false,
        error: 'No server with id $serverId',
      ));
      return;
    }

    final server = subscription.servers[serverIndex];
    try {
      final config = server.protocolConfig;
      final stopwatch = Stopwatch()..start();

      // Real TCP connection test — ported from subscription_manager.dart's
      // pingServer verbatim.
      final socket = await Socket.connect(
        config.address,
        config.port,
        timeout: const Duration(seconds: 5),
      );
      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;
      await socket.close();

      final updatedServers = List.of(subscription.servers);
      updatedServers[serverIndex] = server.copyWith(lastPingMs: latency);
      final updated = List.of(_subscriptions);
      updated[subIndex] = subscription.copyWith(servers: updatedServers);
      _subscriptions = updated;
      await _guarded(_persist);

      _pingResultController.add(PingResult(
        subscriptionId: subscriptionId,
        serverId: serverId,
        latencyMs: latency,
        success: true,
      ));
    } catch (e) {
      _pingResultController.add(PingResult(
        subscriptionId: subscriptionId,
        serverId: serverId,
        latencyMs: -1,
        success: false,
        error: e.toString(),
      ));
    }
  }

  int _indexOfSubscriptionOrThrow(String id) {
    final index = _subscriptions.indexWhere((s) => s.id == id);
    if (index == -1) throw ArgumentError('No subscription with id $id');
    return index;
  }

  Subscription _requireLocal(Subscription subscription) {
    if (!subscription.isLocal) {
      throw StateError(
        'Cannot directly edit servers of a remote subscription; use cloneServerTo() instead',
      );
    }
    return subscription;
  }

  Future<void> dispose() async {
    await _subscriptionsController.close();
    await _pingResultController.close();
    _httpClient.close();
  }
}
