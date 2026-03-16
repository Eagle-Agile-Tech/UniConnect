import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/config/dummy_data.dart';
import 'package:uniconnect/data/repository/user/user_repository_remote.dart';
import 'package:uniconnect/domain/models/onboarding/onboarding_state.dart';
import 'package:uniconnect/domain/models/user/user.dart';
import 'package:uniconnect/ui/profile/view_models/user_provider.dart';
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
          otp: data.otpCode,
          id: data.userId,
          createdAt: data.createdAt,
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

  Err? verifyOtp(String otp) {
    if (otp != state.otp) {
      return Result.error('Invalid OTP') as Err;
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

  Future<Err?> completeOnboarding() async {
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
        createdAt: state.createdAt!,
      );
      return result.fold(
        (data) {
          state = state.copyWith(
            currentStep: OnboardingStep.completed,
            isLoading: false,
          );
          ref.read(userProvider.notifier).state = User(
            id: state.id,
            firstName: state.firstName,
            lastName: state.lastName,
            username: state.username,
            email: state.email,
            university: state.university,
            degree: state.degree,
            currentYear: state.currentYear,
            expectedGraduationYear: state.expectedGraduationYear!,
            bio: state.bio,
            interests: state.interests
                ?.map((interest) => interest.interest)
                .toList(),
            profilePicture: data,
            createdAt: state.createdAt!,
            updatedAt: state.createdAt!,
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
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return Result.error('Failed to complete onboarding') as Err;
    }
  }
}
