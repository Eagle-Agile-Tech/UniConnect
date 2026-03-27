import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/domain/models/expert_onboarding/expert_onboarding.dart';

import '../../../../data/repository/auth/auth_repository_remote.dart';
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

  Future<Err?> registerExpert(
    String firstName,
    String lastName,
    String email,
    String university,
    String uniCode,
    String password,
  ) async {
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
    return result.fold((data) => null, (error, stackTrace) => error as Err);
  }

  Future<Err?> verifyEmail(String otp) async {
    final result = await _authRepo.verifyOtp(state.email, otp);
    if (result) {
      return null;
    } else {
      return Result.error('Invalid otp') as Err;
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    await Future.delayed(Duration(seconds: 5));
    return await _authRepo.isUsernameAvailable(username);
  }

  Future<Err?> createExpertProfile(
    String expertise,
    String honor,
    String username,
    String? bio,
    File? profilePicture,
  ) async {
    final result = await _authRepo.createExpertProfile(
      expertise,
      honor,
      username,
      bio,
      profilePicture,
    );
    return result.fold(
      (data) => null,
      (error, stackTrace) => Result.error(error.toString) as Err,
    );
  }
}
