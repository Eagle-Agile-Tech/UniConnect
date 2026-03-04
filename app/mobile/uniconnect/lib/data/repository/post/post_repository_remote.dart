import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/post/post_repository.dart';
import 'package:uniconnect/data/service/api/api_client.dart';
import 'package:uniconnect/domain/models/post/post.dart';
import 'package:uniconnect/utils/result.dart';

final postProvider = Provider<PostRepositoryRemote>(
  (ref) => PostRepositoryRemote(apiClient: ref.watch(apiClientProvider)),
);

class PostRepositoryRemote implements PostRepository {
  const PostRepositoryRemote({required ApiClient apiClient})
    : _apiClient = apiClient;
  final ApiClient _apiClient;

  @override
  Future<Result<List<Post>>> getUserPost(String id) async {
    final result = await _apiClient.fetchUserPost(id);
    return result.fold(
      (data) {
        List<dynamic> jsonList = jsonDecode(data);
        final posts = jsonList.map((post) => Post.fromJson(post as Map<String, dynamic>)).toList();
        return Result.ok(posts);
      },
      (error, stackTrace) {
        return Result.error(error);
      },
    );
  }
}
