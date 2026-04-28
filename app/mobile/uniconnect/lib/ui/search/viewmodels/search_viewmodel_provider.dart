import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repository/post/post_repository.dart';
import '../../../data/repository/post/post_repository_remote.dart';
import '../../../data/repository/user/user_repository.dart';
import '../../../data/repository/user/user_repository_remote.dart';
import '../../../domain/models/post/post.dart';
import '../../../domain/models/user/user.dart';

final userSearchProvider =
    AsyncNotifierProvider<SearchUserViewModel, List<(String id, String username, String? profileImage, String fullName)>>(
      SearchUserViewModel.new,
    );

class SearchUserViewModel extends AsyncNotifier<List<(String id, String username, String? profileImage, String fullName)>> {
  late UserRepository _userRepo;

  @override
  FutureOr<List<(String id, String username, String profileImage, String fullName)>> build() {
    _userRepo = ref.watch(userRepoProvider);
    return [];
  }

  Future<void> searchUser(String keyWord) async {
    state = const AsyncValue.loading();

    final result = await _userRepo.searchUsers(keyWord);

    state = result.fold(
      (data) => AsyncValue.data(data),
      (error, _) => AsyncValue.error(error, StackTrace.current),
    );
  }
}

final postSearchProvider =
AsyncNotifierProvider<PostSearchViewModel, List<Post>>(
  PostSearchViewModel.new,
);

class PostSearchViewModel extends AsyncNotifier<List<Post>> {
  late PostRepository _postRepo;

  @override
  FutureOr<List<Post>> build() {
    _postRepo = ref.watch(postRemoteProvider);
    return [];
  }

  Future<void> searchPost(String keyWord) async {
    if (keyWord.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    final result = await _postRepo.searchPosts(keyWord);

    state = result.fold(
          (posts) => AsyncValue.data(posts),
          (error, stackTrace) =>
          AsyncValue.error(error, stackTrace ?? StackTrace.current),
    );
  }
}
