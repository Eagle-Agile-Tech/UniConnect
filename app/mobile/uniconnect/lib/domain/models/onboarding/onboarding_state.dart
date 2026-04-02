import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uniconnect/config/dummy_data.dart';

import '../../../utils/enums.dart';

part 'onboarding_state.freezed.dart';

@freezed
abstract class OnboardingState with _$OnboardingState {
  factory OnboardingState({
    @Default(OnboardingStep.account) OnboardingStep currentStep,
    @Default(EmailType.general) EmailType emailType,
    @Default(false) bool isLoading,
    String? errorMessage,

    // Account
    @Default('') String id,
    @Default('') String firstName,
    @Default('') String lastName,
    @Default('') String username,
    @Default('') String email,
    @Default('') String password,

    // Verification
    @Default(false) bool isEmailVerified,

    // Academic
    @Default('') String university,
    @Default('') String degree,
    @Default('') String currentYear,
    DateTime? expectedGraduationYear,

    // Profile
    String? bio,
    List<InterestRecord>? interests,
    File? profilePicture,
    File? frontID,
    File? backID,
  }) = _OnboardingState;
}
