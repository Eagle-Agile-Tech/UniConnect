import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/domain/models/expert_onboarding/expert_onboarding.dart';

import '../../../../data/repository/auth/auth_repository_remote.dart';
import '../../../../domain/models/user/user.dart';
import '../../../../utils/enums.dart';
import '../../../../utils/result.dart';

final expertOnboardingProvider =
NotifierProvider<ExpertOnboardingViewModel, ExpertOnboardingState>(
  ExpertOnboardingViewModel.new,
);

class ExpertOnboardingViewModel extends Notifier<ExpertOnboardingState> {
  late final AuthRepositoryRemote _authRepo;

  @override
  ExpertOnboardingState build() {
    _authRepo = ref.read(authProvider);
    return ExpertOnboardingState();
  }

  //todo: I feel like we can refactor this into the student create account method
  Future<Err?> registerExpert(String firstName,
      String lastName,
      String email,
      String university,
      String uniCode,
      String password,) async {
    state = state.copyWith(
      firstName: firstName,
      lastName: lastName,
      email: email,
      university: university,
    );
    final result = await _authRepo.registerExpert(
      firstName,
      lastName,
      email,
      university,
      uniCode,
      password,
    );
    return result.fold((data){
      state = state.copyWith(id: data);
      return null;
    }, (error, stackTrace) => error as Err);
  }

  Future<Err?> verifyEmail(String otp) async {
    final result = await _authRepo.verifyOtp(state.email, otp);
    return result.fold(
      (data) {
        state = state.copyWith(
          university: data
        );
        return null;
      }, (error, stackTrace) => Result.error(error) as Err,
    );
  }

  Future<bool> isUsernameAvailable(String username) async {
    await Future.delayed(Duration(seconds: 5));
    return await _authRepo.isUsernameAvailable(username);
  }

  Future<Result<User>> createExpertProfile(String expertise,
      String honor,
      String username,
      String? bio,
      File? profilePicture,) async {
    state = state.copyWith(
      expertise: expertise,
      username: username,
      bio: bio,
      honor: honor,
      profilePicture: profilePicture,
    );
    try {
      final result = await _authRepo.createExpertProfile(
        expertise,
        honor,
        username,
        bio,
        profilePicture,
      );
      return result.fold(
            (data) =>
            Result.ok(
              User(
                id: state.id,
                firstName: '',
                lastName: '',
                email: '',
                username: '',
                university: '',
                role: UserRole.EXPERT,
                networkCount: 0
              ),
            ),
            (error, stackTrace) => Result.error(error.toString),
      );
    } catch (e) {
      return Result.error('Failed to complete onboarding');
    }
  }
}
