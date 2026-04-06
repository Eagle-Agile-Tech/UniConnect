import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/result.dart';
import 'routes/api_routes.dart';
import 'token_refresher.dart';

final apiClientProvider = Provider<ApiClient>((ref) {

  return ApiClient(client: ref.watch(dioProvider));
});

class ApiClient {
  final Dio _client;
  // final String _userId;

  ApiClient({Dio? client})
    :
      _client = client ?? Dio();

  Future<Result<List<Map<String, dynamic>>>> fetchUserPost(
    String userId,
  ) async {
    try {
      //todo: pagination
      final response = await _client.get('/${ApiRoutes.posts}/$userId');
      final List data = response.data;
      return Result.ok(data.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> fetchCurrentUser() async {
    try {
      final response = await _client.get('/users/profile');
      final Map<String, dynamic> data = response.data;
      return Result.ok(data);
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> fetchUser(String userId) async {
    try {
      final response = await _client.get('/getUser/$userId');
      final Map<String, dynamic> data = response.data;
      return Result.ok(data);
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String,dynamic>>>> fetchUserNetworks(String userId) async {
    try{
      final response = await _client.get('/networks/$userId');
      final List data = response.data;
      return Result.ok(data.cast<Map<String,dynamic>>());
    } on DioException catch (e){
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> fetchFriends() async {
    try {
      final response = await _client.get('/getFriends/');
      await Future.delayed(Duration(seconds: 3));
      final List data = response.data;
      return Result.ok(data.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
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
          media.map(
            (file) => MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          ),
        );
      }

      final formData = FormData.fromMap(postData);
      final response = await _client.post(
        ApiRoutes.posts,
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
      final response = await _client.get('/feed/');
      return Result.ok(response.data);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result> likePost(String postId) async {
    //todo: reaction type
    try {
      await _client.post('/likePost/$postId',);
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
      await _client.post(
        '/commentPost/$postId',
        data: {
          'postId': postId,
          'comment': comment,
          'createdAt': createdAt.toIso8601String(),
        },
      );
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

  Future<Result> updateProfile(String? firstName, String? lastName, String? username, String? bio, File? profilePic) async {
    try {
      final Map<String,dynamic> change = {
        'firstName': ?firstName,
        'lastName': ?lastName,
        'username': ?username,
        'bio': ?bio,
      };
      if (profilePic != null){
        final file = MultipartFile.fromFile(
          profilePic.path,
          filename: profilePic.path.split('/').last,
        );
        change['profilePic'] = file;
      }
      final formData = FormData.fromMap(change);
      await _client.post('/updateProfile/', data: formData);
      return Result.ok('');
    } on DioException catch (e){
      return Result.error(e);
    }
  }

  Future<Result> bookmarkPost(String postId) async {
    try {
      await _client.post('/bookmarkPost/$postId');
      return Result.ok(null);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<dynamic>> fetchBookmarks() async {
    try {
      final response = await _client.get('/bookmarks/');
      return Result.ok(response.data);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> searchUsers(String keyWord) async {
    try {
      final response = await _client.get('/searchUsers/$keyWord');
      List data = response.data;
      return Result.ok(data.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> searchPosts(String keyWord) async {
    try {
      final response = await _client.get('/searchPosts/$keyWord');
      List data = response.data;
      return Result.ok(data.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  // Community
  Future<Result<Map<String, dynamic>>> createCommunity({
    required String name,
    required String description,
    required List<String> members,
    File? profileImage,
  }) async {
    try {
      final mapData = {
        'name': name,
        'description': description,
        'members': members,
      };
      if (profileImage != null) {
        mapData['profileImage'] = await MultipartFile.fromFile(
          profileImage.path,
          filename: profileImage.path.split('/').last,
        );
      }
      final formData = FormData.fromMap(mapData);
      final response = await _client.post(
        '/createCommunity',
        data: formData,
      );
      // The response is expected to include id.
      return Result.ok(response.data);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> fetchCommunity(String id) async {
    try {
      final response = await _client.get('/getCommunity/$id');
      return Result.ok(response.data.cast<String,dynamic>());
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> fetchCommunityPosts(
      String communityId,
      ) async {
    try {
      final response = await _client.get('/communityPosts/$communityId');
      final List data = response.data;
      return Result.ok(data.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String,dynamic>>>> fetchCommunityMembers(
      String communityId,
      ) async {
    try {
      final response = await _client.get('/communityMembers/$communityId');
      final List data = response.data;
      return Result.ok(data.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String,dynamic>>>> fetchTopCommunities(
      ) async {
    try {
      final response = await _client.get('/topCommunities');
      final List data = response.data;
      return Result.ok(data.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  // Course
  Future<Result<List<Map<String,dynamic>>>> fetchCourses(String id) async {
    try{
      final response = await _client.get('/courses/$id');
      final data = response.data as List;
      return Result.ok(data.cast<Map<String, dynamic>>());
    } on DioException catch(e){
      return Result.error(e);
    }
  }
}
