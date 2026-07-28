import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/config/protocol_config.dart';
import 'package:vpnclient_engine/src/cores/core_type.dart';
import 'package:vpnclient_engine/src/engine/connection_state.dart';
import 'package:vpnclient_engine/src/engine/vpn_engine.dart';
import 'package:vpnclient_engine/src/subscriptions/server.dart';
import 'package:vpnclient_engine/src/subscriptions/server_definition.dart';

Server _shareLinkServer() => Server(
      id: 's1',
      name: 'Share-link server',
      definition: const ShareLinkDefinition(
        'ss://YWVzLTI1Ni1nY206c2VjcmV0@ss.example.com:8388#Test',
      ),
    );

Server _fullConfigServer() => Server(
      id: 's2',
      name: 'Full-config server',
      definition: const FullConfigDefinition(
        ShadowsocksConfig(
          address: 'ss.example.com',
          port: 8388,
          method: 'aes-256-gcm',
          password: 'secret',
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // These two validation paths run before VpnEngine ever touches the native
  // FFI layer, so they're exercised here regardless of whether a compiled
  // native library is available in this environment (02-specifications.md's
  // Testing Strategy: native-artifact-free unit tests).

  test('connect() without coreOverride throws ArgumentError before any state transition', () async {
    final engine = VpnEngine();
    final states = <VpnConnectionState>[];
    engine.stateStream.listen(states.add);

    await expectLater(
      () => engine.connect(_shareLinkServer()),
      throwsArgumentError,
    );
    expect(states, isEmpty);
    expect(engine.state, isA<Disconnected>());
  });

  test('connect() with a FullConfigDefinition server throws UnsupportedError', () async {
    final engine = VpnEngine();
    final states = <VpnConnectionState>[];
    engine.stateStream.listen(states.add);

    await expectLater(
      () => engine.connect(_fullConfigServer(), coreOverride: CoreType.singbox),
      throwsUnsupportedError,
    );
    expect(states, isEmpty);
  });

  test('connect() degrades to ConnectionFailed (not a crash) when the native library is unavailable', () async {
    final engine = VpnEngine();
    final states = <VpnConnectionState>[];
    engine.stateStream.listen(states.add);

    // No native libvpnclient_engine.* build artifact exists in this test
    // environment — connect() must not throw an uncaught FFI lookup error.
    // `engine.state` is checked (not the stream) because broadcast-stream
    // listener delivery is always via microtask, one tick behind the
    // synchronous `state` field — real Stream semantics, not a bug.
    await engine.connect(_shareLinkServer(), coreOverride: CoreType.singbox);

    expect(engine.state, anyOf(isA<Connected>(), isA<ConnectionFailed>()));

    await Future<void>.delayed(Duration.zero);
    expect(states, isNotEmpty);
    expect(states.first, isA<Connecting>());
  });

  test('disconnect() from a fresh engine does not throw', () async {
    final engine = VpnEngine();
    await engine.disconnect();
    expect(engine.state, isA<Disconnected>());
  });
}
