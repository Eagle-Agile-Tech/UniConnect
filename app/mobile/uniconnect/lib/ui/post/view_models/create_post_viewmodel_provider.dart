import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/post/post_repository.dart';
import 'package:uniconnect/data/repository/post/post_repository_remote.dart';

final createPostViewModelProvider = AsyncNotifierProvider(
  CreatePostViewModel.new,
);

class CreatePostViewModel extends AsyncNotifier<void> {
  late final PostRepository _postRepo;

  @override
  FutureOr<void> build() {
    _postRepo = ref.watch(postRemoteProvider);
    return null;
  }

  Future<void> createPost({
    required String content,
    required List<File>? mediaUrls,
    required String userId,
    required DateTime createdAt,
    List<String>? hashtags,
  }) async {
    state = const AsyncValue.loading();
    final result = await _postRepo.createPost(
      content: content,
      mediaUrls: mediaUrls,
      createdAt: createdAt,
      hashtags: hashtags,
    );
    result.fold(
      (data) => state = const AsyncValue.data(null),
      (error, stackTrace) => AsyncError(error, stackTrace!),
    );
  }
}
