import 'package:uniconnect/data/service/api/models/create_account/create_account_response.dart';

import '../../../utils/result.dart';

abstract class UserRepository {
  Future<Result<CreateAccountResponse>> createUserAccount({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  });
}