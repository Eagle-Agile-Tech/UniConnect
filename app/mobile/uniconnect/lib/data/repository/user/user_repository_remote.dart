import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/user/user_repository.dart';
import 'package:uniconnect/domain/models/user/user.dart';
import 'package:uniconnect/utils/result.dart';

import '../../service/api/api_client.dart';

final userRepoProvider = Provider(
  (ref) => UserRepositoryRemote(ref.watch(apiClientProvider)),
);

class UserRepositoryRemote implements UserRepository {
  final ApiClient _client;

  const UserRepositoryRemote(this._client);

  @override
  Future<Result> updateProfile(
      String? firstName,
      String? lastName,
      String? username,
      String? bio,
      File? profilePic,
      ) async {
    final result = await _client.updateProfile(firstName, lastName, username, bio, profilePic);
    return result.fold(
      (data) => Result.ok(''),
      (error, stackTrace) => Result.ok(error),
    );
  }

  @override
  Future<Result<List<User>>> searchUsers(String keyWord) async {
    final result = await _client.searchUsers(keyWord);
    return result.fold((data) {
      final users = data.map((user) => User.fromJson(user)).toList();
      return Result.ok(users);
    }, (error, _) => Result.error(error));
  }

  @override
  Future<Result<User>> getCurrentUser() async {
    final result = await _client.fetchCurrentUser();
    return result.fold((data) {
      final user = User.fromJson(data);
      return Result.ok(user);
    }, (error, _) => Result.error(error));
  }

  @override
  Future<Result<User>> getUser(String id) async {
    final result = await _client.fetchUser(id);
    return result.fold((data) {
      final user = User.fromJson(data);
      return Result.ok(user);
    }, (error, _) => Result.error(error));
  }

  @override
  Future<Result<List<User>>> getFriends() async {
    final result = await _client.fetchFriends();
    return result.fold((data) {
      final users = data.map((user) => User.fromJson(user)).toList();
      return Result.ok(users);
    }, (error, _) => Result.error(error));
  }

  @override
  Future<Result<List<User>>> getCommunityMembers(String id) async {
    final result = await _client.fetchCommunityMembers(id);
    return result.fold((data) {
      final users = data.map((user) => User.fromJson(user)).toList();
      return Result.ok(users);
    }, (error, _) => Result.error(error));
  }
}
