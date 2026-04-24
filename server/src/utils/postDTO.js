function formatPostDTO(post, currentUserId = null) {
  return {
    id: post.id,
    content: post.content || "",

    authorId: post.author?.id || post.authorId,
    authorName: post.author?.profile?.fullName || "Unknown User",
    authorProfilePicture: post.author?.profile?.profileImage || null,

    mediaUrls: post.media?.map((m) => m.fileUrl) || [],

    createdAt: post.createdAt,

    tags: post.tags || [],

    likeCount: post._count?.postReactions || 0,
    commentCount: post._count?.comments || 0,

    isLikedByMe:
      post.postReactions?.some((r) => r.userId === currentUserId) || false,

    isBookmarkedByMe:
      post.favorites?.some((f) => f.userId === currentUserId) || false,
  };
}

module.exports = { formatPostDTO };
