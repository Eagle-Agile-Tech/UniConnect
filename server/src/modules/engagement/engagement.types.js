// server/src/modules/engagement/engagement.types.js
/**
 * Engagement Types Definition
 * This file contains type definitions (JSDoc comments) for the engagement module
 * Even though we're using JavaScript, these serve as documentation
 */

/**
 * @typedef {Object} Reaction
 * @property {string} id - UUID of the reaction
 * @property {string} type - Reaction type (LIKE, LOVE, INSIGHTFUL, SUPPORT, CELEBRATE)
 * @property {string} userId - ID of user who reacted
 * @property {string} postId - ID of post that was reacted to
 * @property {string} createdAt - ISO timestamp of when reaction was created
 * @property {Object} user - User who reacted (when populated)
 * @property {string} user.id - User ID
 * @property {string} user.username - Username
 * @property {Object} user.profile - User profile
 */

/**
 * @typedef {Object} Comment
 * @property {string} id - UUID of the comment
 * @property {string} postId - ID of post the comment belongs to
 * @property {string} commenterId - ID of user who commented
 * @property {string|null} parentCommentId - ID of parent comment (for replies)
 * @property {string} content - Comment content
 * @property {string} moderationStatus - PENDING, APPROVED, REJECTED
 * @property {boolean} isDeleted - Soft delete flag
 * @property {string} createdAt - ISO timestamp
 * @property {string} updatedAt - ISO timestamp
 * @property {Object} commenter - User who commented (when populated)
 * @property {Array<Comment>} replies - Replies to this comment (when populated)
 * @property {Object} _count - Count of related items
 * @property {number} _count.replies - Number of replies
 * @property {number} _count.commentReactions - Number of reactions
 */

/**
 * @typedef {Object} Bookmark
 * @property {string} id - UUID of the bookmark
 * @property {string} userId - ID of user who bookmarked
 * @property {string} postId - ID of bookmarked post
 * @property {string} createdAt - ISO timestamp
 * @property {Object} post - Bookmarked post (when populated)
 */

/**
 * @typedef {Object} EngagementCounts
 * @property {number} likeCount - Number of likes on a post
 * @property {number} commentCount - Number of comments on a post
 * @property {number} bookmarkCount - Number of bookmarks on a post
 * @property {Object} reactionBreakdown - Breakdown by reaction type
 * @property {number} reactionBreakdown.LIKE
 * @property {number} reactionBreakdown.LOVE
 * @property {number} reactionBreakdown.INSIGHTFUL
 * @property {number} reactionBreakdown.SUPPORT
 * @property {number} reactionBreakdown.CELEBRATE
 */

/**
 * @typedef {Object} PaginatedResponse
 * @property {Array} data - Array of items
 * @property {string|null} nextCursor - Cursor for next page
 */

// Export empty object since this is just for types
module.exports = {};
