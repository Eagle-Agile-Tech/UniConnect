import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uniconnect/domain/models/user/user.dart';

import '../../../data/repository/user/user_repository_remote.dart';

//final currentUserProvider = StateProvider<User?>((ref) => null);

// This is for test
final currentUserProvider = StateProvider<User?>(
  (ref) => User(
    id: '123',
    firstName: 'Feysel',
    lastName: 'Teshome',
    username: 'feisel',
    email: 'feyselteshome05@gmail.com',
    university: 'Jimma University',
    degree: 'Software Engineering',
    currentYear: '4',
    expectedGraduationYear: DateTime(2026, 6, 1),
    bio: 'Grind || Blind || Leave the world Behind',
    interests: ['Flutter', 'Dart', 'Mobile Development'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    profilePicture: 'https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d'

  ),
);

final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  final repo = ref.watch(userRepoProvider);
  final result = await repo.getUser(userId);
  return result.fold(
    (data) => data,
    (error, stackTrace) => throw error,
  );
});
