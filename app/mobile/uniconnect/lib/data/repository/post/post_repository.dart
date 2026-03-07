import 'dart:io';

import '../../../domain/models/comment/comment.dart';
import '../../../domain/models/post/post.dart';
import '../../../utils/result.dart';

abstract class PostRepository {
  Future<Result<List<Post>>> getUserPost(String id);
  Future<Result> createPost({
    required String content,
    required List<File>? mediaUrls,
    required String userId,
    required DateTime createdAt,
    List<String>? hashtags,
  });

  Future<Result<List<Post>>> getFeed(String userId);
  Future<Result> likePost({
    required String postId,
    required String userId,
  });
  Future<Result> commentOnPost({
    required String postId,
    required String comment,
    required DateTime createdAt,
    required String authorId
  });
  Future<Result<List<Comment>>> getComments(String postId);
}