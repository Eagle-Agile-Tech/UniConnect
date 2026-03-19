import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:uniconnect/data/service/api/models/create_account/create_account_response.dart';

import 'package:uniconnect/utils/result.dart';

import '../../service/api/auth_api_client.dart';
import '../../service/api/token_refresher.dart';
import '../../service/local/secure_token_storage.dart';
import 'auth_repository.dart';

final authProvider = Provider<AuthRepositoryRemote>((ref) {
  final apiClient = ref.watch(authApiProvider);
  final fresh = ref.watch(freshProvider);
  return AuthRepositoryRemote(apiClient, fresh);
} );

class AuthRepositoryRemote implements AuthRepository {
  final AuthApiClient _authClient;
  final Fresh<OAuth2Token> _fresh;

  AuthRepositoryRemote(this._authClient, this._fresh);
  @override
  // TODO: implement isAuthenticated
  Future<bool> get isAuthenticated => throw UnimplementedError();

  @override
  Future<Result<CreateAccountResponse>> createUserAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final result = await _authClient.createUserAccount(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );
    return result;
  }

  @override
  Future<Result<String>> createUserProfile({
    required String id,
    required String username,
    required String university,
    required String degree,
    required String currentYear,
    required DateTime expectedGraduationYear,
    required DateTime createdAt,
    String? bio,
    List<String>? interests,
    File? profilePicture,
  }) async {
    final result = await _authClient.createUserProfile(
      id: id,
      username: username,
      university: university,
      degree: degree,
      currentYear: currentYear,
      expectedGraduationYear: expectedGraduationYear,
      createdAt: createdAt,
      bio: bio,
      interests: interests,
      profilePicture: profilePicture,
    );
    return result.fold((data) async {
      final token = OAuth2Token(accessToken: data['access_token'], refreshToken: data['refresh_token']);
      await _fresh.setToken(token);
      return data['profile_picture_url'];
    }, (error, _){
      return Result.error(error);
    });
  }
}
