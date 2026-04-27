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

  Future<Result<List<(Course, String id, String fullName, String username, String? profileImage)>>> getFamousCourses() async {
    final result = await _apiClient.fetchFamousCourses();

    return result.fold((coursesData) {
      final List<(Course, String, String, String, String)> courseRecords =
      (coursesData as List).map((data) {

        final course = Course.fromJson(data);

        final expert = data['expert'];
        final String fullName = '${expert['firstName']} ${expert['lastName']}';
        final String id = expert['id'];
        final String username = expert['userName'];
        final String profileImage = expert['profileImage'];

        return (course, id, fullName, username, profileImage);
      }).toList();

      return Result.ok(courseRecords);
    }, (error, stackTrace) => Result.error(error));
  }
}
