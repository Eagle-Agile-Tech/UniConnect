import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/course/course_repository_remote.dart';

import '../../../domain/models/course/course.dart';
import '../../../utils/result.dart';

final courseProvider = FutureProvider.family<Result<List<Course>>, String>(
  (ref, param) async {
    final courseRepo = ref.read(courseRepoProvider);
    final result = await courseRepo.getCourses(param);
    return result.fold(
      (courses) => Result.ok(courses),
      (error, stackTrace) => Result.error(error),
    );
  },
);

final topCoursesProvider = FutureProvider<Result<List<(Course, String id, String fullName, String username, String? profileImage)>>>(
      (ref) async {
    final courseRepo = ref.read(courseRepoProvider);
    final result = await courseRepo.getFamousCourses();
    return result.fold(
          (courses) => Result.ok(courses),
          (error, stackTrace) => Result.error(error),
    );
  },
);