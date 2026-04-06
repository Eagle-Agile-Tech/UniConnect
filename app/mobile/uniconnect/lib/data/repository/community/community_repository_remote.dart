import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/utils/result.dart';

import '../../../domain/models/community/community.dart';
import '../../../ui/auth/auth_state_provider.dart';
import '../../service/api/api_client.dart';
import 'community_repository.dart';

final communityRepoProvider = Provider<CommunityRepositoryRemote>((ref) {
  final user = ref.watch(authNotifierProvider);
  final apiClient = ref.watch(apiClientProvider);
  return CommunityRepositoryRemote(userId: user.value!.user!.id, apiClient);
});

class CommunityRepositoryRemote implements CommunityRepository {
  const CommunityRepositoryRemote(this._client, {required String userId})
    : _userId = userId;

  final ApiClient _client;
  final String _userId;

  @override
  Future<Result<String>> createCommunity({
    required String name,
    required String description,
    required List<String> members,
    File? profileImage,
  }) async {
    final result = await _client.createCommunity(
      name: name,
      description: description,
      members: members,
    );
    return result.fold((data) {
      return Result.ok(data['id']);
    }, (error, _) => Result.error(error));
  }

  @override
  Future<Result<Community>> getCommunity(String id) async {
    final result = await _client.fetchCommunity(id);
    return result.fold(
      (data) {
        final community = Community.fromJson(data);
        return Result.ok(community);
      },
      (error, stackTrace) {
        return Result.error(error, stackTrace);
      },
    );
  }

  @override
  Future<Result<List<Community>>> getTopCommunities() async {
    final result = await _client.fetchTopCommunities();
    return result.fold((data) {
      List<Community> communities = data
          .map((community) => Community.fromJson(community))
          .toList();
      return Result.ok(communities);
    }, (error, stackTrace) => Result.error(error, stackTrace));
  }
}
