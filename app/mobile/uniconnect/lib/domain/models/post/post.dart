import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';
part 'post.g.dart';

@freezed
abstract class Post with _$Post {
  factory Post({
    required String id,
    required String content,
    required String authorId,
    final List<String>? mediaUrls,
    required DateTime createdAt,
    final List<String>? hashtags,
    required final int likeCount,
    required final int commentCount,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
