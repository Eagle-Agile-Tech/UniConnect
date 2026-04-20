// token_refresher.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:uniconnect/data/service/api/routes/api_routes.dart';
import '../local/secure_token_storage.dart';

final freshProvider = Provider<Fresh<OAuth2Token>>((ref) {
  final refreshDio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {'Content-Type': 'application/json'},
  ));

  return Fresh.oAuth2(
    tokenStorage: SecureTokenStorage(),
    httpClient: refreshDio,
    refreshToken: (token, client) async {
      try {
        final response = await client.post(
          '/auth/refresh',
          data: {'refresh_token': token?.refreshToken},
        );

        final data = response.data as Map<String, dynamic>;

        if (data['error'] == 'refresh_token_revoked' ||
            data['error'] == 'refresh_token_expired' ||
            data['message']?.contains('refresh') == true) {
          throw RevokeTokenException();
        }

        return OAuth2Token(
          accessToken: data['access_token'] ?? data['accessToken'],
          refreshToken: data['refresh_token'] ?? data['refreshToken'],
          expiresIn: (data['access_token_expires_in'] ?? data['expiresIn'] ?? 3600).toInt(),
          issuedAt: DateTime.now(),
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          throw RevokeTokenException();
        }
        rethrow;
      }
    },
    isTokenRequired: (options) {
      final path = options.path;
      return !path.contains('/auth/register') &&
          !path.contains('/auth/login') &&
          !path.contains('/auth/verify-otp');
    },
    shouldRefresh: (response) {
      if (response?.statusCode != 401) return false;
      final body = response?.data;
      if (body is Map<String, dynamic>) {
        final message = body['message']?.toString().toLowerCase();
        return message?.contains('expired') == true ||
            message?.contains('invalid token') == true;
      }
      return true;
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
  ));
  dio.interceptors.add(fresh);
  dio.interceptors.add(LogInterceptor(
    request: true,
    requestHeader: true,
    requestBody: true,
    responseHeader: true,
    responseBody: true,
    error: true,
  ));
  return dio;
});