import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fresh_dio/fresh_dio.dart';

import '../local/secure_token_storage.dart';
import 'auth_api_client.dart';

final freshProvider = Provider<Fresh<OAuth2Token>>((ref) {
  return Fresh.oAuth2(
    tokenStorage: SecureTokenStorage(),
    refreshToken: (token, client) async {
      final response = await client.post(
        'auth/refresh',
        data: {'refresh_token': token?.refreshToken},
      );
      return OAuth2Token(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refresh_token'],
      );
    },
    isTokenRequired: (options) =>
        !options.path.contains('/createAccount') && !options.path.contains('/login'),
  );
});

final dioProvider = Provider<Dio>((ref){
  final fresh = ref.watch(freshProvider);
  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  dio.interceptors.add(fresh);
  return dio;
});
