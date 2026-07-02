import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/utils/localhost.dart';

const String _apiHost = String.fromEnvironment('API_HOST', defaultValue: '');
const String _apiPort = String.fromEnvironment(
  'API_PORT',
  defaultValue: '8080',
);
const String _apiTls = String.fromEnvironment('API_TLS', defaultValue: 'false');

bool get _secure => _apiTls == 'true';

final apiBaseUriProvider = Provider<Uri>(
  (_) => Uri(
    scheme: _secure ? 'https' : 'http',
    host: _apiHost.isNotEmpty ? _apiHost : localhost,
    port: int.parse(_apiPort),
  ),
);

/// Builds the EventBus WebSocket uri; the Firebase id token travels as a query
/// parameter because browser WebSocket clients cannot set headers.
final eventBusUriProvider = Provider<Uri Function(String token)>((ref) {
  final base = ref.watch(apiBaseUriProvider);
  return (token) => base.replace(
    scheme: _secure ? 'wss' : 'ws',
    path: '/events',
    queryParameters: {'token': token},
  );
});
