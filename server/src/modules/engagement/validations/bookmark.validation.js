// server/src/modules/engagement/validations/bookmark.validation.js
const { body, param } = require("express-validator");

const validateBookmark = [
  param("postId").isUUID().withMessage("Invalid post ID format"),

  body("userId").isUUID().withMessage("Invalid user ID format"),
];

module.exports = { validateBookmark };
