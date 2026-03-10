import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/profile/view_models/user_provider.dart';
import '../../../utils/result.dart';
import 'routes/api_routes.dart';
import 'token_refresher.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final user = ref.watch(userProvider);

  if (user == null) {
    throw Exception('User not logged in');
  }

  return ApiClient(client: ref.watch(dioProvider), userId: user.id);
});

class ApiClient {
  final Dio _client;
  final String _userId;

  ApiClient({Dio? client, required String userId})
      : _userId = userId,
        _client = client ?? Dio();


  Future<Result<List<Map<String,dynamic>>>> fetchUserPost() async {
    try {
      //todo: pagination
      final response = await _client.get('${ApiRoutes.posts}/$_userId');
      return Result.ok(response.data);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result> createPost({
    required String content,
    List<File>? media,
    required DateTime createdAt,
    List<String>? hashtags,
  }) async {
    try {
      final Map<String, dynamic> postData = {
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'hashtags': ?hashtags,
      };

      if (media != null && media.isNotEmpty) {
        postData['media'] = await Future.wait(
          media.map((file) => MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          )),
        );
      }

      final formData = FormData.fromMap(postData);
      final response = await _client.post(
        '${ApiRoutes.posts}/$_userId',
        data: formData,
      );

      return Result.ok(response.data);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<dynamic>> fetchFeed() async {
    try {
      //todo: pagination
      final response = await _client.get('/feed/$_userId');
      return Result.ok(response.data);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result> likePost(String postId) async {
    //todo: reaction type
    try {
      await _client.post('/likePost/$postId', data: {'userId': _userId});
      return Result.ok(null);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result> commentOnPost({
    required String postId,
    required String comment,
    required DateTime createdAt,
  }) async {
    try {
      await _client.post('/commentPost/$postId', data: {
        'postId': postId,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
        'authorId': _userId,
      });
      return Result.ok(null);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<dynamic>> fetchComments(String postId) async {
    try {
      final response = await _client.get('/comments/$postId');
      return Result.ok(response.data);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result> bookmarkPost(String postId) async {
    try {
      await _client.post('/bookmarkPost/$postId', data: {'userId': _userId});
      return Result.ok(null);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<dynamic>> fetchBookmarks() async {
    try {
      final response = await _client.get('/bookmarks/$_userId');
      return Result.ok(response.data);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }
}