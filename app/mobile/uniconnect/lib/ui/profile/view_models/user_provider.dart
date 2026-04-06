import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uniconnect/domain/models/user/user.dart';

import '../../../data/repository/user/user_repository_remote.dart';

final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  final repo = ref.watch(userRepoProvider);
  final result = await repo.getUser(userId);
  return result.fold(
    (data) => data,
    (error, stackTrace) => throw error,
  );
});

final selectedChatUserProvider = StateProvider<User?>((ref) => null);

final selectedUserProfileProvider = StateProvider<User?>((ref) => null);