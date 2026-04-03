import 'dart:io';

import '../../../domain/models/user/user.dart';
import '../../../utils/result.dart';

abstract class UserRepository {
  Future<Result<List<User>>> searchUsers(String keyWord);
  Future<Result<User>> getUser(String id);
  Future<Result<User>> getCurrentUser();
  Future<Result<List<User>>> getFriends();
  Future<Result<List<User>>> getCommunityMembers(String id);
  Future<Result> updateProfile(String? firstName, String? lastName, String? username, String? bio, File? profilePic);
}