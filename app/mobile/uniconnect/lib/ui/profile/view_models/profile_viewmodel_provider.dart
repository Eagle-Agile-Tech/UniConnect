import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/post/post_repository_remote.dart';
import 'package:uniconnect/domain/models/post/post.dart';
import 'package:uniconnect/ui/profile/view_models/user_provider.dart';

final profileViewModelProvider = FutureProvider.family<List<Post>, String>((ref, userId) async {
  final repo = ref.watch(postRemoteProvider);
  final result = await repo.getUserPost(userId);
  return result.fold(
        (data) => data,
        (error, stackTrace) => throw error,
  );
});

// final profileViewModelProvider =
//     AsyncNotifierProvider<ProfileViewModel, List<Post>>(ProfileViewModel.new);
//
// class ProfileViewModel extends AsyncNotifier<List<Post>> {
//   @override
//   FutureOr<List<Post>> build() async {
//     final userId = ref.watch(currentUserProvider)?.id;
//     if (userId == null) return [];
//     final result = await ref.read(postRemoteProvider).getUserPost(userId);
//     return result.fold((posts) => posts, (error, stackTrace) => throw error);
//   }
// }