import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/ui/profile/view_models/user_provider.dart';

import '../../../data/repository/post/post_repository.dart';
import '../../../data/repository/post/post_repository_remote.dart';
import '../../../domain/models/post/post.dart';
import '../../auth/auth_state_provider.dart';

final bookmarkProvider = AsyncNotifierProvider<BookmarkProvider, List<Post>>(
  BookmarkProvider.new,
);

class BookmarkProvider extends AsyncNotifier<List<Post>> {
  late PostRepository _postRepo;

  @override
  FutureOr<List<Post>> build() async {
    _postRepo = ref.watch(postRemoteProvider);
    final userId = ref.read(authNotifierProvider).value!.user?.id;
    if (userId == null) return [];
    final result = await _postRepo.getBookmarks(userId);
    return result.fold((posts) {
      return posts
          .map((post) => post.copyWith(isBookmarkedByMe: true))
          .toList();
    }, (error, stackTrace) => throw error);
  }
}
