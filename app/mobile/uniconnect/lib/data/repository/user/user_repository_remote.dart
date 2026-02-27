import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/user/user_repository.dart';
import 'package:uniconnect/data/service/api/models/create_account/create_account_response.dart';

import '../../../utils/result.dart';
import '../../service/api/api_client.dart';

final userRepositoryProvider = Provider<UserRepositoryRemote>((ref){
  return UserRepositoryRemote(ref.watch(apiClientProvider));
});

class UserRepositoryRemote implements UserRepository {
  final ApiClient _apiClient;
  UserRepositoryRemote(this._apiClient);

  @override
  Future<Result<CreateAccountResponse>> createUserAccount({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    final result = await _apiClient.createUserAccount(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        password: password);
    return result;
  }
}