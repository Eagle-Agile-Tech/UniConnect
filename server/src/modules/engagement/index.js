// server/src/modules/engagement/index.js
const engagementRoutes = require("./engagement.routes");
const likeService = require("./services/like.service");
const commentService = require("./services/comment.service");
const bookmarkService = require("./services/bookmark.service");

module.exports = {
  engagementRoutes,
  likeService,
  commentService,
  bookmarkService,
};
