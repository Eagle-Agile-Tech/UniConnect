import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/user/user_repository_remote.dart';
import 'package:uniconnect/domain/models/onboarding/onboarding_state.dart';

import '../../../../utils/enums.dart';

final onboardingProvider =
NotifierProvider<OnboardingViewmodel, OnboardingState>(
    OnboardingViewmodel.new
);

class OnboardingViewmodel extends Notifier<OnboardingState> {
  late final UserRepositoryRemote _userRepo;

  @override
  OnboardingState build() => OnboardingState();

  // Account
  void updateAccount(String firstName,
      String lastName,
      String username,
      String email,
      String password,) {
    state = state.copyWith(
      firstName: firstName,
      lastName: lastName,
      username: username,
      email: email,
      password: password,
    );
  }

  Future<void> submitAccount() async {
    _userRepo = ref.read(userRepositoryProvider);
    state = state.copyWith(isLoading: true, errorMessage: null);
      final result = await _userRepo.createUserAccount(
          firstName: state.firstName,
          lastName: state.lastName,
          username: state.username,
          email: state.email,
          password: state.password);
      result.fold((data){
        state = state.copyWith(
          currentStep: OnboardingStep.verifyEmail,
          isLoading: false,
          otp: data.otpCode,
          id: data.userId
        );
      }, (error,stackTrace){
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
      });
  }

  // Verify Email
  void updateOTP(String otp) {
    state = state.copyWith(otp: otp, isLoading: true);
  }

  Future<void> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, otp: otp);
    try {
      //TODO: call to api to fetch otp and verify
      await Future.delayed(Duration(seconds: 2));
      state = state.copyWith(
        isEmailVerified: true,
        currentStep: OnboardingStep.academic,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Academic
  void updateAcademic(String university,
      String degree,
      String currentYear,
      String expectedGraduationYear,) {
    state = state.copyWith(
      university: university,
      degree: degree,
      currentYear: currentYear,
      expectedGraduationYear: expectedGraduationYear,
    );
  }

  void submitAcademic() {
    state = state.copyWith(currentStep: OnboardingStep.profile);
  }

  // Profile
  void updateProfile(String? bio, String? interests, String? profilePicture) {
    state = state.copyWith(
      bio: bio ?? state.bio,
      interests: interests ?? state.interests,
      profilePicture: profilePicture ?? state.profilePicture,
    );
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(isLoading: true);
    try {
      //TODO: call to api to submit profile details and complete onboarding
      await Future.delayed(Duration(seconds: 2));
      state = state.copyWith(
          currentStep: OnboardingStep.completed, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
