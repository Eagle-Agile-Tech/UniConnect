// server/src/modules/engagement/validations/bookmark.validation.js
const { param } = require("express-validator");

const validateBookmark = [
  param("postId").isUUID().withMessage("Invalid post ID format"),
];

module.exports = { validateBookmark };
