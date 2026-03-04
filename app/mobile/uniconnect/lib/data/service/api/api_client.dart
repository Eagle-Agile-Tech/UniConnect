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
      final request = http.MultipartRequest('POST', Uri.http('localhost:8080', '/createPost/$userId',));
      request.fields['content'] = content;
      request.fields['createdAt'] = createdAt.toIso8601String();
      if (hashtags != null) {
        request.fields['hashtags'] = jsonEncode(hashtags);
      }
      if (mediaUrls != null){
        for (var file in mediaUrls){
          final multipartFile = await http.MultipartFile.fromPath('media', file.path);
          request.files.add(multipartFile);
        }
      }
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200){
        return Result.ok(null);
      } else {
        return Result.error(Exception('Failed to create post'));
      }
    } catch (e) {
      return Result.error(e);
    }
  }
}
