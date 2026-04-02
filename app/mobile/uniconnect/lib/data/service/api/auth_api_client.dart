import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/result.dart';
import '../local/secure_token_storage.dart';
import 'models/create_account/create_account_response.dart';

final authApiProvider = Provider((ref) {
  return AuthApiClient();
});

// todo: integrate the baseUrl into the endpoints when using the real real backend

final String baseUrl = 'http://localhost:3000/api';

class AuthApiClient {
  final Dio _client;

  AuthApiClient({Dio? client})
    : _client = client ?? Dio(BaseOptions(baseUrl: baseUrl));

  Future<Result> createUserAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      await _client.post(
        '/auth/register',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'passwordConfirm': confirmPassword,
        },
      );
      return Result.ok('');
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  Future<Result<Map<String,dynamic>>> verifyOtp(String email, String otp) async {
    try {
      final response = await _client.post(
        '/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      // { 'university': 'Jimma university' or 'university': 'general'} -> accessToken, refreshToken
      return Result.ok(response.data);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result> verifyId(File front, File back) async {
    try{
      Map<String,dynamic> data = {};
      data['documentFrontImage'] = await MultipartFile.fromFile(front.path, filename: front.path.split('/').last);
      data['documentBackImage'] = await MultipartFile.fromFile(back.path, filename: back.path.split('/').last);
      final formData = FormData.fromMap(data);
      await _client.post('/auth/verify-id', data: formData);
      return Result.ok('');
    }on DioException catch(e){
      return Result.error(e);
    }
  }

  //fixme: as the user this logics can run
  Future<Result> usernameChecker(String username) async {
    try {
      await _client.get(
        '/users/username/$username/available',
      );
      return Result.ok('');
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> createUserProfile({
    required String username,
    required String university,
    required String degree,
    required String currentYear,
    required DateTime expectedGraduationYear,
    String? bio,
    List<String>? interests,
    File? profilePicture,
  }) async {
    try {
      final Map<String, dynamic> userData = {
        'universityName': university,
        'department': degree,
        'username': username,
        'yearOfStudy': currentYear,
        'graduationYear': expectedGraduationYear.toIso8601String(),
        'bio': ?bio,
        if (interests != null) 'interests': jsonEncode(interests),
      };

      if (profilePicture != null) {
        userData['profileImage'] = await MultipartFile.fromFile(
          profilePicture.path,
          filename: profilePicture.path.split('/').last,
        );
      }
      final formData = FormData.fromMap(userData);
      final response = await _client.post('/users/profile', data: formData);
      return Result.ok(response.data);
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> loginUser(
    String username,
    String password,
  ) async {
    try {
      final response = await _client.post(
        '/login/',
        data: {'username': username, 'password': password},
      );
      // return user data
      return Result.ok(response.data);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await SecureTokenStorage().read();
    if (token == null) {
      return false;
    } else {
      return true;
    }
  }

  Future<bool> logoutUser() async {
    try {
      await SecureTokenStorage().delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Expert
  Future<Result<dynamic>> registerExpert(
    String firstName,
    String lastName,
    String email,
    String university,
    String uniCode,
    String password,
  ) async {
    try {
      final response = await _client.post(
        '/register/expert/',
        data: {
          'fistName': firstName,
          'lastName': lastName,
          'email': email,
          'university': university,
          'uniCode': uniCode,
          'password': password,
        },
      );
      return Result.ok(response.data);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> createExpertProfile(
    String expertise,
    String honor,
    String username,
    String? bio,
    File? profilePicture,
  ) async {
    try {
      final Map<String, dynamic> userData = {
        'expertise': expertise,
        'honor': honor,
        'username': username,
        'bio': ?bio,
      };
      if (profilePicture != null) {
        userData['profilePicture'] = await MultipartFile.fromFile(
          profilePicture.path,
          filename: profilePicture.path.split('/').last,
        );
      }
      final formData = FormData.fromMap(userData);
      final response = await _client.post(
        '/createExpertProfile/',
        data: formData,
      );
      // Response contains tokens plus profile picture url
      return Result.ok(response.data);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }
}
