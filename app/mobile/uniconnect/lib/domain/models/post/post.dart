import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';
part 'post.g.dart';

@freezed
abstract class Post with _$Post {
  factory Post({
    required String id,
    required String content,
    required String authorId,
    final String? authorProfilePicture,
    required String authorName,
    final List<String>? mediaUrls,
    required DateTime createdAt,
    final List<String>? tags,
    required final int likeCount,
    required final int commentCount,
    @Default(false) bool isLikedByMe,
    @Default(false) bool isBookmarkedByMe,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
