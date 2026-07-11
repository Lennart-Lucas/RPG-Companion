import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:http/http.dart' as http;

/// Token provider for the FastAPI backend (`access_token` / `refresh_token`).
class RpgAuthTokenProvider extends AuthTokenProviderService {
  RpgAuthTokenProvider(
    TokenStorageInterface tokenStorage,
    HttpClientServiceBase httpClient,
  )   : _tokenStorage = tokenStorage,
        _httpClient = httpClient,
        super(tokenStorage, httpClient);

  final TokenStorageInterface _tokenStorage;
  final HttpClientServiceBase _httpClient;

  Future<void>? _refreshInFlight;

  @override
  Future<void> refreshToken() {
    _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
    return _refreshInFlight!;
  }

  Future<void> _doRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      await _tokenStorage.clear();
      throw AuthException.unauthenticated();
    }

    try {
      final response = await _httpClient.send(
        HttpRequest(
          method: 'POST',
          path: '/auth/refresh',
          headers: const {},
          body: {'refresh_token': refreshToken},
        ),
      );

      if (response.statusCode == 401) {
        await _tokenStorage.clear();
        throw AuthException.tokenExpired();
      }

      if (response.statusCode != 200) {
        await _tokenStorage.clear();
        throw AuthException.refreshFailed(
          'Token refresh failed with status ${response.statusCode}',
        );
      }

      final tokens = parseRpgTokenPair(response.jsonBodyAsMap);
      await _tokenStorage.writeTokens(
        accessToken: tokens.$1,
        refreshToken: tokens.$2,
      );
    } on AuthException {
      rethrow;
    } on http.ClientException catch (error) {
      await _tokenStorage.clear();
      throw AuthException.networkError('Token refresh failed: ${error.message}');
    } catch (error) {
      await _tokenStorage.clear();
      throw AuthException.refreshFailed(
        'Unexpected error during token refresh: $error',
      );
    }
  }
}

(String accessToken, String refreshToken) parseRpgTokenPair(
  Map<String, dynamic> json,
) {
  final access = json['access_token'] ?? json['accessToken'];
  final refresh = json['refresh_token'] ?? json['refreshToken'];
  if (access is! String || refresh is! String) {
    throw AuthException(
      code: AuthErrorCode.refreshFailed,
      message: 'Invalid token response format',
    );
  }
  return (access, refresh);
}
