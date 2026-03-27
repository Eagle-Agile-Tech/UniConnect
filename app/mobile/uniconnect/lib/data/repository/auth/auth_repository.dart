import 'dart:io';

import '../../../domain/models/user/user.dart';
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

  Future<bool> verifyOtp(String email, String otp);

  Future<bool> isUsernameAvailable(String username);

  Future<Result<String>> createUserProfile({
    required String id,
    required String username,
    required String university,
    required String degree,
    required String currentYear,
    required DateTime expectedGraduationYear,
    String? bio,
    List<String>? interests,
    File? profilePicture,
  });

  Future<Result<User>> login(String username, String password);

  Future<Result> registerExpert(
    String firstName,
    String lastName,
    String email,
    String university,
    String uniCode,
    String password,
  );

  Future<Result<String>> createExpertProfile(
    String expertise,
    String honor,
    String username,
    String? bio,
    File? profilePicture,
  );
}
