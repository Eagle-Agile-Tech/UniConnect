import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/config/dummy_data.dart';
import 'package:uniconnect/domain/models/onboarding/onboarding_state.dart';
import 'package:uniconnect/domain/models/user/student/student.dart';
import 'package:uniconnect/domain/models/user/user.dart';
import 'package:uniconnect/utils/result.dart';

import '../../../../data/repository/auth/auth_repository_remote.dart';
import '../../../../utils/enums.dart';

final onboardingProvider =
    NotifierProvider<OnboardingViewmodel, OnboardingState>(
      OnboardingViewmodel.new,
    );

class OnboardingViewmodel extends Notifier<OnboardingState> {
  late AuthRepositoryRemote _authRepo;

  @override
  OnboardingState build() {
    _authRepo = ref.read(authProvider);
    return OnboardingState(expectedGraduationYear: DateTime.now());
  }

  Future<Err?> submitAccount(
    String confirmPassword,
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    state = state.copyWith(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      isLoading: true,
    );
    final result = await _authRepo.createUserAccount(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
    return result.fold(
      (data) {
        state = state.copyWith(
          isLoading: false,
        );
        return null;
      },
      (error, stackTrace) {
        state = state.copyWith(
          isLoading: false,
        );
        return Result.error(error) as Err;
      },
    );
  }

  Future<Err?> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true,);

    final result = await _authRepo.verifyOtp(state.email, otp);

    return result.fold((data) {
      state = state.copyWith(
        isLoading: false,
        university: data,
      );
      return null;
    }, (error, stackTrace) {
      state = state.copyWith(
        isLoading: false,
      );
      return Result.error(error) as Err;
    });
  }

  Future<Err?> verifyId(File front, File back) async {
    state = state.copyWith(isLoading: true, );
    final result = await _authRepo.verifyId(front, back);
    return result.fold(
      (data) {
        state = state.copyWith(isLoading: false, );
      },
      (error, stackTrace) {
        state = state.copyWith(isLoading: false, );
        return Result.error(error) as Err;
      },
    );
  }

  // Academic
  void updateAcademic(
    String university,
    String degree,
    String currentYear,
    DateTime expectedGraduationYear,
  ) {
    state = state.copyWith(
      university: university,
      degree: degree,
      currentYear: currentYear,
      expectedGraduationYear: expectedGraduationYear,
    );
  }

  Future<bool> isUsernameAvailable(String username) async {
    return await _authRepo.isUsernameAvailable(username);
  }

  // Profile
  void updateProfile(
    String username,
    String? bio,
    List<InterestRecord>? interests,
    File? profilePicture,
  ) {
    state = state.copyWith(
      username: username,
      bio: bio,
      interests: interests,
      profilePicture: profilePicture,
    );
  }

  Future<Result<User>> completeOnboarding() async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _authRepo.createUserProfile(
        username: state.username,
        bio: state.bio,
        interests: state.interests
            ?.map((interest) => interest.interest)
            .toList(),
        profilePicture: state.profilePicture,
        university: state.university,
        degree: state.degree,
        currentYear: state.currentYear,
        expectedGraduationYear: state.expectedGraduationYear!,
      );
      return result.fold(
        (data) {
          state = state.copyWith(
            isLoading: false,
          );
          return Result.ok(data);
        },
        (error, stackTrace) {
          state = state.copyWith(
            isLoading: false,
          );
          return Result.error(error);
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false,);
      return Result.error('Failed to complete onboarding');
    }
  }
}
