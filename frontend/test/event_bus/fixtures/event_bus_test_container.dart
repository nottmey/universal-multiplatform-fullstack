import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/api/api_offline_retry.dart';
import 'package:frontend/auth/authentication_state_provider.dart';
import 'package:frontend/event_bus/event_bus_provider.dart';
import 'package:frontend/event_bus/event_bus_socket.dart';

import 'fake_event_bus_socket.dart';

const Duration fastHandshakeTimeout = Duration(milliseconds: 20);
const String testIdToken = 'test-id-token';

/// Builds the fake socket returned for a given 0-based connect attempt.
typedef FakeSocketBuilder = FakeEventBusSocket Function(int attempt);

/// Connects the EventBus provider to a caller-supplied fake socket sequence.
///
/// Retry is disabled at the container level so tests observe a single attempt
/// deterministically; the offline retry *classification* is covered by
/// api_offline_retry_test.dart. [onConnect] fires (with the 0-based attempt
/// index) before each socket is returned, so tests can drive it. Set
/// [connectThrows] to make a connect attempt fail instead of returning a
/// socket.
ProviderContainer createEventBusTestContainer({
  required FakeSocketBuilder socketBuilder,
  void Function(int attempt, FakeEventBusSocket socket)? onConnect,
  Object? Function(int attempt)? connectThrows,
  String? idToken = testIdToken,
}) {
  var attempt = 0;
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      eventBusHandshakeTimeoutProvider.overrideWithValue(fastHandshakeTimeout),
      authenticationIdTokenProvider.overrideWith((_) async => idToken),
      eventBusConnectorProvider.overrideWithValue((uri) async {
        final index = attempt++;
        final failure = connectThrows?.call(index);
        if (failure != null) {
          throw failure;
        }
        final socket = socketBuilder(index);
        onConnect?.call(index, socket);
        return socket;
      }),
    ],
  );
  // Keep the autoDispose provider alive for the test lifetime so it is not
  // torn down (which would close the socket) between reads. The subscription
  // is released when the container is disposed.
  container.listen(eventBusProvider, (_, _) {});
  return container;
}
