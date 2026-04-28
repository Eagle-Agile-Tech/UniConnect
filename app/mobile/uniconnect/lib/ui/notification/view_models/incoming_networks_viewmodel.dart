import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repository/user/user_repository_remote.dart';
import '../../../domain/models/user/user.dart';

final incomingNetworksProvider =
    AsyncNotifierProvider<IncomingNetworksViewModel, List<(User, String)>>(
  IncomingNetworksViewModel.new,
);

class IncomingNetworksViewModel extends AsyncNotifier<List<(User, String)>> {
  Future<List<(User, String)>> _fetch() async {
    final repo = ref.read(userRepoProvider);
    final result = await repo.getIncomingNetworks();
    return result.fold((data) => data, (error, _) => throw error);
  }

  @override
  FutureOr<List<(User, String)>> build() async {
    return _fetch();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncValue.data(await _fetch());
  }
}
