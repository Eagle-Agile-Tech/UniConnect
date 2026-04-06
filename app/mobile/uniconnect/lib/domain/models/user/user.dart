import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../utils/enums.dart';
import 'expert/expert.dart';
import 'student/student.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User{
  const User._();
  const factory User({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String university,
    required int networkCount,
    String? bio,
    String? profilePicture,
    required UserRole role,
    Student? student,
    Expert? expert,
    @Default(false) bool areWe
}) = _User;

  String get fullName => '$firstName $lastName';
  bool get isExpert => role == UserRole.EXPERT;

  factory User.fromJson(Map<String,dynamic> json) => _$UserFromJson(json);
}
