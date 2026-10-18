import 'package:moon_cycle/features/discovery/data/providers/provider_http.dart';

/// Tests never reach the real internet: every external provider call gets "service
/// unavailable" unless a test installs its own fake network.
Future<({int status, String body})> offlineGet(
  Uri url,
  Map<String, String> headers,
) async => (status: 503, body: '');

/// The same, as a transport.
const HttpGet offline = offlineGet;
