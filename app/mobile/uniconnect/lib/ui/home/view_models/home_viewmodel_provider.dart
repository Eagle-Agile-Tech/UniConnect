import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/post/post_repository.dart';
import 'package:uniconnect/domain/models/post/post.dart';
import 'package:uniconnect/ui/profile/view_models/user_provider.dart';

import '../../../data/repository/post/post_repository_remote.dart';

final homeViewModelProvider =
AsyncNotifierProvider<HomeViewmodelProvider, List<Post>>(
  HomeViewmodelProvider.new,
);

class HomeViewmodelProvider extends AsyncNotifier<List<Post>> {
  late PostRepository _postRepo;

  @override
  FutureOr<List<Post>> build() {
    _postRepo = ref.watch(postRemoteProvider);
    return _fetchPosts();
  }

  Future<List<Post>> _fetchPosts() async {
    state = const AsyncValue.loading();
    final result = await _postRepo.getFeed(ref.read(userProvider)!.id);
    return result.fold(
          (data) => data,
          (error, stackTrace) =>
          Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current),
    );
  }

  Future<void> toggleLike({required String postId}) async {
    final previous = state.value;
    if (previous == null) return;
    final updatedPost = previous.map((post) {
      if (post.id == postId) {
        final isLiked = post.isLikedByMe;
        return post.copyWith(
          isLikedByMe: !isLiked,
          likeCount: isLiked ? post.likeCount - 1 : post.likeCount + 1,
        );
      }
      return post;
    }).toList();

    state = AsyncValue.data(updatedPost);
    final result = await _postRepo.likePost(
      postId: postId,
      userId: ref.read(userProvider)!.id,
    );
    result.fold((success) => null, (error, _) {
      // todo: notify user of the error
      state = AsyncValue.data(previous);
    });
  }

  Future<void> bookmarkPost({required String postId}) async {
    final previous = state.value;
    if (previous == null) return;
    final bookmarkedPost = previous.map((post) {
      if (post.id == postId) {
        final isBookmarked = post.isBookmarkedByMe;
        return post.copyWith(
          isBookmarkedByMe: !isBookmarked,
        );
      }
      return post;
    }).toList();
    state = AsyncValue.data(bookmarkedPost);
    final result = await _postRepo.bookmarkPost(
        postId: postId, userId: ref.read(userProvider)!.id);

    return result.fold((data) => null, (error, _) {
      state = AsyncValue.data(previous);
      AsyncValue.error(error, StackTrace.current);
    });
  }
}
