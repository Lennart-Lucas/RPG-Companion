import 'package:anvil_foundry/anvil_foundry.dart';
import 'package:http/http.dart' as http;
import 'package:rpg_companion/core/auth/rpg_auth_token_provider.dart';

/// Auth repository for the FastAPI backend (`/auth/me`, snake_case tokens).
class RpgAuthRepository extends AuthRepositoryService {
  RpgAuthRepository(RpgAuthTokenProvider tokenProvider, HttpClientServiceBase http)
      : _tokenProvider = tokenProvider,
        _http = http,
        super(tokenProvider, http);

  final RpgAuthTokenProvider _tokenProvider;
  final HttpClientServiceBase _http;

  @override
  Future<bool> isAuthenticated() async {
    try {
      final accessToken = await _tokenProvider.getAccessToken();
      final response = await _checkMe(accessToken);
      if (response.statusCode == 200) {
        return true;
      }
      if (response.statusCode == 401) {
        await _tokenProvider.refreshToken();
        final retryToken = await _tokenProvider.getAccessToken();
        final retryResponse = await _checkMe(retryToken);
        return retryResponse.statusCode == 200;
      }
      return false;
    } on AuthException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<HttpResponse> _checkMe(String accessToken) async {
    try {
      return await _http.send(
        HttpRequest(
          path: '/auth/me',
          method: 'GET',
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
    } on http.ClientException catch (error) {
      throw AuthException.networkError(
        'Failed to check authentication: ${error.message}',
      );
    }
  }

  @override
  Future<void> login(String email, String password) async {
    await _authenticate(
      path: '/auth/login',
      email: email,
      password: password,
      failureCode: AuthErrorCode.loginFailed,
      expectedStatus: 200,
    );
  }

  @override
  Future<void> register(String email, String password) async {
    await _authenticate(
      path: '/auth/register',
      email: email,
      password: password,
      failureCode: AuthErrorCode.registerFailed,
      expectedStatus: 201,
    );
  }

  Future<void> _authenticate({
    required String path,
    required String email,
    required String password,
    required AuthErrorCode failureCode,
    required int expectedStatus,
  }) async {
    if (!_isValidEmail(email)) {
      throw AuthException.invalidInput('Invalid email format');
    }
    if (!_isValidPassword(password)) {
      throw AuthException.invalidInput('Password must be at least 8 characters');
    }

    try {
      final response = await _http.send(
        HttpRequest(
          path: path,
          method: 'POST',
          headers: const {},
          body: {'email': email, 'password': password},
        ),
      );

      if (response.statusCode != expectedStatus) {
        final jsonBody = response.jsonBodyAsMap;
        final detail = jsonBody['detail'];
        throw AuthException(
          code: failureCode,
          message: detail is String
              ? detail
              : 'Request failed: ${response.statusCode}',
        );
      }

      final tokens = parseRpgTokenPair(response.jsonBodyAsMap);
      await _tokenProvider.setTokens(
        accessToken: tokens.$1,
        refreshToken: tokens.$2,
      );
    } on AuthException {
      rethrow;
    } on http.ClientException catch (error) {
      throw AuthException.networkError('Request failed: ${error.message}');
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  bool _isValidPassword(String password) => password.length >= 8;

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await _tokenProvider.getRefreshToken();
      final accessToken = await _tokenProvider.getAccessToken();

      try {
        await _http.send(
          HttpRequest(
            path: '/auth/logout',
            method: 'POST',
            headers: {'Authorization': 'Bearer $accessToken'},
            body: {'refresh_token': refreshToken},
          ),
        );
      } catch (_) {
        // Logout should succeed locally even if the server request fails.
      }
    } on AuthException {
      // No refresh token — still clear local storage below.
    } finally {
      await _tokenProvider.clear();
    }
  }
}
