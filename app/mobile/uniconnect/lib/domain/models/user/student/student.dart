import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../utils/enums.dart';

part 'student.freezed.dart';
part 'student.g.dart';

@freezed
abstract class Student with _$Student {
  const factory Student({
    required String department,
    required String currentYear,
    required DateTime expectedGraduationYear,
    List<String>? interests,
    @Default(VerificationStatus.PENDING) VerificationStatus verificationStatus,
  }) = _Student;

  factory Student.fromJson(Map<String, dynamic> json) =>
      _$StudentFromJson(json);
}