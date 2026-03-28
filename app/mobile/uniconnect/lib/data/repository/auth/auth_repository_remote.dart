import 'dart:io';

import 'package:chat_plugin/chat_plugin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:uniconnect/data/service/api/models/create_account/create_account_response.dart';
import 'package:uniconnect/data/service/socket/chat_service.dart' as Chat;
import 'package:uniconnect/utils/enums.dart';

import 'package:uniconnect/utils/result.dart';

import '../../../domain/models/user/expert/expert.dart';
import '../../../domain/models/user/student/student.dart';
import '../../../domain/models/user/user.dart';
import '../../service/api/auth_api_client.dart';
import '../../service/api/token_refresher.dart';
import 'auth_repository.dart';

final authProvider = Provider<AuthRepositoryRemote>((ref) {
  final apiClient = ref.watch(authApiProvider);
  final fresh = ref.watch(freshProvider);
  final chat = ref.watch(Chat.chatServiceProvider);
  return AuthRepositoryRemote(apiClient, fresh, chat);
});

class AuthRepositoryRemote implements AuthRepository {
  final AuthApiClient _authClient;
  final Fresh<OAuth2Token> _fresh;
  final Chat.ChatService _chatService;

  AuthRepositoryRemote(this._authClient, this._fresh, this._chatService);

  @override
  Future<bool> get isAuthenticated => _authClient.isLoggedIn();

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
  Future<bool> verifyOtp(String email, String otp) async {
    final result = await _authClient.verifyOtp(email, otp);
    return result.fold((data) => true, (error, stackTrace) => false);
  }

  @override
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
  }) async {
    final result = await _authClient.createUserProfile(
      id: id,
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
        final token = OAuth2Token(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        await _fresh.setToken(token);
        // todo: token
        await _chatService.initializeChatPlugin(id);
        await Future.delayed(Duration(milliseconds: 500));
        return Result.ok(data['profilePicture']);
      },
      (error, _) {
        return Result.error(error);
      },
    );
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final result = await _authClient.usernameChecker(username);
    return result.fold((data) => true, (error, stackTrace) => false);
  }

  @override
  Future<Result<User>> login(String username, String password) async {
    final result = await _authClient.loginUser(username, password);
    return result.fold(
      (data) async {
        final token = OAuth2Token(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        await _fresh.setToken(token);
        final role = UserRole.values.firstWhere((e) => e.name == data['role']);
        final user = switch (role) {
          UserRole.student => User(
            id: data['id'],
            firstName: data['firstName'],
            lastName: data['lastName'],
            email: data['email'],
            username: data['username'],
            university: data['university'],
            role: data['role'],
            bio: data['bio'],
            profilePicture: data['profilePicture'],
            student: Student(
              degree: data['degree'],
              currentYear: data['currentYear'],
              expectedGraduationYear: DateTime.parse(data['graduation']),
              interests: data['interest'],
              isVerified: data['isVerified'],
            ),
          ),

          UserRole.expert => User(
            id: data['id'],
            firstName: data['firstName'],
            lastName: data['lastName'],
            email: data['email'],
            username: data['username'],
            university: data['university'],
            role: data['role'],
            bio: data['bio'],
            profilePicture: data['profilePicture'],
            expert: Expert(expertise: data['expertise'], honor: data['honor']),
          ),
        };
        // todo: token
        await _chatService.initializeChatPlugin(data['id']);
        await Future.delayed(Duration(milliseconds: 500));

        return Result.ok(user);
      },
      (error, _) {
        return Result.error(error);
      },
    );
  }

  Future<void> logout() async {
    await _authClient.logoutUser();
    try {
      if (ChatConfig.instance.userId != null) {
        ChatPlugin.chatService.fullDisconnect();
      }
    } catch (e) {}
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
      (data) => Result.ok(data['userId']),
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
        );
        await _fresh.setToken(token);
        // todo: token
        await _chatService.initializeChatPlugin(data['id']);
        await Future.delayed(Duration(milliseconds: 500));
        return Result.ok(data['profilePicture']);
      },
      (error, _) {
        return Result.error(error);
      },
    );
  }
}
