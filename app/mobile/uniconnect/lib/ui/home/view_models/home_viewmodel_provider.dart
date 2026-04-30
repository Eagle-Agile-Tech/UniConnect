import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/post/post_repository.dart';
import 'package:uniconnect/domain/models/post/post.dart';

import '../../../data/repository/post/post_repository_remote.dart';
import '../../auth/auth_state_provider.dart';

final homeViewModelProvider =
    AsyncNotifierProvider.family<HomeViewmodelProvider, List<Post>, String>(
      HomeViewmodelProvider.new,
    );

class HomeViewmodelProvider extends AsyncNotifier<List<Post>> {
  late PostRepository _postRepo;
  final String userId;

  HomeViewmodelProvider(this.userId);

  @override
  FutureOr<List<Post>> build() {
    _postRepo = ref.watch(postRemoteProvider);
    return _fetchPosts();
  }

  Future<List<Post>> _fetchPosts() async {
    final result = await _postRepo.getOtherUserPost(userId);

    return result.fold(
          (posts) => posts,
          (error, stackTrace) => Error.throwWithStackTrace(
        error,
        stackTrace ?? StackTrace.current,
      ),
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
    final result = await _postRepo.likePost(postId: postId, userId: userId);
    result.fold((success) => null, (error, _) {
      // todo: notify user of the error
      state = AsyncValue.data(state.value!);
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


final feedProvider =
AsyncNotifierProvider<FeedProvider, List<Post>>(
  FeedProvider.new,
);

class FeedProvider extends AsyncNotifier<List<Post>> {
  late PostRepository _postRepo;
  late String userId;
  @override
  FutureOr<List<Post>> build() {
    _postRepo = ref.watch(postRemoteProvider);
     userId = ref
        .read(authNotifierProvider)
        .value!
        .user!
        .id;
    return _fetchPosts();
  }

  Future<List<Post>> _fetchPosts() async {
    final result = await _postRepo.getFeed(ref
        .read(authNotifierProvider)
        .value!
        .user!
        .id);

    return result.fold(
          (posts) => posts,
          (error, stackTrace) =>
          Error.throwWithStackTrace(
            error,
            stackTrace ?? StackTrace.current,
          ),
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
    final result = await _postRepo.likePost(postId: postId, userId: userId);
    result.fold((success) => null, (error, _) {
      state = AsyncValue.data(state.value!);
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