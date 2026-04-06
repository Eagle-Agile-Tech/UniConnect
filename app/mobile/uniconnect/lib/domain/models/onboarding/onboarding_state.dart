import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uniconnect/config/dummy_data.dart';

import '../../../utils/enums.dart';

part 'onboarding_state.freezed.dart';

@freezed
abstract class OnboardingState with _$OnboardingState {
  factory OnboardingState({
    @Default(EmailType.general) EmailType emailType,
    @Default(false) bool isLoading,

    @Default('') String id,
    @Default('') String firstName,
    @Default('') String lastName,
    @Default('') String username,
    @Default('') String email,
    @Default('') String password,
    @Default('') String university,
    @Default('') String degree,
    @Default('') String currentYear,
    required DateTime expectedGraduationYear,

    String? bio,
    List<InterestRecord>? interests,
    File? profilePicture,
    File? frontID,
    File? backID,
  }) = _OnboardingState;
}
