import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repository/post/post_repository.dart';
import '../../../data/repository/post/post_repository_remote.dart';
import '../../../utils/enums.dart';
import '../../../utils/result.dart';

final postReportActionProvider =
    AsyncNotifierProvider.family<PostReportActionViewModel, bool, String>(
      PostReportActionViewModel.new,
    );

class PostReportActionViewModel extends AsyncNotifier<bool> {
  final String postId;

  PostReportActionViewModel(this.postId);

  late PostRepository _repo;

  @override
  FutureOr<bool> build() {
    _repo = ref.read(postRemoteProvider);
    return false;
  }

  Future<Result<void>> reportPost({
    required ReportReason reason,
    String? message,
  }) async {
    if (state.isLoading) {
      return Result.error(StateError('Report already in progress'));
    }

    state = const AsyncValue.loading();
    final result = await _repo.reportPost(
      postId: postId,
      reason: reason,
      message: message,
    );
    state = const AsyncValue.data(false);
    return result;
  }
}
