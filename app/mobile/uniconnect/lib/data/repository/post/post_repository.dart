import 'dart:io';

import '../../../domain/models/comment/comment.dart';
import '../../../domain/models/post/post.dart';
import '../../../utils/enums.dart';
import '../../../utils/result.dart';

abstract class PostRepository {
  Future<Result<List<Post>>> getUserPost();
  Future<Result<List<Post>>> getOtherUserPost(String userId);
  Future<Result> createPost({
    required String content,
    required String userId,
    required List<File>? mediaUrls,
    required DateTime createdAt,
    List<String>? hashtags,
  });

  Future<Result<List<Post>>> getFeed(String userId);
  Future<Result<Post>> getPostById(String postId);
  Future<Result> likePost({required String postId, required String userId});
  Future<Result> commentOnPost({
    required String postId,
    required String comment,
    required DateTime createdAt,
    required String authorId,
  });
  Future<Result<List<Comment>>> getComments(String postId);
  Future<Result> bookmarkPost({required String postId});
  Future<Result<void>> deletePost({required String postId});

  Future<Result<List<Post>>> getBookmarks(String userId);
  Future<Result<List<Post>>> searchPosts(String keyWord);

  Future<Result<List<Post>>> getCommunityPost(String id);
  Future<Result<void>> reportPost({
    required String postId,
    required ReportReason reason,
    String? message,
  });
}
