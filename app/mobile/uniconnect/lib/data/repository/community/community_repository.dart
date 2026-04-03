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
}