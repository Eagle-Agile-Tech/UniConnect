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
    String? bio,
    String? profilePicture,
    required UserRole role,
    Student? student,
    Expert? expert,
}) = _User;

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String,dynamic> json) => _$UserFromJson(json);
}
