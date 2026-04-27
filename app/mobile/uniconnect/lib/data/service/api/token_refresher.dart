import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:uniconnect/data/service/api/routes/api_routes.dart';
import '../local/secure_token_storage.dart';

final freshProvider = Provider<Fresh<OAuth2Token>>((ref) {
  final refreshDio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {'Content-Type': 'application/json'},
    validateStatus: (status) => status != null && status < 500, // Don't throw on 4xx
  ));

  return Fresh.oAuth2(
    tokenStorage: SecureTokenStorage(),
    httpClient: refreshDio,
    refreshToken: (token, client) async {
      print('🔄 Attempting to refresh token...');
      print('📝 Current refresh token: ${token?.refreshToken?.substring(0, 20)}...');

      if (token?.refreshToken == null) {
        print('❌ No refresh token available');
        throw RevokeTokenException();
      }

      try {
        final response = await client.post(
          '/auth/refresh',
          data: {'refreshToken': token!.refreshToken},
          options: Options(
            headers: {'Content-Type': 'application/json'},
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        print('📡 Refresh response status: ${response.statusCode}');
        print('📡 Refresh response data: ${response.data}');

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;

          final newToken = OAuth2Token(
            accessToken: data['accessToken'] ?? data['access_token'],
            refreshToken: data['refreshToken'] ?? data['refresh_token'],
            expiresIn: (data['accessTokenExpiresIn'] ?? data['expires_in'] ?? 3600).toInt(),
            issuedAt: DateTime.now(),
          );

          print('✅ Token refreshed successfully');
          return newToken;
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          print('❌ Refresh token invalid/expired');
          throw RevokeTokenException();
        } else {
          print('❌ Unexpected refresh response: ${response.statusCode}');
          throw Exception('Failed to refresh token');
        }
      } on DioException catch (e) {
        print('❌ Dio error during refresh: ${e.response?.statusCode} - ${e.message}');
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          throw RevokeTokenException();
        }
        rethrow;
      } catch (e) {
        print('❌ Unexpected error during refresh: $e');
        rethrow;
      }
    },
    // Fix: Properly exclude all auth-related endpoints
    isTokenRequired: (options) {
      final path = options.path;
      // Exclude ALL authentication and public endpoints
      final excludedPaths = [
        '/auth/login',
        '/auth/register',
        '/auth/verify-otp',
        '/auth/refresh',
      ];

      final shouldExclude = excludedPaths.any((excludedPath) => path.contains(excludedPath));
      final isRequired = !shouldExclude;

      print('🔐 Token required for $path: $isRequired');
      return isRequired;
    },
    // Fix: Refresh on BOTH 401 AND 403
    shouldRefresh: (response) {
      final statusCode = response?.statusCode;
      print('🔍 Checking if should refresh - Status: $statusCode');

      if (statusCode == 401 || statusCode == 403) {
        final body = response?.data;
        if (body is Map<String, dynamic>) {
          final message = body['message']?.toString().toLowerCase();
          // Refresh on token-related errors
          final shouldRefresh = message?.contains('expired') == true ||
              message?.contains('invalid token') == true ||
              message?.contains('unauthorized') == true ||
              message?.contains('token') == true;

          print('🔍 Should refresh: $shouldRefresh (message: $message)');
          return shouldRefresh;
        }
        print('🔍 Should refresh: true (no message body)');
        return true;
      }
      return false;
    },
    // Proactively refresh 5 minutes before expiry
    shouldRefreshBeforeRequest: (options, token) {
      if (token?.expiresAt == null) return false;
      final expiresIn = token!.expiresAt!.difference(DateTime.now()).inSeconds;
      final shouldRefresh = expiresIn < 300; // Refresh if less than 5 minutes left
      if (shouldRefresh) {
        print('🔄 Proactive refresh needed - expires in $expiresIn seconds');
      }
      return shouldRefresh;
    },
  );
});

final dioProvider = Provider<Dio>((ref) {
  final fresh = ref.watch(freshProvider);

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
    // Let Dio treat 4xx and 5xx as errors by default
    // Remove custom validateStatus or use default behavior
  ));

  // Add Fresh interceptor FIRST
  dio.interceptors.add(fresh);

  // Add logging interceptor
  dio.interceptors.add(LogInterceptor(
    request: true,
    requestHeader: true,
    requestBody: true,
    responseHeader: true,
    responseBody: true,
    error: true,
  ));

  // Add specific error handler interceptor
  dio.interceptors.add(InterceptorsWrapper(
    onError: (DioException e, handler) {
      // Only handle token/authorization/refresh errors
      final statusCode = e.response?.statusCode;

      final isTokenExpired = statusCode == 401 &&
          _isTokenExpiredError(e.response?.data);

      final isUnauthorized = statusCode == 401 || statusCode == 403;

      final isRefreshError = e.message?.contains('refresh') == true ||
          e.message?.contains('token') == true ||
          e.requestOptions.path.contains('/refresh');

      if (isTokenExpired || isUnauthorized || isRefreshError) {
        print('🔐 Token/Auth error intercepted - Status: $statusCode');
        print('🔐 Error: ${e.message}');

        if (isUnauthorized) {
          print('🚪 Authentication failed - forcing logout');
          // ref.read(authProvider.notifier).forceLogout();
        }

        handler.next(e);
      } else {
        // Pass through all other errors (400, 404, 500, network, etc.)
        print('⚠️ Non-auth error (${statusCode ?? 'no status'}) - passing through');
        handler.next(e);
      }
    },
  ));

  return dio;
});

bool _isTokenExpiredError(dynamic responseData) {
  if (responseData is Map) {
    final message = responseData['message']?.toString().toLowerCase() ?? '';
    final error = responseData['error']?.toString().toLowerCase() ?? '';

    return message.contains('expired') ||
        message.contains('invalid token') ||
        error.contains('expired') ||
        message.contains('token has expired');
  }
  return false;
}