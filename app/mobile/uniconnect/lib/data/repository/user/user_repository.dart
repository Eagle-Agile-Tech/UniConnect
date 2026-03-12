import '../../../domain/models/user/user.dart';
import '../../../utils/result.dart';

abstract class UserRepository {
  Future<Result<List<User>>> searchUsers(String keyWord);
}