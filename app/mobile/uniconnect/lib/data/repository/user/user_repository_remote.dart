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
  Future<Result<List<User>>> searchUsers(String keyWord) async {
    final result = await _client.searchUsers(keyWord);
    return result.fold((data) {
      final users = data.map((user) => User.fromJson(user)).toList();
      return Result.ok(users);
    }, (error, _) => Result.error(error));
  }
}
