import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/post/post_repository.dart';
import 'package:uniconnect/domain/models/post/post.dart';
import 'package:uniconnect/ui/profile/view_models/user_provider.dart';

import '../../../data/repository/post/post_repository_remote.dart';

final homeViewModelProvider =
    AsyncNotifierProvider<HomeViewmodelProvider, List<Post>>(
      HomeViewmodelProvider.new,
    );

class HomeViewmodelProvider extends AsyncNotifier<List<Post>> {
  late PostRepository _postRepo;

  @override
  FutureOr<List<Post>> build() {
    _postRepo = ref.watch(postProvider);
    return _fetchPosts();
  }

  Future<List<Post>> _fetchPosts() async {
    state = const AsyncValue.loading();
    final result = await _postRepo.getFeed(ref.read(userProvider)!.id);
    return result.fold(
      (data) => data,
      (error, stackTrace) =>
          Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current),
    );
  }
}
