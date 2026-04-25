import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  late final OnboardingViewmodel _onborader;



  @override
  Future<AuthState> build() async {
    try {
      _userRepo = ref.read(userRepoProvider);
      _repo = ref.read(authProvider);
      _onborader = ref.read(onboardingProvider.notifier);

      final isAuth = await _repo.isAuthenticated;
      if (!isAuth) return const AuthState(user: null);

      final result = await _userRepo.getCurrentUser();

      return result.fold((user) {
        return AuthState(user: user);
      }, (_, _) => const AuthState(user: null));
    } catch (e) {
      return const AuthState(user: null);
    }
  }

  Future<Result> sendOtp(String email) async {
    final result =  await _repo.sendOtp(email);
    return result.fold((data) async {
      return Result.ok('');
    }, (error, stackTrace) => Result.error(error));
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();

    final result = await _repo.login(email, password);

    result.fold(
          (user) async {
        state = AsyncData(AuthState(user: user));
            await Future.delayed(Duration(milliseconds: 500));
            _chat.initialize();
        },
          (_, _) => state = const AsyncData(AuthState(user: null)),
    );
  }

  Future<Result<String?>> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      const String androidClient =
          "986632048471-94ssepv0ha12q6e944golr3hr7srqkts.apps.googleusercontent.com";
      const String serverClient =
          "986632048471-j0diers30nqi8lq9jf67485a9fmtgo05.apps.googleusercontent.com";
      final GoogleSignIn signIn = GoogleSignIn.instance;
      await signIn.initialize(
        serverClientId: serverClient,
        clientId: androidClient,
      );

      final GoogleSignInAccount googleUser = await signIn.authenticate();

      final auth = await googleUser.authentication;

      final idToken = auth.idToken;

      if (idToken == null) {
        state = const AsyncData(AuthState(user: null));
        return Result.error('Failed to authenticate');
      }

      final result = await _onborader.signInWithGoogle(idToken);

      return result.fold(
            (user) async {
          if (user != null) {
            state = AsyncData(AuthState(user: user));
            await Future.delayed(const Duration(milliseconds: 500));
            _chat.initialize();
            return Result.ok(null);
          } else {
            state = const AsyncData(AuthState(user: null));
            return Result.ok('Proceed');
          }
        },
            (error, _) {
          state = const AsyncData(AuthState(user: null));
          return Result.error(error);
        },
      );
    } catch (e) {
      state = const AsyncData(AuthState(user: null));
      return Result.error(e.toString());
    }
  }

  Future<Result<String?>> signInWithMicrosoft() async {
    state = const AsyncLoading();
    final result = await _onborader.signInWithMicrosoft();
    return result.fold(
          (user) async {
        if (user != null) {
          state = AsyncData(AuthState(user: user));
          await Future.delayed(const Duration(milliseconds: 500));
          _chat.initialize();
          return Result.ok(null);
        } else {
          state = const AsyncData(AuthState(user: null));
          return Result.ok('Proceed');
        }
      },
          (error, _) {
        state = const AsyncData(AuthState(user: null));
        return Result.error(error);
      },
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
    final result = await _onborader.completeOnboarding();
    return result.fold((user) async {
      state = AsyncData(AuthState(user: user));
      await Future.delayed(Duration(milliseconds: 500));
      await _chat.initialize();
      return null;
    }, (error, stackTrace) => Result.error(error) as Err);
  }

  Future<Err?> registerExpert(String expertise,
      String honor,
      String username,
      String? bio,
      File? profilePicture,) async {
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
            (error, stackTrace) =>
        state = const AsyncData(AuthState(user: null)),
      );
      return Result.ok('Profile updated');
    }, (error, _) => Result.error(error));
  }
}
