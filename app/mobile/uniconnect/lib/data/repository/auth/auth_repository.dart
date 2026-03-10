import 'dart:io';

import '../../../utils/result.dart';
import '../../service/api/models/create_account/create_account_response.dart';

abstract class AuthRepository {
  Future<bool> get isAuthenticated;
  Future<Result<CreateAccountResponse>> createUserAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });

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
  });
}
