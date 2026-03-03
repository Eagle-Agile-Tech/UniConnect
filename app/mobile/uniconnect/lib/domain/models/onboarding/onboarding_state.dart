import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uniconnect/config/dummy_data.dart';

import '../../../utils/enums.dart';

part 'onboarding_state.freezed.dart';

@freezed
abstract class OnboardingState with _$OnboardingState {
  factory OnboardingState({
    @Default(OnboardingStep.account) OnboardingStep currentStep,
    @Default(false) bool isLoading,
    String? errorMessage,

    // Account
    @Default('') String id,
    @Default('') String firstName,
    @Default('') String lastName,
    @Default('') String username,
    @Default('') String email,
    @Default('') String password,
    DateTime? createdAt,

    // Verification
    @Default('') String otp,
    @Default(false) bool isEmailVerified,

    // Academic
    @Default('') String university,
    @Default('') String degree,
    @Default('') String currentYear,
    DateTime? expectedGraduationYear,

    // Profile
    @Default('') String bio,
    List<InterestRecord>? interests,
    File? profilePicture,
  }) = _OnboardingState;
}
