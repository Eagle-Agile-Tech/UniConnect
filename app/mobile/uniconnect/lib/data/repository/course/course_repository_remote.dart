import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/service/api/api_client.dart';
import 'package:uniconnect/domain/models/course/course.dart';
import 'package:uniconnect/utils/result.dart';
import 'course_repository.dart';

final courseRepoProvider = Provider<CourseRepositoryRemote>((ref) {
  final api = ref.read(apiClientProvider);
  return CourseRepositoryRemote(api);
});

class CourseRepositoryRemote extends CourseRepository {
  CourseRepositoryRemote(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Result<List<Course>>> getCourses(String userId) async {
    final result = await _apiClient.fetchCourses(userId);
    return result.fold((coursesData) {
      final courses = coursesData
          .map((course) => Course.fromJson(course))
          .toList();
      return Result.ok(courses);
    }, (error, stackTrace) => Result.error(error));
  }
}
