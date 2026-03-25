import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/user/user_repository_remote.dart';

import '../../data/repository/auth/auth_repository_remote.dart';
import '../../data/service/socket/chat_service.dart';
import '../../domain/models/user/user.dart';
import '../../utils/result.dart';
import 'onboarding/view_models/onboarding_viewmodel_provider.dart';

// class AuthState {
//   final bool isLoading;
//   final bool isAuthenticated;
//
//   const AuthState({required this.isLoading, required this.isAuthenticated});
//
//   const AuthState.loading() : isLoading = true, isAuthenticated = false;
//
//   const AuthState.authenticated() : isLoading = false, isAuthenticated = true;
//
//   const AuthState.unauthenticated()
//     : isLoading = false,
//       isAuthenticated = false;
// }
//
// final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
//   (ref) => AuthNotifier(ref.read(authProvider), ref.watch(userRepoProvider)),
// );
//
// class AuthNotifier extends StateNotifier<AuthState> {
//   final AuthRepositoryRemote _repo;
//   final UserRepositoryRemote _userRepo;
//
//   AuthNotifier(this._repo, this._userRepo) : super(const AuthState.loading()) {
//     _checkAuth();
//   }
//
//   Future<void> _checkAuth() async {
//     final isAuth = await _repo.isAuthenticated;
//     final result = await _userRepo.getCurrentUser();
//     if (isAuth) {
//       result.fold((user) {
//         ref.read(currentUserProvider.notifier).state = user;
//       }, (_, _) => state = const AuthState.unauthenticated());
//     } else {
//       state = const AuthState.unauthenticated();
//     }
//   }
//
//   Future<void> login(String username, String password) async {
//     final result = await _repo.login(username, password);
//     result.fold(
//       (_) => state = const AuthState.authenticated(),
//       (_, _) => state = const AuthState.unauthenticated(),
//     );
//   }
//
//   Future<void> logout() async {
//     await _repo.logout();
//     state = const AuthState.unauthenticated();
//   }
// }

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
  late final OnboardingViewmodel _onborader;

  @override
  Future<AuthState> build() async {
    _userRepo = ref.read(userRepoProvider);
    _repo = ref.watch(authProvider);
    final isAuth = await _repo.isAuthenticated;
    if (!isAuth) return const AuthState(user: null);
    _chat = ref.watch(chatServiceProvider);
    final result = await _userRepo.getCurrentUser();

    return result.fold(
      (user) {
        _chat.initializeChatPlugin(user.id);
        return AuthState(user: user);
      },
      (_, __) => const AuthState(user: null),
    );
  }

  Future<void> login(String username, String password) async {
    state = const AsyncLoading();

    final result = await _repo.login(username, password);

     result.fold(
      (user) => state = AsyncData(AuthState(user: user)),
      (_, _) => state = const AsyncData(AuthState(user: null)),
    );
  }

  Future<Err?> registerUser() async{
    _onborader = ref.watch(onboardingProvider.notifier);
    final result = await _onborader.completeOnboarding();
    return result.fold((user){
      AuthState(user:user);
      return null;
    }, (error, stackTrace) => Result.error(error) as Err,);
  }
}
