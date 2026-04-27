// utils/postDTO.js - ONLY UPDATE THIS FILE
function formatPostDTO(post, currentUserId = null) {
  // Get author name with proper fallback chain
  let authorName = "Unknown User";

  if (post.author) {
    // Priority 1: Use profile.fullName if exists
    if (post.author.profile?.fullName) {
      authorName = post.author.profile.fullName;
    }
    // Priority 2: Use firstName + lastName from User model
    else if (post.author.firstName || post.author.lastName) {
      authorName =
        `${post.author.firstName || ""} ${post.author.lastName || ""}`.trim();
      if (!authorName) authorName = "Unknown User";
    }
    // Priority 3: Use email username
    else if (post.author.email) {
      authorName = post.author.email.split("@")[0];
    }
  }

  return {
    id: post.id,
    content: post.content || "",

    authorId: post.author?.id || post.authorId,
    authorName: authorName, // ✅ Now uses fallback chain
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
