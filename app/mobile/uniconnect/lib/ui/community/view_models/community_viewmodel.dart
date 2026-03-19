import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/community/community_repository.dart';
import 'package:uniconnect/data/repository/community/community_repository_remote.dart';

import '../../../data/repository/post/post_repository_remote.dart';
import '../../../data/repository/user/user_repository_remote.dart';
import '../../../domain/models/community/community.dart';
import '../../../domain/models/post/post.dart';
import '../../../domain/models/user/user.dart';

final communityProvider =
    AsyncNotifierProvider.family<CommunityViewModel, Community, String>(
      CommunityViewModel.new,
    );

class CommunityViewModel extends AsyncNotifier<Community> {
  CommunityViewModel(this.id);

  final String id;
  late CommunityRepository _comRepo;

  @override
  FutureOr<Community> build() async {
    _comRepo = ref.watch(communityRepoProvider);
    final response = await _comRepo.getCommunity(id);
    return response.fold(
      (data) => data,
      (error, stackTrace) =>
          Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current),
    );
  }
}

final communityPostsProvider = AsyncNotifierProvider.family<
    CommunityPostsViewModel,
    List<Post>,
    String>(CommunityPostsViewModel.new);

class CommunityPostsViewModel extends AsyncNotifier<List<Post>> {
  CommunityPostsViewModel(this.communityId);

  final String communityId;

  @override
  Future<List<Post>> build() async {
    final repo = ref.watch(postRemoteProvider);

    final result = await repo.getCommunityPost(communityId);

    return result.fold(
          (data) => data,
          (error, stack) =>
          Error.throwWithStackTrace(error, stack ?? StackTrace.current),
    );
  }
}

final communityMembersProvider =
AsyncNotifierProvider.family<
    CommunityMembersViewModel,
    List<User>,
    String>(CommunityMembersViewModel.new);

class CommunityMembersViewModel extends AsyncNotifier<List<User>>{
  CommunityMembersViewModel(this.communityId);
  final String communityId;
  @override
  FutureOr<List<User>> build() async{
    final repo = ref.watch(userRepoProvider);
    final result = await repo.getCommunityMembers(communityId);
    return result.fold(
          (data) => data,
          (error, stack) =>
          Error.throwWithStackTrace(error, stack ?? StackTrace.current),
    );
  }
}