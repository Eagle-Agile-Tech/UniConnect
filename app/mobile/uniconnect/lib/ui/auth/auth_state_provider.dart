import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/user/user_repository_remote.dart';

import '../../data/repository/auth/auth_repository_remote.dart';
import '../../data/service/socket/chat_service.dart';
import '../../domain/models/user/user.dart';
import '../../utils/result.dart';
import 'onboarding/view_models/onboarding_viewmodel_provider.dart';
import 'onboarding_experts/viewmodel/expert_onboarding_provider.dart';

class AuthState {
  final User? user;

  bool get isAuthenticated => user != null;

  const AuthState({this.user});
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthState> {
  late final AuthRepositoryRemote _repo;
  late final UserRepositoryRemote _userRepo;
  late final ChatService _chat;
  late final ExpertOnboardingViewModel _onBoardExpert;


  @override
  Future<AuthState> build() async {
    try {
      _userRepo = ref.read(userRepoProvider);
      _repo = ref.read(authProvider);

      final isAuth = await _repo.isAuthenticated;
      if (!isAuth) return const AuthState(user: null);

      _chat = ref.watch(chatServiceProvider);

      final result = await _userRepo.getCurrentUser();

      return result.fold((user) {
        _chat.initializeChatPlugin(user.id);
        return AuthState(user: user);
      }, (_, _) => const AuthState(user: null));

    } catch (e, st) {
      return const AuthState(user: null);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();

    final result = await _repo.login(email, password);

    result.fold(
      (user) => state = AsyncData(AuthState(user: user)),
      (_, _) => state = const AsyncData(AuthState(user: null)),
    );
  }

  Future<bool> logout() async {
    final result = await _repo.logout();
    if (result) {
      state = AsyncData(AuthState(user: null));
    }
    return result;
  }

  Future<Err?> registerStudent() async {
    final _onborader = ref.read(onboardingProvider.notifier);
    final result = await _onborader.completeOnboarding();
    return result.fold((user) {
      state = AsyncData(AuthState(user: user));
      return null;
    }, (error, stackTrace) => Result.error(error) as Err);
  }

  Future<Err?> registerExpert(
    String expertise,
    String honor,
    String username,
    String? bio,
    File? profilePicture,
  ) async {
    _onBoardExpert = ref.read(expertOnboardingProvider.notifier);
    final result = await _onBoardExpert.createExpertProfile(
      expertise,
      honor,
      username,
      bio,
      profilePicture,
    );
    return result.fold((user) {
      AuthState(user: user);
      return null;
    }, (error, stackTrace) => Result.error(error) as Err);
  }

  Future<Result> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? bio,
    File? profilePic,
  }) async {

    final userRepo = _userRepo;
    final result = await userRepo.updateProfile(
      firstName,
      lastName,
      username,
      bio,
      profilePic,
    );

    return result.fold((data) async {
      final updatedUser = await _userRepo.getCurrentUser();
      updatedUser.fold(
        (data) => state = AsyncData(AuthState(user: data)),
        (error, stackTrace) => state  = const AsyncData(AuthState(user: null)),
      );
      return Result.ok('Profile updated');
    }, (error, _) => Result.error(error));
  }
}
