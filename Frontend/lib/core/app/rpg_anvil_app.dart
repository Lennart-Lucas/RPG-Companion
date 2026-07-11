import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:flutter/foundation.dart';
import 'package:rpg_companion/core/auth/rpg_auth_repository.dart';
import 'package:rpg_companion/core/auth/rpg_auth_token_provider.dart';
import 'package:rpg_companion/core/auth/shared_preferences_token_storage.dart';
import 'package:rpg_companion/core/config/app_config.dart';
import 'package:rpg_companion/core/http/rpg_http_client.dart';
import 'package:rpg_companion/core/records/rpg_record_registry.dart';
import 'package:rpg_companion/core/records/rpg_record_repository.dart';

/// Bootstrap for RPG Companion auth and record layers.
class RpgAnvilApp {
  RpgAnvilApp._({
    required this.httpClient,
    required this.tokenProvider,
    required this.authRepository,
    required this.apiClient,
    required this.authBloc,
    required this.recordBloc,
  });

  final RpgHttpClientService httpClient;
  final RpgAuthTokenProvider tokenProvider;
  final RpgAuthRepository authRepository;
  final ApiClientService apiClient;
  final AuthBloc authBloc;
  final RecordBloc recordBloc;

  static RpgAnvilApp? _instance;

  static RpgAnvilApp get instance {
    final app = _instance;
    if (app == null) {
      throw StateError('Call RpgAnvilApp.init() before using the app.');
    }
    return app;
  }

  static Future<void> init() async {
    if (_instance != null) return;

    final baseUrl = AppConfig.apiBaseUrl;
    if (kDebugMode) {
      debugPrint('RPG Companion API base URL: $baseUrl');
    }

    final httpClient = RpgHttpClientService(baseUrl: baseUrl);
    final tokenStorage = SharedPreferencesTokenStorage();
    final tokenProvider = RpgAuthTokenProvider(tokenStorage, httpClient);
    final authRepository = RpgAuthRepository(tokenProvider, httpClient);
    final authBloc = AuthBloc(authRepository);
    final apiClient = ApiClientService(httpClient, tokenProvider);
    final recordCoordinator = RecordCoordinatorService(
      buildRpgRecordRegistry(),
      RpgRecordRepository(apiClient),
    );
    final recordBloc = RecordBloc(recordCoordinator);

    _instance = RpgAnvilApp._(
      httpClient: httpClient,
      tokenProvider: tokenProvider,
      authRepository: authRepository,
      apiClient: apiClient,
      authBloc: authBloc,
      recordBloc: recordBloc,
    );
  }
}
