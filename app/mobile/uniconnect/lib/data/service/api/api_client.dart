import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/result.dart';
import 'routes/api_routes.dart';
import 'token_refresher.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(client: dio);
});

class ApiClient {
  final Dio _client;
  ApiClient({Dio? client})
    :
      _client = client ?? Dio(BaseOptions(baseUrl: baseUrl));

  dynamic _payload(dynamic responseData) {
    if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
      return responseData['data'];
    }
    return responseData;
  }


  Future<Result<List<Map<String, dynamic>>>> fetchUserPost() async {
    try {
      final response = await _client.get('/v1/posts/me');
      final List data = response.data['data'];
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
      final response = await _client.get('/users/profile/$userId');
      final Map<String, dynamic> data = response.data;
      return Result.ok(data);
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result> makeNetwork(String receiverId) async {
    try {
      await _client.post("/network/request", data: {
        "receiverId" : receiverId
      });
      return Result.ok('');
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result> acceptNetwork(String requestId) async {
    try {
      await _client.post("/network/accept", data: {
        "receiverId" : requestId
      });
      return Result.ok('');
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result> rejectNetwork(String requestId) async {
    try {
      await _client.post("/network/reject", data: {
        "requestId" : requestId
      });
      return Result.ok('');
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result> removeNetwork(String receiverId) async {
    try {
      await _client.delete("/network", data: {
        "targetId" : receiverId
      });
      return Result.ok('');
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
      final response = await _client.get('/network');
      final List data = response.data['data'];
      return Result.ok(data.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result> createPost({
    required String content,
    required String userId,
    List<File>? media,
    required DateTime createdAt,
    List<String>? hashtags,
  }) async {
    try {
      final Map<String, dynamic> postData = {
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'tags': jsonEncode(hashtags),
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
        '/v1/posts/',
        data: formData,
      );

      return Result.ok(_payload(response.data));
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> fetchFeed(String userId) async {
    try {
      final response = await _client.get('/v1/posts/feed/$userId');
      final List data = response.data['data'];
      return Result.ok(data.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> fetchPostById(String postId) async {
    try {
      final response = await _client.get('/v1/posts/$postId');
      final payload = _payload(response.data);
      if (payload is Map<String, dynamic>) {
        return Result.ok(payload);
      }
      return Result.error(StateError('Invalid post payload')); 
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> likePost({
    required String postId,
    required String userId,
  }) async {
    //todo: reaction type
    try {
      final response = await _client.post(
        '/v1/posts/likePost/$postId',
        data: {'userId': userId, 'type': 'LIKE'},
      );
      final payload = _payload(response.data);
      if (payload is Map<String, dynamic>) {
        return Result.ok(payload);
      }
      return Result.error(StateError('Invalid like payload'));
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  //todo: handle replies
  Future<Result> commentOnPost({
    required String postId,
    required String comment,
    required DateTime createdAt,
  }) async {
    try {
      await _client.post(
        '/v1/posts/commentPost/$postId',
        data: {
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
      final response = await _client.get('/v1/posts/comments/$postId');
      return Result.ok(_payload(response.data));
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> deletePost(String postId) async {
    try {
      await _client.delete('/v1/posts/$postId');
      return Result.ok(null);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result> updateProfile(String? firstName, String? lastName, String? username, String? bio, File? profilePic) async {
    try {
      final Map<String,dynamic> change = {
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'bio': bio,
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
      await _client.post('/v1/posts/bookmarkPost/:$postId');
      await _client.post('/v1/posts/bookmarkPost/:$postId');
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
      final response = await _client.get('/users/profiles/username/$keyWord');      List data = response.data;
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

  // Events
  Future<Result<List<Map<String, dynamic>>>> fetchEvents(String userId) async {
    try{
      final response = await _client.get('users/event/$userId');
      final List data = response.data;
      return Result.ok(data.cast<Map<String,dynamic>>());
    } on DioException catch(e) {
      return Result.error(e);
    }
  }

  // Chats
Future<Result<Map<String, dynamic>>> getChatId(String receiverId) async {
  try{
    final response = await _client.get('/chats/$receiverId');
    final Map<String,dynamic> data = response.data;
    return Result.ok(data);
  } on DioException catch(e) {
    return Result.error(e);
  }
}
}