import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:uniconnect/ui/chat/viewmodels/chat_provider.dart';

import 'package:uniconnect/utils/result.dart';

import '../../../domain/models/user/user.dart';
import '../../service/api/auth_api_client.dart';
import '../../service/api/token_refresher.dart';
import '../../service/socket/chat_service.dart';
import 'auth_repository.dart';

final authProvider = Provider<AuthRepositoryRemote>((ref) {
  final apiClient = ref.watch(authApiProvider);
  final fresh = ref.watch(freshProvider);
  return AuthRepositoryRemote(apiClient, fresh);
});

class AuthRepositoryRemote implements AuthRepository {
  final AuthApiClient _authClient;
  final Fresh<OAuth2Token> _fresh;

  AuthRepositoryRemote(this._authClient, this._fresh);

  @override
  Future<bool> get isAuthenticated => _authClient.isLoggedIn();

  @override
  Future<Result> createUserAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final result = await _authClient.createUserAccount(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
    return result;
  }

  @override
  Future<Result<String>> verifyOtp(String email, String otp) async {
    final result = await _authClient.verifyOtp(email, otp);
    return result.fold((data) async {
      final token = OAuth2Token(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
        expiresIn: data['accessTokenExpiresIn'],
        issuedAt: DateTime.fromMillisecondsSinceEpoch(
          data['accessTokenIssuedAt'] * 1000,
        ),
      );
      await _fresh.setToken(token);
      return Result.ok(data['university'] as String);
    }, (error, stackTrace) => Result.error(error));
  }

  @override
  Future<Result> verifyId(File front, File back) async {
    final result = await _authClient.verifyId(front, back);
    return result.fold(
      (data) => Result.ok(''),
      (error, stackTrace) => Result.error(error),
    );
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final result = await _authClient.usernameChecker(username);
    return result.fold((data) => true, (error, stackTrace) => false);
  }

  @override
  Future<Result<User>> createUserProfile({
    required String username,
    required String university,
    required String degree,
    required String currentYear,
    required DateTime expectedGraduationYear,
    String? bio,
    List<String>? interests,
    File? profilePicture,
  }) async {
    final result = await _authClient.createUserProfile(
      username: username,
      university: university,
      degree: degree,
      currentYear: currentYear,
      expectedGraduationYear: expectedGraduationYear,
      bio: bio,
      interests: interests,
      profilePicture: profilePicture,
    );
    return result.fold(
      (data) async {
        await Future.delayed(const Duration(milliseconds: 500));
        return Result.ok(User.fromJson(data));
      },
      (error, _) {
        return Result.error(error);
      },
    );
  }

  @override
  Future<Result<User>> login(String email, String password) async {
    final result = await _authClient.loginUser(email, password);
    return result.fold(
      (data) async {
        final token = OAuth2Token(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          expiresIn: data['accessTokenExpiresIn'],
          issuedAt: DateTime.fromMillisecondsSinceEpoch(
            data['accessTokenIssuedAt'] * 1000,
          ),
        );
        await _fresh.setToken(token);

        await Future.delayed(const Duration(milliseconds: 500));

        return Result.ok(User.fromJson(data));
      },
      (error, _) {
        return Result.error(error);
      },
    );
  }

  @override
  Future<Result<User?>> googleLogin(String idToken) async {
    final result = await _authClient.googleLogin(idToken);
    return result.fold(
      (data) async {
        if(data.containsKey('university')){
          final token = OAuth2Token(
            accessToken: data['accessToken'],
            refreshToken: data['refreshToken'],
            expiresIn: data['accessTokenExpiresIn'],
            issuedAt: DateTime.fromMillisecondsSinceEpoch(
              data['accessTokenIssuedAt'] * 1000,
            ),
          );
          await _fresh.setToken(token);

          await Future.delayed(const Duration(milliseconds: 500));

          return Result.ok(User.fromJson(data));
        } else {
          return Result.ok(null);
        }
      },
      (error, _) {
        return Result.error(error);
      },
    );
  }

  Future<bool> logout() async {
    await _fresh.setToken(null);
    final result = await _authClient.logoutUser();
    return result;
  }

  // Expert
  @override
  Future<Result<String>> registerExpert(
    String firstName,
    String lastName,
    String email,
    String university,
    String uniCode,
    String password,
  ) async {
    final result = await _authClient.registerExpert(
      firstName,
      lastName,
      email,
      university,
      uniCode,
      password,
    );
    return result.fold(
      (data) => Result.ok(data['userId'] as String),
      (error, stackTrace) => Result.error(error),
    );
  }

  @override
  Future<Result<String>> createExpertProfile(
    String expertise,
    String honor,
    String username,
    String? bio,
    File? profilePicture,
  ) async {
    final result = await _authClient.createExpertProfile(
      expertise,
      honor,
      username,
      bio,
      profilePicture,
    );
    return result.fold(
      (data) async {
        final token = OAuth2Token(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          expiresIn: data['accessTokenExpiresIn'].toInt(),
          issuedAt: DateTime.now(),
        );
        await _fresh.setToken(token);
        await Future.delayed(const Duration(milliseconds: 500));
        return Result.ok(data['profilePicture'] as String);
      },
      (error, _) {
        return Result.error(error);
      },
    );
  }

  @override
  Future<Result<dynamic>> sendOtp(String email) async {
    final result = await _authClient.forgetPassword(email);
    return result.fold((data) async {
      return Result.ok('');
    }, (error, stackTrace) => Result.error(error));
  }

  @override
  Future<Result> changePassword(String email, String otp, String password, String confirmPassword) async {
    final result = await _authClient.changePassword(email, otp, password, confirmPassword);
    return result.fold((data) async {
      return Result.ok('');
    }, (error, stackTrace) => Result.error(error));
  }

}
