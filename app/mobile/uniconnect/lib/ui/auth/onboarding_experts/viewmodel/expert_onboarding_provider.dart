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

  Future<Err?> registerExpert(String firstName,
      String lastName,
      String email,
      String university,
      String uniCode,
      String password,
      String confirmPassword,) async {
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
      confirmPassword,
    );
    return result.fold((data){
      return null;
    }, (error, stackTrace) => Result.error(error, stackTrace) as Err);
  }

  Future<Err?> verifyEmail(String otp) async {
    final result = await _authRepo.verifyExpertOtp(state.email, otp);
    return result.fold(
      (data) {
        return null;
      }, (error, stackTrace) => Result.error(error, stackTrace) as Err,
    );
  }

  Future<bool> isUsernameAvailable(String username) async {
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
              data
            ),
            (error, stackTrace) => Result.error(error.toString()),
      );
    } catch (e) {
      return Result.error('Failed to complete onboarding');
    }
  }
}
