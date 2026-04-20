import '../../../domain/models/course/course.dart';
import '../../../utils/result.dart';

abstract class CourseRepository{
  Future<Result<List<Course>>> getCourses(String userId);
}