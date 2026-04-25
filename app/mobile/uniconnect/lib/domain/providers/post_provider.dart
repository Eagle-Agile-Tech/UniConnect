import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/post/post_repository.dart';
import 'package:uniconnect/data/repository/post/post_repository_remote.dart';

final postProvider = NotifierProvider(PostProvider.new);

class PostProvider extends Notifier<void> {
  late PostRepository _postRepo;

  @override
  void build() {
    _postRepo = ref.watch(postRemoteProvider);
    return;
  }

  Future<void> incrementLike({
    required String postId,
    required String userId,
  }) async {
    final result = await _postRepo.likePost(postId: postId, userId: userId);
    result.fold(
      (data) => null,
      (error, stackTrace) => Exception('Failed to like post'),
    );
  }
}
