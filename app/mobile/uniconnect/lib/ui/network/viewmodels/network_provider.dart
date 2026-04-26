import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/user/user_repository.dart';
import 'package:uniconnect/data/repository/user/user_repository_remote.dart';
import 'package:uniconnect/ui/auth/auth_state_provider.dart';
import 'package:uniconnect/utils/result.dart';

import '../../../domain/models/user/user.dart';

final networksProvider =
    AsyncNotifierProvider.family<NetworksViewModel, List<User>, String>(
      NetworksViewModel.new,
    );

class NetworksViewModel extends AsyncNotifier<List<User>> {
  final String userId;

  NetworksViewModel(this.userId);

  late UserRepository _repo;


  @override
  FutureOr<List<User>> build() async {
    _repo = ref.read(userRepoProvider);
    String currentUserId = ref.read(authNotifierProvider).value!.user!.id;

    if (currentUserId == userId) {
      final result = await _repo.getUserNetworks(userId);
      return result.fold((data) => data, (error, stackTrace) => throw error);

    } else {
      final result = await _repo.getUserNetworks(userId);
      return result.fold((data) => data, (error, stackTrace) => throw error);
    }
  }

  Future<Result> removeConnection(String targetId) async {
    final previous = state.value;
    if (previous == null) return Result.error(StateError('Networks not loaded'));

    state = AsyncValue.data(
      previous.where((member) => member.id != targetId).toList(),
    );

    final result = await _repo.removeNetwork(targetId);
    return result.fold(
      (data) => Result.ok(data),
      (error, stackTrace) {
        state = AsyncValue.data(previous);
        return Result.error(error);
      },
    );
  }
}

final networkActionProvider =
    AsyncNotifierProvider.family<NetworkActionViewModel, bool, String>(
      NetworkActionViewModel.new,
    );

class NetworkActionViewModel extends AsyncNotifier<bool> {
  final String targetUserId;

  NetworkActionViewModel(this.targetUserId);

  late UserRepository _repo;

  @override
  FutureOr<bool> build() {
    _repo = ref.read(userRepoProvider);
    return false;
  }

  Future<Result> sendRequest() => _perform(() => _repo.sendNetworkRequest(targetUserId));

  Future<Result> acceptRequest() => _perform(() => _repo.acceptNetworkRequest(targetUserId));

  Future<Result> rejectRequest() => _perform(() => _repo.rejectNetworkRequest(targetUserId));

  Future<Result> removeConnection() => _perform(() => _repo.removeNetwork(targetUserId));

  Future<Result> cancelRequest() => _perform(() => _repo.cancelNetwork(targetUserId));

  Future<Result> _perform(Future<Result> Function() action) async {
    if (state.isLoading) {
      return Result.error(StateError('Network action in progress'));
    }

    state = const AsyncValue.loading();
    final result = await action();
    state = const AsyncValue.data(false);
    return result;
  }
}
