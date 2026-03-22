import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/result.dart';
import '../local/secure_token_storage.dart';
import '../socket/socket_service.dart';
import 'models/create_account/create_account_response.dart';

final authApiProvider = Provider((ref) {
  return AuthApiClient();
});

// fixme: the baseurl is 'http://localhost:3000/api'
final String baseUrl = 'http://localhost:8080';

class AuthApiClient {
  final Dio _client;

  AuthApiClient({Dio? client})
    : _client = client ?? Dio(BaseOptions(baseUrl: baseUrl));

  Future<Result<CreateAccountResponse>> createUserAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        '/auth/register',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
        },
      );
      return Result.ok(CreateAccountResponse.fromJson(response.data));
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  Future<Result> verifyOtp(String userId, String otp) async {
    try {
      await _client.post(
        '/verifyOtp/',
        data: {'userId': userId, 'otp': otp},
      );
      return Result.ok('');
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  //todo: create username checker
  Future<Result> usernameChecker(String username) async{
    try{
      await _client.get('/checkUsername/', data: {'username': username});
      return Result.ok('');
    }on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> createUserProfile({
    required String id,
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
        'id': id,
        'university': university,
        'degree': degree,
        'username': username,
        'currentYear': currentYear,
        'expectedGraduationYear': expectedGraduationYear.toIso8601String(),
        'bio': ?bio,
        if (interests != null) 'interests': jsonEncode(interests),
      };

      if (profilePicture != null) {
        userData['profilePicture'] = await MultipartFile.fromFile(
          profilePicture.path,
          filename: profilePicture.path.split('/').last,
        );
      }
      final formData = FormData.fromMap(userData);
      final response = await _client.post('/createProfile/$id', data: formData);
      // Response contains tokens plus profile picture url
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

  Future<void> logoutUser() async {
    await SecureTokenStorage().delete();
  }
}
