class CommentMapper {
  static toDTO(comment, userReactionMap = new Map()) {
    const firstName = comment.commenter?.firstName || "";
    const lastName = comment.commenter?.lastName || "";

    return {
      id: comment.id,
      postId: comment.postId,
      authorProfilePicUrl: comment.commenter?.profile?.profileImage || null,
      content: comment.content,
      authorId: comment.commenterId,
      authorName: `${firstName} ${lastName}`.trim(),
      createdAt: comment.createdAt
        ? new Date(comment.createdAt).toISOString()
        : null,

      likeCount: comment._count?.commentReactions || 0,
      replyCount: comment._count?.replies ?? 0,

      userInteraction: userReactionMap.has(comment.id)
        ? userReactionMap.get(comment.id)
        : null,
    };
  }

  static toList(comments, userReactionMap = new Map()) {
    return Array.isArray(comments)
      ? comments.map((c) => this.toDTO(c, userReactionMap))
      : [];
  }
}

module.exports = CommentMapper;
