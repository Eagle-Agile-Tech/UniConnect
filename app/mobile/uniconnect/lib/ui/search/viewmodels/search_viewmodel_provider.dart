import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repository/post/post_repository.dart';
import '../../../data/repository/post/post_repository_remote.dart';
import '../../../data/repository/user/user_repository.dart';
import '../../../data/repository/user/user_repository_remote.dart';
import '../../../domain/models/post/post.dart';
import '../../../domain/models/user/user.dart';

final userSearchProvider =
    AsyncNotifierProvider<SearchUserViewModel, List<User>>(
      SearchUserViewModel.new,
    );

class SearchUserViewModel extends AsyncNotifier<List<User>> {
  late UserRepository _userRepo;

  @override
  FutureOr<List<User>> build() {
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

final postSearchProvider = AsyncNotifierProvider<PostUserViewModel, List<Post>>(
  PostUserViewModel.new,
);

class PostUserViewModel extends AsyncNotifier<List<Post>> {
  late PostRepository _postRepo;

  @override
  FutureOr<List<Post>> build() {
    _postRepo = ref.watch(postRemoteProvider);
    return [];
  }

  Future<void> searchPost(String keyWord) async {
    state = const AsyncValue.loading();

    final result = await _postRepo.searchPosts(keyWord);

    state = result.fold(
      (data) => AsyncValue.data(data),
      (error, _) => AsyncValue.error(error, StackTrace.current),
    );
  }
}
