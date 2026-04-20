import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/user/user_repository.dart';
import 'package:uniconnect/data/repository/user/user_repository_remote.dart';

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
    final result = await _repo.getUserNetworks(userId);
    return result.fold((data) => data, (error, stackTrace) => throw error);
  }
}
