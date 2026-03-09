import '../../../domain/models/post/post.dart';
import '../../../utils/result.dart';

abstract class PostRepository {
  Future<Result<List<Post>>> getUserPost(String id);
}