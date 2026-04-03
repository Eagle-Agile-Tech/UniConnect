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
  late final AuthRepositoryRemote _authRepo;

  @override
  OnboardingState build() => OnboardingState();

  // Account
  void updateAccount(
    String firstName,
    String lastName,
    String email,
    String password,
  ) {
    state = state.copyWith(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );
  }

  Future<Err?> submitAccount() async {
    _authRepo = ref.read(authProvider);
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _authRepo.createUserAccount(
      firstName: state.firstName,
      lastName: state.lastName,
      email: state.email,
      password: state.password,
    );
    return result.fold(
      (data) {
        state = state.copyWith(
          currentStep: OnboardingStep.verifyEmail,
          isLoading: false,
          id: data.userId,
        );
        return null;
      },
      (error, stackTrace) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
        return Result.error(error) as Err;
      },
    );
  }

  Future<Err?> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authRepo.verifyOtp(state.email, otp);

    if (!result) {
      state = state.copyWith(isLoading: false);
      return Result.error('Invalid otp') as Err;
    }

    state = state.copyWith(
      isEmailVerified: true,
      currentStep: OnboardingStep.academic,
      isLoading: false,
    );

    return null;
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
      currentStep: OnboardingStep.profile,
    );
  }

  Future<bool> isUsernameAvailable(String username) async {
    await Future.delayed(Duration(seconds: 5));
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
      bio: bio ?? state.bio,
      interests: interests,
      profilePicture: profilePicture,
    );
  }

  Future<Result<User>> completeOnboarding() async {
    state = state.copyWith(isLoading: true);
    try {
      //TODO: call to api to submit profile details and complete onboarding
      final result = await _authRepo.createUserProfile(
        id: state.id,
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
            currentStep: OnboardingStep.completed,
            isLoading: false,
          );
          final user = User(
            id: state.id,
            firstName: state.firstName,
            lastName: state.lastName,
            username: state.username,
            email: state.email,
            university: state.university,
            bio: state.bio,
            profilePicture: data,
            role: UserRole.student,
            student: Student(
              degree: state.degree,
              currentYear: state.currentYear,
              expectedGraduationYear: state.expectedGraduationYear!,
              interests: state.interests
                  ?.map((interest) => interest.interest)
                  .toList(),
            ),
          );
          return Result.ok(user);
        },
        (error, stackTrace) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: error.toString(),
          );
          return Result.error(error);
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return Result.error('Failed to complete onboarding');
    }
  }
}
