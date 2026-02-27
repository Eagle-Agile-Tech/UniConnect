import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

enum UserRole {
  @JsonValue('STUDENT') student,
  @JsonValue('EXPERT') expert,
  @JsonValue('INSTITUTION') institution,
}

@freezed
abstract class User with _$User {
  const User._();

  const factory User({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String university,
    required String degree,
    required String currentYear,
    required String expectedGraduationYear,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? bio,
    String? interests,
    String? profilePicture,
    @JsonKey(includeToJson: false) required String passwordHash,
    @Default(UserRole.student) UserRole role,
    @Default(false) bool isVerified,
  }) = _User;

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}