import 'package:flutter_test/flutter_test.dart';
import 'package:vpnclient_engine/src/subscriptions/ping_result.dart';

void main() {
  test('constructs success and failure shapes', () {
    const success = PingResult(
      subscriptionId: 'sub1',
      serverId: 'srv1',
      latencyMs: 42,
      success: true,
    );
    expect(success.latencyMs, 42);
    expect(success.error, isNull);

    const failure = PingResult(
      subscriptionId: 'sub1',
      serverId: 'srv1',
      latencyMs: -1,
      success: false,
      error: 'Invalid server id',
    );
    expect(failure.success, isFalse);
    expect(failure.error, 'Invalid server id');
  });
}
