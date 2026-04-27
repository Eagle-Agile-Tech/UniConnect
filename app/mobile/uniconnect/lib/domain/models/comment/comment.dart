import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

@freezed
abstract class Comment with _$Comment {
  factory Comment({
    required String id,
    String? parentCommentId,
    required String postId,
    required String content,
    required String authorId,
    required String authorName,
    required String? authorProfilePicUrl,
    required DateTime createdAt,
    @Default(0) int likeCount,
    @Default(0) int replyCount,
    @JsonKey(readValue: readIsLikedByMe) @Default(false) bool isLikedByMe,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);

}

Object? readIsLikedByMe(Map<dynamic, dynamic> json, String key) {
  final direct = json[key];
  if (direct is bool) return direct;

  final interaction = json['userInteraction'];
  if (interaction is Map) {
    final hasReacted = interaction['hasReacted'];
    if (hasReacted is bool) return hasReacted;
  }

  return false;
}