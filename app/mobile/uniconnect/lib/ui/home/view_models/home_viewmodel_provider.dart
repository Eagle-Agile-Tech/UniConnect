import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/post/post_repository.dart';
import 'package:uniconnect/domain/models/post/post.dart';

import '../../../data/repository/post/post_repository_remote.dart';
import '../../auth/auth_state_provider.dart';

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
    final authAsync = ref.read(authNotifierProvider);

    return authAsync.when(
      data: (auth) async {
        final currentUser = auth.user;

        if (currentUser == null) {
          throw Exception('User is not authenticated');
        }

        final result = await _postRepo.getFeed(currentUser.id);

        return result.fold(
              (posts) => posts,
              (error, stackTrace) => Error.throwWithStackTrace(
            error,
            stackTrace ?? StackTrace.current,
          ),
        );
      },
      loading: () => throw Exception('Auth state still loading'),
      error: (err, stack) => Error.throwWithStackTrace(err, stack),
    );
  }

  Future<void> toggleLike({required String postId}) async {
    final auth = ref.read(authNotifierProvider).value;
    final currentUserId = auth?.user?.id;
    if (currentUserId == null) return;

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
    final result = await _postRepo.likePost(postId: postId, userId: currentUserId);
    result.fold((success) => null, (error, _) {
      // todo: notify user of the error
      state = AsyncValue.data(previous);
    });
  }

  Future<void> refreshFeed() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchPosts);
  }

  Future<void> removePost(String postId) async {
    final previous = state.value;
    if (previous == null) return;

    state = AsyncValue.data(previous.where((post) => post.id != postId).toList());
    final result = await _postRepo.deletePost(postId: postId);
    result.fold(
      (_) => null,
      (error, _) => state = AsyncValue.data(previous),
    );
  }

  Future<void> addPostToFeed(Post post) async {
    final previous = state.value ?? const <Post>[];
    state = AsyncValue.data([post, ...previous]);
  }

  Future<Post?> fetchSinglePost(String postId) async {
    final result = await _postRepo.getPostById(postId);
    return result.fold((post) => post, (_, __) => null);
  }

  Future<void> bookmarkPost({required String postId}) async {
    final previous = state.value;
    if (previous == null) return;
    final bookmarkedPost = previous.map((post) {
      if (post.id == postId) {
        final isBookmarked = post.isBookmarkedByMe;
        return post.copyWith(isBookmarkedByMe: !isBookmarked);
      }
      return post;
    }).toList();
    state = AsyncValue.data(bookmarkedPost);
    final result = await _postRepo.bookmarkPost(postId: postId);

    return result.fold((data) => null, (error, _) {
      state = AsyncValue.data(previous);
      AsyncValue.error(error, StackTrace.current);
    });
  }
}
