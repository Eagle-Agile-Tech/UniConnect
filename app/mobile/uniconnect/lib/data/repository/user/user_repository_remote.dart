import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/user/user_repository.dart';
import 'package:uniconnect/data/service/api/models/create_account/create_account_response.dart';

import '../../../utils/result.dart';
import '../../service/api/auth_api_client.dart';

final userRepositoryProvider = Provider<UserRepositoryRemote>((ref) {
  return UserRepositoryRemote(ref.watch(authApiClientProvider));
});

class UserRepositoryRemote implements UserRepository {
  final AuthApiClient _apiClient;

  UserRepositoryRemote(this._apiClient);

  @override
  Future<Result<CreateAccountResponse>> createUserAccount({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    final result = await _apiClient.createUserAccount(
      firstName: firstName,
      lastName: lastName,
      username: username,
      email: email,
      password: password,
    );
    return result;
  }

  @override
  Future<Result> createUserProfile({
    required String id,
    required String university,
    required String degree,
    required String currentYear,
    required DateTime expectedGraduationYear,
    required DateTime createdAt,
    String? bio,
    List<String>? interests,
    File? profilePicture,
  }) async {
    final result = await _apiClient.createUserProfile(
      id: id,
      university: university,
      degree: degree,
      currentYear: currentYear,
      expectedGraduationYear: expectedGraduationYear,
      createdAt: createdAt,
      bio: bio,
      interests: interests,
      profilePicture: profilePicture,
    );
    return result;
  }
}
