import 'dart:io';

import '../../../domain/models/user/user.dart';
import '../../../utils/result.dart';

abstract class AuthRepository {
  Future<bool> get isAuthenticated;

  Future<Result> createUserAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  });

  Future<Result<String>> verifyOtp(String email, String otp);

  Future<Result> verifyId(File front,  File back);

  Future<bool> isUsernameAvailable(String username);

  Future<Result<User>> createUserProfile({
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

  Future<Result<User?>> googleLogin(String idToken);

  Future<Result> registerExpert(
    String firstName,
    String lastName,
    String email,
    String university,
    String uniCode,
    String password,
    String confirmPassword,
  );

  Future<Result<User>> createExpertProfile(
    String expertise,
    String honor,
    String username,
    String? bio,
    File? profilePicture,
  );

  Future<Result> sendOtp(String email);

  Future<Result> changePassword(String email, String otp, String password, String confirmPassword);
}
