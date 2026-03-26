import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/post/post_repository.dart';
import 'package:uniconnect/ui/auth/auth_state_provider.dart';

import '../../../data/repository/post/post_repository_remote.dart';
import '../../../domain/models/comment/comment.dart';

final commentProvider = AsyncNotifierProvider.autoDispose
    .family<CommentNotifier, List<Comment>, String>(CommentNotifier.new);

class CommentNotifier extends AsyncNotifier<List<Comment>> {
  CommentNotifier(this.postId);

  final String postId;
  late PostRepository _postRepo;

  @override
  FutureOr<List<Comment>> build() async {
    _postRepo = ref.watch(postRemoteProvider);
    final result = await _postRepo.getComments(postId);
    return result.fold(
      (data) => data,
      (error, stackTrace) =>
          Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current),
    );
  }

  // Future<List<Comment>> fetchComments({required String postId}) async{
  //   state = const AsyncValue.loading();
  //   final result = await _postRepo.getComments(postId);
  //   return result.fold(
  //         (data) => data,
  //         (error, stackTrace) =>
  //         Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current),
  //   );
  // }

  Future<void> makeComment({required String content}) async {
    final previous = state.value ?? [];
    state = AsyncValue.loading();
    final newComment = Comment(
      id: DateTime.now().toString(),
      content: content,
      postId: postId,
      authorId: ref.read(authNotifierProvider).value!.user!.id,
      authorName: ref.read(authNotifierProvider).value!.user!.fullName,
      authorProfilePicUrl: ref.read(authNotifierProvider).value!.user!.profilePicture ?? '',
      createdAt: DateTime.now(),
      likeCount: 0,
    );
    state = AsyncValue.data([newComment,...previous ]);
    final result = await _postRepo.commentOnPost(
      postId: postId,
      comment: content,
      createdAt: DateTime.now(),
      authorId: ref.read(authNotifierProvider).value!.user!.id,
    );
    result.fold(
      (data) => null,
      (error, stackTrace) {
        // todo: notify user of the error
        AsyncValue.error(error, stackTrace ?? StackTrace.current);
        state = AsyncValue.data(previous);
      },
    );
  }
}
