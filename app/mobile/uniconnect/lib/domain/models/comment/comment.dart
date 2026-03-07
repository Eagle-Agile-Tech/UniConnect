import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

@freezed
abstract class Comment with _$Comment {
  factory Comment({
    required String id,
    required String postId,
    required String content,
    required String authorId,
    required String authorName,
    required String? authorProfilePicUrl,
    required DateTime createdAt,
    required int likeCount,
}) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
}