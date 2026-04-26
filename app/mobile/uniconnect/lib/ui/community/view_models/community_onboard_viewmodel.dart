import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/community/community_repository.dart';
import 'package:uniconnect/ui/auth/auth_state_provider.dart';

import '../../../data/repository/community/community_repository_remote.dart';
import '../../../data/repository/user/user_repository_remote.dart';

final friendsProvider = FutureProvider((ref) async {
  final userRepo = ref.watch(userRepoProvider);
  final friends = await userRepo.getUserNetworks(ref.read(authNotifierProvider).value!.user!.id);
  return friends.fold((data) => data, (error, stackTrace) => throw error);
});

final onboardCommunity = AsyncNotifierProvider(OnboardCommunity.new);

class OnboardCommunity extends AsyncNotifier<String> {
  late CommunityRepository _comRepo;

  @override
  FutureOr<String> build() {
    _comRepo = ref.watch(communityRepoProvider);
    return '';
  }

  Future<void> registerCommunity({
    required String name,
    required String description,
    File? profilePic,
    required List<String> members,
  }) async {
    state = AsyncValue.loading();
    final result = await _comRepo.createCommunity(
      name: name,
      description: description,
      members: members,
      profileImage: profilePic,
    );
    state = result.fold(
          (data) => state =  AsyncValue.data(data),
          (error, stackTrace) => AsyncError(error, StackTrace.current),
    );
  }
}
