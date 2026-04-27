import 'dart:io';

import '../../../domain/models/user/user.dart';
import '../../../utils/enums.dart';
import '../../../utils/result.dart';

abstract class UserRepository {
  Future<
    Result<
      List<(String id, String username, String? profileImage, String fullName)>
    >
  >
  searchUsers(String keyWord);
  Future<Result<User>> getUser(String id);
  Future<Result<List<User>>> getUserNetworks(String userId);
  Future<Result<User>> getCurrentUser();
  Future<Result<List<User>>> getCommunityMembers(String id);
  Future<Result> sendNetworkRequest(String receiverId);
  Future<Result> acceptNetworkRequest(String requestId);
  Future<Result> rejectNetworkRequest(String requestId);
  Future<Result> removeNetwork(String targetId);
  Future<Result> cancelNetwork(String receiverId);
  Future<Result<List<(User, String requestId)>>> getIncomingNetworks();
  Future<Result> updateProfile(
    String? firstName,
    String? lastName,
    String? username,
    String? bio,
    File? profilePic,
  );
  Future<Result<void>> reportUser({
    required String userId,
    required ReportReason reason,
    String? message,
  });
}
