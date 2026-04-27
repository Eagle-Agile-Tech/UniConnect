import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/enums.dart';
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
    : _client = client ?? Dio(BaseOptions(baseUrl: baseUrl));

  dynamic _payload(dynamic responseData) {
    if (responseData is Map<String, dynamic> &&
        responseData.containsKey('data')) {
      return responseData['data'];
    }
    return responseData;
  }

  List<dynamic>? _extractListPayload(dynamic payload) {
    if (payload is List) {
      return payload;
    }
    if (payload is Map<String, dynamic>) {
      const listKeys = ['events', 'items', 'results', 'data'];
      for (final key in listKeys) {
        final value = payload[key];
        if (value is List) {
          return value;
        }
      }
    }
    return null;
  }

  Future<Result<List<Map<String, dynamic>>>> fetchUserPost() async {
    try {
      final response = await _client.get('/v1/posts/me');
      final List data = response.data;
      return Result.ok(data.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> fetchOtherUserPost(
    String userId,
  ) async {
    try {
      final response = await _client.get('/v1/posts/user/$userId');
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
      await _client.post("/network/request", data: {"receiverId": receiverId});
      return Result.ok('');
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result> acceptNetwork(String requestId) async {
    try {
      await _client.post("/network/accept", data: {"requestId": requestId});
      return Result.ok('');
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result> cancelNetwork(String receiverId) async {
    try {
      await _client.post(
        "/network/cancel",
        data: {"receiverId": "{$receiverId}"},
      );
      return Result.ok('');
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result> rejectNetwork(String requestId) async {
    try {
      await _client.post("/network/reject", data: {"requestId": requestId});
      return Result.ok('');
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result> removeNetwork(String receiverId) async {
    try {
      await _client.delete("/network", data: {"targetId": receiverId});
      return Result.ok('');
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> incomingRequests() async {
    try {
      final response = await _client.get("/network/incoming");
      final List data = response.data['data'];
      return Result.ok(data.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> fetchUserNetworks(
    String userId,
  ) async {
    try {
      final response = await _client.get('/network/$userId');
      final List data = response.data['data'];
      return Result.ok(data.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
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
      await _client.post('/v1/posts/', data: formData);

      return Result.ok('');
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

  Future<Result<Map<String, dynamic>>> commentOnPost({
    required String postId,
    required String comment,
    required DateTime createdAt,
    String? parentCommentId,
  }) async {
    try {
      final response = await _client.post(
        '/v1/posts/commentPost/$postId',
        data: {
          'comment': comment,
          'createdAt': createdAt.toIso8601String(),
          if (parentCommentId != null) 'parentCommentId': parentCommentId,
        },
      );

      final payload = _payload(response.data);
      if (payload is Map<String, dynamic>) {
        return Result.ok(payload);
      }

      return Result.error(StateError('Invalid comment payload'));
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> fetchPaginatedComments({
    required String postId,
    String? cursor,
    int limit = 10,
  }) async {
    try {
      final response = await _client.get(
        '/v1/posts/comments/$postId/paginated',
        queryParameters: {'limit': limit, if (cursor != null) 'cursor': cursor},
      );

      if (response.data is Map<String, dynamic>) {
        return Result.ok(Map<String, dynamic>.from(response.data as Map));
      }

      return Result.error(StateError('Invalid paginated comments payload'));
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> fetchCommentReplies({
    required String commentId,
    String? cursor,
    int limit = 5,
  }) async {
    try {
      final response = await _client.get(
        '/v1/posts/comments/$commentId/replies',
        queryParameters: {'limit': limit, if (cursor != null) 'cursor': cursor},
      );

      if (response.data is Map<String, dynamic>) {
        return Result.ok(Map<String, dynamic>.from(response.data as Map));
      }

      return Result.error(StateError('Invalid comment replies payload'));
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> toggleCommentReaction({
    required String commentId,
    String type = 'LIKE',
  }) async {
    try {
      final response = await _client.post(
        '/v1/posts/comments/$commentId/reactions',
        data: {'type': type},
      );
      final payload = _payload(response.data);
      if (payload is Map<String, dynamic>) {
        return Result.ok(payload);
      }

      return Result.error(StateError('Invalid comment reaction payload'));
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

  Future<Result> updateProfile(
    String? firstName,
    String? lastName,
    String? username,
    String? bio,
    File? profilePic,
  ) async {
    try {
      final Map<String, dynamic> change = {
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'bio': bio,
      };
      if (profilePic != null) {
        final file = MultipartFile.fromFile(
          profilePic.path,
          filename: profilePic.path.split('/').last,
        );
        change['profilePic'] = file;
      }
      final formData = FormData.fromMap(change);
      await _client.post('/updateProfile/', data: formData);
      return Result.ok('');
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result> bookmarkPost(String postId) async {
    try {
      await _client.post('/v1/posts/bookmarkPost/$postId');
      return Result.ok(null);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> fetchBookmarks(
    String userId,
  ) async {
    try {
      final response = await _client.get('/v1/posts/bookmarks/$userId');
      final List data = response.data;
      return Result.ok(data.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> reportContent({
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String? message,
  }) async {
    try {
      final payload = <String, dynamic>{
        'targetType': targetType.name,
        'targetId': targetId,
        'reason': reason.name,
      };

      final trimmedMessage = message?.trim();
      if (trimmedMessage != null && trimmedMessage.isNotEmpty) {
        payload['message'] = trimmedMessage;
      }

      final response = await _client.post('/reports', data: payload);
      final responseData = _payload(response.data);
      if (responseData is Map<String, dynamic>) {
        return Result.ok(responseData);
      }
      return Result.ok(<String, dynamic>{});
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> searchUsers(String keyWord) async {
    try {
      final response = await _client.get('/users/profiles/username/$keyWord');
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
      final formData = FormData();

      formData.fields.add(MapEntry('name', name));
      formData.fields.add(MapEntry('description', description));

      for (final member in members) {
        formData.fields.add(MapEntry('members[]', member));
      }

      if (profileImage != null) {
        formData.files.add(
          MapEntry(
            'profileImage',
            await MultipartFile.fromFile(
              profileImage.path,
              filename: profileImage.path.split('/').last,
            ),
          ),
        );
      }

      final response = await _client.post('/communities', data: formData);
      // The response is expected to include id.
      return Result.ok(response.data);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> fetchCommunity(String id) async {
    try {
      final response = await _client.get('/communities/$id');
      return Result.ok(response.data.cast<String, dynamic>());
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> fetchCommunityPosts(
    String communityId,
  ) async {
    try {
      final response = await _client.get('/communities/$communityId/posts');
      final List data = response.data;
      return Result.ok(data.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> fetchCommunityMembers(
    String communityId,
  ) async {
    try {
      final response = await _client.get('/communities/$communityId/members');
      final List data = response.data;
      return Result.ok(data.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> fetchTopCommunities() async {
    try {
      final response = await _client.get('/communities/top');
      final List data = response.data;
      return Result.ok(data.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> joinCommunity(String communityId) async {
    try {
      final response = await _client.post(
        '/communities/join',
        data: {'communityId': communityId},
      );
      final payload = _payload(response.data);
      return Result.ok(Map<String, dynamic>.from(payload as Map));
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> leaveCommunity(
    String communityId,
  ) async {
    try {
      final response = await _client.post(
        '/communities/leave',
        data: {'communityId': communityId},
      );
      final payload = _payload(response.data);
      return Result.ok(Map<String, dynamic>.from(payload as Map));
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> postToCommunity({
    required String communityId,
    required String content,
    List<String>? tags,
    List<File>? media,
    String visibility = 'PUBLIC',
    String? category,
  }) async {
    try {
      final mapData = <String, dynamic>{
        'communityId': communityId,
        'content': content,
        'visibility': visibility,
        // The backend accepts `tags` as JSON string or comma-separated string.
        if (tags != null) 'tags': jsonEncode(tags),
        if (category != null) 'category': category,
      };

      if (media != null && media.isNotEmpty) {
        mapData['media'] = await Future.wait(
          media.map(
            (file) => MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          ),
        );
      }

      final response = await _client.post(
        '/communities/posts',
        data: FormData.fromMap(mapData),
      );

      final payload = _payload(response.data);
      return Result.ok(Map<String, dynamic>.from(payload as Map));
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  // Course
  Future<Result<List<Map<String, dynamic>>>> fetchCourses(String id) async {
    try {
      final response = await _client.get('/courses/expert/$id');
      final data = response.data['data'] as List;
      return Result.ok(data.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> fetchFamousCourses() async {
    try {
      final response = await _client.get('/courses/top/enrolled');
      final data = response.data['data'] as List;
      return Result.ok(data.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> fetchAllEvents({
    String? search,
    String? university,
    DateTime? eventDay,
    String? authorId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (search != null) 'search': search,
        if (university != null) 'university': university,
        if (eventDay != null) 'eventDay': eventDay.toIso8601String(),
        if (authorId != null) 'authorId': authorId,
      };
      final response = await _client.get(
        '/events',
        queryParameters: queryParams,
      );
      final payload = _payload(response.data);
      final listPayload = _extractListPayload(payload);
      if (listPayload == null) {
        return Result.error(StateError('Invalid events payload'));
      }
      return Result.ok(listPayload.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> fetchTrendingEvents({
    String? university,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (university != null) 'university': university,
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      };
      final response = await _client.get(
        '/events/trending',
        queryParameters: queryParams,
      );
      final payload = _payload(response.data);
      final listPayload = _extractListPayload(payload);
      if (listPayload == null) {
        return Result.error(StateError('Invalid trending events payload'));
      }
      return Result.ok(listPayload.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> fetchPublicUserEvents(
    String userId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _client.get(
        '/events/user/$userId',
        queryParameters: {'page': page, 'limit': limit},
      );
      final payload = _payload(response.data);
      final listPayload = _extractListPayload(payload);
      if (listPayload == null) {
        return Result.error(StateError('Invalid user events payload'));
      }
      return Result.ok(listPayload.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<Map<String, dynamic>>>> fetchMyEvents({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _client.get(
        '/events/me',
        queryParameters: {'page': page, 'limit': limit},
      );
      final payload = _payload(response.data);
      final listPayload = _extractListPayload(payload);
      if (listPayload == null) {
        return Result.error(StateError('Invalid my events payload'));
      }
      return Result.ok(listPayload.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> fetchEventById(String id) async {
    try {
      final response = await _client.get('/events/$id');
      final payload = _payload(response.data);
      if (payload is Map<String, dynamic>) {
        return Result.ok(payload);
      }
      return Result.error(StateError('Invalid event payload'));
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> viewEvent(String id) async {
    try {
      await _client.post('/events/$id/view');
      return Result.ok(null);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> registerForEvent(String id) async {
    try {
      final response = await _client.post('/events/$id/register');
      final payload = _payload(response.data);
      if (payload is Map<String, dynamic>) {
        return Result.ok(payload);
      }
      return Result.ok(<String, dynamic>{});
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> cancelEventRegistration(String id) async {
    try {
      await _client.post('/events/$id/cancel-registration');
      return Result.ok(null);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> createEvent({
    required String title,
    required String description,
    required DateTime starts,
    required DateTime ends,
    required DateTime eventDay,
    required String location,
    required String university,
  }) async {
    try {
      final response = await _client.post(
        '/events',
        data: {
          'title': title,
          'description': description,
          'starts': starts.toIso8601String(),
          'ends': ends.toIso8601String(),
          'eventDay': eventDay.toIso8601String(),
          'location': location,
          'university': university,
        },
      );
      final responseData = _payload(response.data);
      if (responseData is Map<String, dynamic>) {
        return Result.ok(responseData);
      }
      return Result.ok(<String, dynamic>{});
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> updateEvent(
    String id, {
    String? title,
    String? description,
    DateTime? starts,
    DateTime? ends,
    DateTime? eventDay,
    String? location,
    String? university,
  }) async {
    try {
      final data = {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (starts != null) 'starts': starts.toIso8601String(),
        if (ends != null) 'ends': ends.toIso8601String(),
        if (eventDay != null) 'eventDay': eventDay.toIso8601String(),
        if (location != null) 'location': location,
        if (university != null) 'university': university,
      };
      final response = await _client.patch('/events/$id', data: data);
      final responseData = _payload(response.data);
      if (responseData is Map<String, dynamic>) {
        return Result.ok(responseData);
      }
      return Result.error(StateError('Invalid update response'));
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> deleteEvent(String id) async {
    try {
      await _client.delete('/events/$id');
      return Result.ok(null);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }

  // Notifications
  Future<Result<Map<String, dynamic>>> fetchNotifications({
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _client.get(
        '/notifications',
        queryParameters: {'limit': limit, if (unreadOnly) 'unreadOnly': true},
      );
      if (response.data is Map<String, dynamic>) {
        return Result.ok(Map<String, dynamic>.from(response.data as Map));
      }
      return Result.error(StateError('Invalid notifications payload'));
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<int>> fetchUnreadNotificationCount() async {
    try {
      final response = await _client.get('/notifications/unread-count');
      final payload = _payload(response.data);
      if (payload is Map<String, dynamic>) {
        final unreadCount = payload['unreadCount'];
        if (unreadCount is int) {
          return Result.ok(unreadCount);
        }
        if (unreadCount is num) {
          return Result.ok(unreadCount.toInt());
        }
      }
      return Result.error(StateError('Invalid unread count payload'));
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Map<String, dynamic>>> markNotificationAsRead(
    String notificationId,
  ) async {
    try {
      final response = await _client.patch(
        '/notifications/$notificationId/read',
      );
      if (response.data is Map<String, dynamic>) {
        return Result.ok(Map<String, dynamic>.from(response.data as Map));
      }
      return Result.error(StateError('Invalid mark-as-read payload'));
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<int>> markAllNotificationsAsRead() async {
    try {
      final response = await _client.patch('/notifications/read-all');
      final payload = _payload(response.data);
      if (payload is Map<String, dynamic>) {
        final updatedCount = payload['updatedCount'];
        if (updatedCount is int) {
          return Result.ok(updatedCount);
        }
        if (updatedCount is num) {
          return Result.ok(updatedCount.toInt());
        }
      }
      return Result.error(StateError('Invalid mark-all-read payload'));
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> updateNotificationDeviceToken(String? fcmToken) async {
    try {
      await _client.put(
        '/notifications/device-token',
        data: {'fcmToken': fcmToken},
      );
      return Result.ok(null);
    } on DioException catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(e);
    }
  }

  // Chats
  Future<Result<Map<String, dynamic>>> getChatId(String receiverId) async {
    try {
      final response = await _client.get('/chats/$receiverId');
      final Map<String, dynamic> data = response.data;
      return Result.ok(data);
    } on DioException catch (e) {
      return Result.error(e);
    }
  }
}
