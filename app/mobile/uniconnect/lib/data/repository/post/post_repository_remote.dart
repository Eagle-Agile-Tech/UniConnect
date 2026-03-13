import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/post/post_repository.dart';
import 'package:uniconnect/domain/models/comment/comment.dart';
import 'package:uniconnect/domain/models/post/post.dart';
import 'package:uniconnect/utils/result.dart';

import '../../service/api/api_client.dart';

final postRemoteProvider = Provider<PostRepositoryRemote>(
  (ref) => PostRepositoryRemote(apiClient: ref.watch(apiClientProvider)),
);

class PostRepositoryRemote implements PostRepository {
  const PostRepositoryRemote({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Result<List<Post>>> getUserPost(String id) async {
    final result = await _apiClient.fetchUserPost(id);
    return result.fold((data) {
      final posts = data.map((post) => Post.fromJson(post)).toList();
      return Result.ok(posts);
    }, (error, stackTrace) => Result.error(error));
  }

  @override
  Future<Result> createPost({
    required String content,
    required List<File>? mediaUrls,
    required DateTime createdAt,
    List<String>? hashtags,
  }) async {
    final result = await _apiClient.createPost(
      content: content,
      media: mediaUrls,
      createdAt: createdAt,
      hashtags: hashtags,
    );
    return result.fold(
      (data) => Result.ok(null),
      (error, stackTrace) => Result.error(error),
    );
  }

  @override
  Future<Result<List<Post>>> getFeed(String userId) async {
    final result = await _apiClient.fetchFeed();
    return result.fold((data) {
      final posts = (data as List)
          .map((post) => Post.fromJson(post as Map<String, dynamic>))
          .toList();
      return Result.ok(posts);
    }, (error, stackTrace) => Result.error(error));
  }

  @override
  Future<Result> commentOnPost({
    required String postId,
    required String comment,
    required DateTime createdAt,
    required String authorId,
  }) async {
    final result = await _apiClient.commentOnPost(
      postId: postId,
      comment: comment,
      createdAt: createdAt,
    );
    return result.fold(
      (data) => Result.ok(null),
      (error, stackTrace) => Result.error(error),
    );
  }

  @override
  Future<Result> likePost({required String postId}) async {
    final result = await _apiClient.likePost(postId);
    return result.fold(
      (data) => Result.ok(null),
      (error, stackTrace) => Result.error(error),
    );
  }

  @override
  Future<Result<List<Comment>>> getComments(String postId) async {
    final result = await _apiClient.fetchComments(postId);
    return result.fold((data) {
      final comments = (data as List)
          .map((comment) => Comment.fromJson(comment))
          .toList();
      return Result.ok(comments);
    }, (error, _) => Result.error(error));
  }

  @override
  Future<Result> bookmarkPost({required String postId}) async {
    final result = await _apiClient.bookmarkPost(postId);
    return result.fold(
      (data) => Result.ok(null),
      (error, stackTrace) => Result.error(error),
    );
  }

  @override
  Future<Result<List<Post>>> getBookmarks(String userId) async {
    final result = await _apiClient.fetchBookmarks();
    return result.fold((data) {
      final posts = (data as List).map((post) => Post.fromJson(post)).toList();
      return Result.ok(posts);
    }, (error, stackTrace) => Result.error(error, stackTrace));
  }

  @override
  Future<Result<List<Post>>> searchPosts(String keyWord) async {
    final result = await _apiClient.searchPosts(keyWord);
    return result.fold((data) {
      final posts = data.map((user) => Post.fromJson(user)).toList();
      return Result.ok(posts);
    }, (error, _) => Result.error(error));
  }
}
