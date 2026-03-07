import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uniconnect/utils/result.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<Result<dynamic>> fetchUserPost(String id) async {
    try {
      final response = await _client.get(Uri.parse('/posts/$id'));
      if (response.statusCode == 200) {
        return Result.ok(response.body);
      } else {
        return Result.error(Exception('Couldn\'t fetch post'));
      }
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result> createPost({
    required String content,
    required List<File>? mediaUrls,
    required String userId,
    required DateTime createdAt,
    List<String>? hashtags,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.http('localhost:8080', '/createPost/$userId'),
      );
      request.fields['content'] = content;
      request.fields['createdAt'] = createdAt.toIso8601String();
      if (hashtags != null) {
        request.fields['hashtags'] = jsonEncode(hashtags);
      }
      if (mediaUrls != null) {
        for (var file in mediaUrls) {
          final multipartFile = await http.MultipartFile.fromPath(
            'media',
            file.path,
          );
          request.files.add(multipartFile);
        }
      }
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return Result.ok(null);
      } else {
        return Result.error(Exception('Failed to create post'));
      }
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<dynamic>> fetchFeed(String userId) async {
    try {
      final response = await _client.get(Uri.parse('/feed/$userId'));
      if (response.statusCode == 200) {
        return Result.ok(response.body);
      } else {
        return Result.error(Exception('Couldn\'t fetch feed!'));
      }
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result> likePost({
    required String postId,
    required String userId,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('/likePost/$postId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );
      await Future.delayed(Duration(seconds: 5)); // Simulate network delay
      if (response.statusCode == 200) {
        return Result.ok(null);
      } else {
        return Result.error(Exception('Failed to like post'));
      }
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result> commentOnPost({
    required String postId,
    required String comment,
    required DateTime createdAt,
    required String authorId,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('/commentPost/$postId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'postId': postId,
          'comment': comment,
          'createdAt': createdAt.toIso8601String(),
          'authorId': authorId,
        }),
      );
      await Future.delayed(Duration(seconds: 5));
      if (response.statusCode == 200) {
        return Result.ok(null);
      } else {
        return Result.error(Exception('Failed to comment on post'));
      }
    } catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<dynamic>> fetchComments(String postId) async {
    try {
      final response = await _client.get(Uri.parse('/comments/$postId'));
      if (response.statusCode == 200) {
        return Result.ok(response.body);
      } else {
        return Result.error(Exception('Couldn\'t fetch comments!'));
      }
    }catch(e){
      return Result.error(e);
    }
  }
}
