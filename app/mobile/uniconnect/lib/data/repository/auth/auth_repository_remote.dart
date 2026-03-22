import 'dart:io';

import 'package:chat_plugin/chat_plugin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:uniconnect/data/service/api/models/create_account/create_account_response.dart';
import 'package:uniconnect/data/service/socket/chat_service.dart' as Chat;

import 'package:uniconnect/utils/result.dart';

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
  Future<bool> verifyOtp(String userId, String otp) async {
    final result = await _authClient.verifyOtp(userId, otp);
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
    return result.fold((data) => true, (error, stackTrace) => false,);
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
        final user = User(
          id: data['id'],
          firstName: data['firstName'],
          lastName: data['lastName'],
          email: data['email'],
          username: data['username'],
          university: data['university'],
          degree: data['degree'],
          currentYear: data['currentYear'],
          expectedGraduationYear: DateTime.parse(data['graduation']),
          createdAt: DateTime.parse(data['createdAt']),
          updatedAt: DateTime.parse(data['updatedAt']),
          role: data['role'],
          bio: data['bio'],
          interests: data['interest'],
          profilePicture: data['profilePicture'],
          isVerified: data['isVerified'],
        );
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
}
