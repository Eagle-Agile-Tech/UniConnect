import 'dart:io';

import '../../../domain/models/community/community.dart';
import '../../../utils/result.dart';

abstract class CommunityRepository{
  Future<Result<String>> createCommunity({
    required String name,
    required String description,
    required List<String> members,
    File? profileImage,
  });
  Future<Result<Community>> getCommunity(String id);
  Future<Result<List<Community>>> getTopCommunities();

  Future<Result<void>> joinCommunity(String communityId);
  Future<Result<void>> leaveCommunity(String communityId);

  Future<Result<Map<String, dynamic>>> postToCommunity({
    required String communityId,
    required String content,
    List<String>? tags,
    List<File>? media,
  });
}
