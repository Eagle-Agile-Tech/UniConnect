import 'package:freezed_annotation/freezed_annotation.dart';

part 'course.freezed.dart';
part 'course.g.dart';

@freezed
abstract class Course with _$Course{
  const factory Course({
    required String id,
    required String title,
    @Default('https://repository.ju.edu.et/') String link,
    required String description,
    required int enrolled,
    required int price,
}) = _Course;

  factory Course.fromJson(Map<String,dynamic> json) => _$CourseFromJson(json);
}