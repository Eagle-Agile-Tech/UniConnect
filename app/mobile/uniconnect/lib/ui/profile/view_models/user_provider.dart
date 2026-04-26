import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uniconnect/domain/models/user/user.dart';

import '../../../data/repository/user/user_repository.dart';
import '../../../data/repository/user/user_repository_remote.dart';
import '../../../utils/enums.dart';
import '../../../utils/result.dart';

final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  final repo = ref.watch(userRepoProvider);
  final result = await repo.getUser(userId);
  return result.fold((data) => data, (error, stackTrace) => throw error);
});

final selectedChatUserProvider = StateProvider<User?>((ref) => null);

final selectedUserProfileProvider = StateProvider<User?>((ref) => null);

final userReportActionProvider =
    AsyncNotifierProvider.family<UserReportActionViewModel, bool, String>(
      UserReportActionViewModel.new,
    );

class UserReportActionViewModel extends AsyncNotifier<bool> {
  final String userId;

  UserReportActionViewModel(this.userId);

  late UserRepository _repo;

  @override
  Future<bool> build() async {
    _repo = ref.read(userRepoProvider);
    return false;
  }

  Future<Result<void>> reportUser({
    required ReportReason reason,
    String? message,
  }) async {
    if (state.isLoading) {
      return Result.error(StateError('Report already in progress'));
    }

    state = const AsyncValue.loading();
    final result = await _repo.reportUser(
      userId: userId,
      reason: reason,
      message: message,
    );
    state = const AsyncValue.data(false);
    return result;
  }
}
