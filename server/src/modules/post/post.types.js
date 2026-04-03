/**
 * @typedef {Object} PostCreateInput
 * @property {string} content
 * @property {'PUBLIC'|'PRIVATE'} [visibility]
 * @property {string[]} [tags]
 * @property {string} [category]
 * @property {string[]} [mediaIds]
 */

/**
 * @typedef {Object} PostUpdateInput
 * @property {string} [content]
 * @property {'PUBLIC'|'PRIVATE'} [visibility]
 * @property {string[]} [tags]
 * @property {string} [category]
 * @property {string[]} [mediaIds]
 */

/**
 * @typedef {Object} PostFilterOptions
 * @property {string} [authorId]
 * @property {string[]} [tags]
 * @property {string} [category]
 * @property {Date} [fromDate]
 * @property {Date} [toDate]
 * @property {boolean} [hasMedia]
 * @property {'createdAt'|'reactionCount'|'commentCount'|'shareCount'} [sortBy]
 * @property {'asc'|'desc'} [sortOrder]
 * @property {string} [searchQuery]
 * @property {string} [cursor]
 * @property {number} [limit]
 */

/**
 * @typedef {Object} PostReactionInput
 * @property {'LIKE'|'LOVE'|'INSIGHTFUL'|'SUPPORT'|'CELEBRATE'} type
 */
