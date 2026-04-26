import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/post/post_repository.dart';
import 'package:uniconnect/domain/models/comment/comment.dart';
import 'package:uniconnect/domain/models/post/post.dart';
import 'package:uniconnect/utils/enums.dart';
import 'package:uniconnect/utils/result.dart';

import '../../service/api/api_client.dart';

final postRemoteProvider = Provider<PostRepositoryRemote>(
  (ref) => PostRepositoryRemote(apiClient: ref.watch(apiClientProvider)),
);

class PostRepositoryRemote implements PostRepository {
  const PostRepositoryRemote({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  // List<Map<String, dynamic>> _asMapList(dynamic value) {
  //   if (value is List) {
  //     return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  //   }
  //   if (value is Map<String, dynamic> && value['data'] is List) {
  //     final data = value['data'] as List;
  //     return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  //   }
  //   return const [];
  // }
  //
  // String _authorNameFrom(Map<String, dynamic> json) {
  //   final direct = json['authorName'];
  //   if (direct is String && direct.isNotEmpty) return direct;
  //
  //   final author = json['author'];
  //   if (author is Map) {
  //     final username = author['username'];
  //     if (username is String && username.isNotEmpty) return username;
  //
  //     final firstName = author['firstName']?.toString() ?? '';
  //     final lastName = author['lastName']?.toString() ?? '';
  //     final fullName = '$firstName $lastName'.trim();
  //     if (fullName.isNotEmpty) return fullName;
  //   }
  //   return 'Unknown user';
  // }
  //
  // String? _authorPhotoFrom(Map<String, dynamic> json) {
  //   final direct = json['authorProfilePicture'];
  //   if (direct is String && direct.isNotEmpty) return direct;
  //
  //   final author = json['author'];
  //   if (author is Map) {
  //     final profileImage = author['profileImage'];
  //     if (profileImage is String && profileImage.isNotEmpty) return profileImage;
  //   }
  //   return null;
  // }
  //
  // List<String>? _mediaUrlsFrom(Map<String, dynamic> json) {
  //   final mediaUrls = json['mediaUrls'];
  //   if (mediaUrls is List) {
  //     final urls = mediaUrls.whereType<String>().toList();
  //     return urls.isEmpty ? null : urls;
  //   }
  //
  //   final media = json['media'];
  //   if (media is List) {
  //     final urls = media
  //         .whereType<Map>()
  //         .map((item) {
  //           final mapped = Map<String, dynamic>.from(item);
  //           return mapped['url'] ?? mapped['mediaUrl'] ?? mapped['secureUrl'] ?? mapped['fileUrl'];
  //         })
  //         .whereType<String>()
  //         .toList();
  //     return urls.isEmpty ? null : urls;
  //   }
  //   return null;
  // }
  //
  // Post _mapPost(Map<String, dynamic> json) {
  //   final author = json['author'];
  //   final authorId = json['authorId']?.toString() ??
  //       (author is Map ? (author['id']?.toString() ?? '') : '');
  //
  //   final likeCountValue = json['likeCount'] ?? json['reactionCount'] ?? 0;
  //   final commentCountValue = json['commentCount'] ?? 0;
  //
  //   return Post(
  //     id: json['id'].toString(),
  //     content: (json['content'] ?? '').toString(),
  //     authorId: authorId,
  //     authorProfilePicture: _authorPhotoFrom(json),
  //     authorName: _authorNameFrom(json),
  //     mediaUrls: _mediaUrlsFrom(json),
  //     createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
  //     tags: (json['tags'] as List?)?.whereType<String>().toList() ??
  //         (json['hashtags'] as List?)?.whereType<String>().toList(),
  //     likeCount: (likeCountValue as num).toInt(),
  //     commentCount: (commentCountValue as num).toInt(),
  //     isLikedByMe: (json['isLikedByMe'] as bool?) ??
  //         (json['userReacted'] as bool?) ??
  //         ((json['userReaction']?.toString().isNotEmpty ?? false)),
  //     isBookmarkedByMe: (json['isBookmarkedByMe'] as bool?) ??
  //         (json['userBookmarked'] as bool?) ??
  //         false,
  //   );
  // }
  //
  // Comment _mapComment(Map<String, dynamic> json) {
  //   final commenter = json['commenter'];
  //   final commenterMap = commenter is Map ? Map<String, dynamic>.from(commenter) : const <String, dynamic>{};
  //   final commenterProfile = commenterMap['profile'];
  //   final commenterProfileMap = commenterProfile is Map
  //       ? Map<String, dynamic>.from(commenterProfile)
  //       : const <String, dynamic>{};
  //
  //   final firstName = commenterMap['firstName']?.toString() ?? '';
  //   final lastName = commenterMap['lastName']?.toString() ?? '';
  //   final fallbackAuthorName = '$firstName $lastName'.trim();
  //
  //   return Comment(
  //     id: (json['id'] ?? '').toString(),
  //     postId: (json['postId'] ?? '').toString(),
  //     content: (json['content'] ?? '').toString(),
  //     authorId: (json['authorId'] ?? json['commenterId'] ?? json['userId'] ?? '').toString(),
  //     authorName: (json['authorName'] ?? fallbackAuthorName).toString().isEmpty
  //         ? 'Unknown user'
  //         : (json['authorName'] ?? fallbackAuthorName).toString(),
  //     authorProfilePicUrl:
  //         (json['authorProfilePicUrl'] ?? commenterMap['profileImage'] ?? commenterProfileMap['profileImage'])
  //             ?.toString(),
  //     createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
  //     likeCount: ((json['likeCount'] ?? json['reactionCount'] ?? 0) as num).toInt(),
  //   );
  // }

  @override
  Future<Result<List<Post>>> getUserPost() async {
    final result = await _apiClient.fetchUserPost();
    return result.fold((data) {
      final posts = data.map((post) => Post.fromJson(post)).toList();
      return Result.ok(posts);
    }, (error, stackTrace) => Result.error(error));
  }

  @override
  Future<Result<List<Post>>> getOtherUserPost(String userId) async {
    final result = await _apiClient.fetchOtherUserPost(userId);

    return result.fold((data) {
      final posts = data.map((post) => Post.fromJson(post)).toList();
      return Result.ok(posts);
    }, (error, stackTrace) => Result.error(error));
  }

  @override
  Future<Result> createPost({
    required String content,
    required String userId,
    required List<File>? mediaUrls,
    required DateTime createdAt,
    List<String>? hashtags,
  }) async {
    final result = await _apiClient.createPost(
      content: content,
      userId: userId,
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
    final result = await _apiClient.fetchFeed(userId);
    return result.fold((data) {
      final posts = data.map((post) => Post.fromJson(post)).toList();
      return Result.ok(posts);
    }, (error, stackTrace) => Result.error(error));
  }

  @override
  Future<Result<Post>> getPostById(String postId) async {
    final result = await _apiClient.fetchPostById(postId);
    return result.fold((data) {
      final post = Post.fromJson(data);
      return Result.ok(post);
    }, (error, stackTrace) => Result.error(error, stackTrace));
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
  Future<Result> likePost({
    required String postId,
    required String userId,
  }) async {
    final result = await _apiClient.likePost(postId: postId, userId: userId);
    return result.fold(
      (data) => Result.ok(data),
      (error, stackTrace) => Result.error(error),
    );
  }

  @override
  Future<Result<List<Comment>>> getComments(String postId) async {
    final result = await _apiClient.fetchComments(postId);
    return result.fold((data) {
      final comments = data
          .map((comment) => Comment.fromJson(comment))
          .toList();
      return Result.ok(comments);
    }, (error, _) => Result.error(error));
  }

  @override
  Future<Result<void>> deletePost({required String postId}) async {
    final result = await _apiClient.deletePost(postId);
    return result.fold(
      (data) => Result.ok(null),
      (error, stackTrace) => Result.error(error, stackTrace),
    );
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
    final result = await _apiClient.fetchBookmarks(userId);
    return result.fold((data) {
      final posts = (data as List).map((post) => Post.fromJson(post)).toList();
      return Result.ok(posts);
    }, (error, stackTrace) => Result.error(error, stackTrace));
  }

  @override
  Future<Result<List<Post>>> searchPosts(String keyWord) async {
    final result = await _apiClient.searchPosts(keyWord);
    return result.fold((data) {
      final posts = data.map((data) => Post.fromJson(data)).toList();
      return Result.ok(posts);
    }, (error, _) => Result.error(error));
  }

  @override
  Future<Result<List<Post>>> getCommunityPost(String id) async {
    final result = await _apiClient.fetchCommunityPosts(id);
    return result.fold((data) {
      final posts = data.map((post) => Post.fromJson(post)).toList();
      return Result.ok(posts);
    }, (error, stackTrace) => Result.error(error));
  }

  @override
  Future<Result<void>> reportPost({
    required String postId,
    required ReportReason reason,
    String? message,
  }) async {
    final result = await _apiClient.reportContent(
      targetType: ReportTargetType.POST,
      targetId: postId,
      reason: reason,
      message: message,
    );

    return result.fold(
      (_) => Result.ok(null),
      (error, stackTrace) => Result.error(error, stackTrace),
    );
  }
}
