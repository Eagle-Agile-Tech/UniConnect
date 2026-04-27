module.exports = {
  postRoutes: require("./post.routes"),
  postController: require("./post.controller"),
  // Services
  postCreateService: require("./services/post-create.service"),
  postDeleteService: require("./services/post-delete.service"),
  postFeedService: require("./services/post-feed.service"),
};
