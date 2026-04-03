// src/modules/post/utils/post.helpers.js

/**
 * Verify that media belongs to user and is not attached to any post
 * @param {Object} prisma - Prisma client instance
 * @param {string} userId - ID of the user
 * @param {string[]} mediaIds - Array of media IDs to verify
 * @returns {Promise<Array>} - Array of verified media
 */
async function verifyMediaOwnership(prisma, userId, mediaIds) {
  if (!mediaIds || mediaIds.length === 0) return [];

  const media = await prisma.media.findMany({
    where: {
      id: { in: mediaIds },
      uploaderId: userId,
      postId: null,
    },
  });

  if (media.length !== mediaIds.length) {
    throw new Error("One or more media files not found or already used");
  }

  return media;
}

/**
 * Get user's connected user IDs from communities they're in
 * @param {Object} prisma - Prisma client instance
 * @param {string} userId - ID of the user
 * @returns {Promise<string[]>} - Array of connected user IDs
 */
async function getConnectedUserIds(prisma, userId) {
  try {
    // Find all communities the user is a member of (with APPROVED status)
    const userCommunities = await prisma.communityMember.findMany({
      where: {
        userId: userId,
        status: "APPROVED",
      },
      select: {
        communityId: true,
      },
    });

    const communityIds = userCommunities.map((c) => c.communityId);

    if (communityIds.length === 0) {
      return []; // User isn't in any communities yet
    }

    // Find all other users in the same communities
    const members = await prisma.communityMember.findMany({
      where: {
        communityId: { in: communityIds },
        userId: { not: userId },
        status: "APPROVED",
      },
      select: {
        userId: true,
      },
      distinct: ["userId"],
    });

    return members.map((m) => m.userId);
  } catch (error) {
    console.error("Error in getConnectedUserIds:", error.message);
    return []; // Return empty array on error to prevent crashing
  }
}

/**
 * Format post response with counts
 * @param {Object} post - Post object from database
 * @param {string|null} userReaction - User's reaction type if any
 * @returns {Object} - Formatted post object
 */
function formatPostResponse(post, userReaction = null) {
  // Create a copy of the post
  const formattedPost = { ...post };

  // Add reaction and comment counts
  formattedPost.reactionCount = post._count?.reactions || 0;
  formattedPost.commentCount = post._count?.comments || 0;

  // Remove the _count object
  delete formattedPost._count;

  // Add user's reaction if provided
  if (userReaction) {
    formattedPost.userReaction = userReaction;
  }

  // Format author data if it exists
  if (formattedPost.author) {
    // If author has a profile, flatten username/profileImage onto author
    if (formattedPost.author.profile) {
      if (formattedPost.author.profile.username) {
        formattedPost.author.username = formattedPost.author.profile.username;
      }
      formattedPost.author.profileImage =
        formattedPost.author.profile.profileImage;
      // Remove the nested profile to avoid duplication
      delete formattedPost.author.profile;
    }
  }

  return formattedPost;
}

/**
 * Check if user can view a post based on visibility
 * @param {Object} post - Post object
 * @param {string|null} userId - Current user ID
 * @param {string[]} connectedUserIds - Array of connected user IDs
 * @returns {boolean} - Whether user can view the post
 */
function canViewPost(post, userId, connectedUserIds = []) {
  // Public posts - anyone can view
  if (post.visibility === "PUBLIC") {
    return true;
  }

  // Private posts
  if (post.visibility === "PRIVATE") {
    // If no user logged in, cannot view private posts
    if (!userId) return false;

    // Author can view their own private posts
    if (post.authorId === userId) return true;

    // Connected users can view private posts
    if (connectedUserIds.includes(post.authorId)) return true;

    return false;
  }

  return false;
}

/**
 * Extract mentions from post content
 * @param {string} content - Post content
 * @returns {string[]} - Array of mentioned usernames
 */
function extractMentions(content) {
  const mentionRegex = /@(\w+)/g;
  const mentions = [];
  let match;

  while ((match = mentionRegex.exec(content)) !== null) {
    mentions.push(match[1]);
  }

  return mentions;
}

/**
 * Extract hashtags from post content
 * @param {string} content - Post content
 * @returns {string[]} - Array of hashtags
 */
function extractHashtags(content) {
  const hashtagRegex = /#(\w+)/g;
  const hashtags = [];
  let match;

  while ((match = hashtagRegex.exec(content)) !== null) {
    hashtags.push(match[1]);
  }

  return hashtags;
}

/**
 * Validate post content length and sanitize
 * @param {string} content - Post content
 * @returns {string} - Sanitized content
 */
function sanitizeContent(content) {
  if (!content || typeof content !== "string") {
    throw new Error("Content must be a non-empty string");
  }

  const trimmed = content.trim();

  if (trimmed.length === 0) {
    throw new Error("Content cannot be empty");
  }

  if (trimmed.length > 5000) {
    throw new Error("Content exceeds maximum length of 5000 characters");
  }

  // Basic XSS prevention - escape HTML
  return trimmed
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

/**
 * Generate a summary from post content
 * @param {string} content - Post content
 * @param {number} maxLength - Maximum summary length
 * @returns {string} - Content summary
 */
function generateSummary(content, maxLength = 150) {
  if (!content) return "";

  const plainText = content.replace(/<[^>]*>/g, ""); // Remove HTML tags

  if (plainText.length <= maxLength) {
    return plainText;
  }

  return plainText.substring(0, maxLength).trim() + "...";
}

// ✅ EXPORT ALL FUNCTIONS - This is the critical part!
module.exports = {
  verifyMediaOwnership,
  getConnectedUserIds, // ← This was missing before!
  formatPostResponse,
  canViewPost,
  extractMentions,
  extractHashtags,
  sanitizeContent,
  generateSummary,
};
