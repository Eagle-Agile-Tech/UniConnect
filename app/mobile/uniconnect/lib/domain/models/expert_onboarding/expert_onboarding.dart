import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'expert_onboarding.freezed.dart';

@freezed
abstract class ExpertOnboardingState with _$ExpertOnboardingState{
  factory ExpertOnboardingState({
    @Default('') String firstName,
    @Default('')  String lastName,
    @Default('')  String email,
    @Default('')  String university,

    @Default('') String expertise,
    @Default('') String honor,
    @Default('') String username,
    @Default('') String bio,
    File? profilePicture

}) = _ExpertOnboardingState;
}