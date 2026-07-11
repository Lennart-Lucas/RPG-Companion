import 'package:flutter/foundation.dart' show kIsWeb;

/// Application configuration (API base URL, etc.).
class AppConfig {
  AppConfig._();

  static const String _rawApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8010/api/v1',
  );

  /// FastAPI base including `/api/v1`. Override via
  /// `--dart-define=API_BASE_URL=http://host:port/api/v1`.
  static String get apiBaseUrl => _normalizeApiBase(_rawApiBaseUrl);

  /// API server origin without the `/api/v1` path.
  static Uri get apiRootUri {
    final api = Uri.parse(apiBaseUrl);
    return Uri(
      scheme: api.scheme,
      host: api.host,
      port: api.hasPort ? api.port : null,
    );
  }

  /// `GET /health` on the API server (not under `/api/v1`).
  static Uri get apiHealthUri => apiRootUri.replace(path: '/health');

  static String _normalizeApiBase(String url) {
    final trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
    final withHost = kIsWeb
        ? trimmed.replaceAll('://127.0.0.1', '://localhost')
        : trimmed.replaceAll('://localhost', '://127.0.0.1');
    final uri = Uri.parse(withHost);
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final hasV1 = segments.length >= 2 &&
        segments[segments.length - 2] == 'api' &&
        segments.last == 'v1';
    if (hasV1) {
      return withHost;
    }
    return '$withHost/api/v1';
  }
}
