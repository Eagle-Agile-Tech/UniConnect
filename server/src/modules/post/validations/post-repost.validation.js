// server/src/modules/post/validations/post-repost.validation.js
const { body, param } = require("express-validator");

const validateRepost = [
  param("postId").isUUID().withMessage("Invalid post ID format"),

  body("content")
    .optional()
    .isString()
    .trim()
    .isLength({ max: 5000 })
    .withMessage("Content must be less than 5000 characters"),

  body("visibility")
    .optional()
    .isIn(["PUBLIC", "PRIVATE"])
    .withMessage("Visibility must be PUBLIC or PRIVATE"),
];

const validateGetReposts = [
  param("postId").isUUID().withMessage("Invalid post ID format"),

  param("userId").optional().isUUID().withMessage("Invalid user ID format"),

  body("cursor").optional().isString(),

  body("limit")
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage("Limit must be between 1 and 100"),
];

module.exports = {
  validateRepost,
  validateGetReposts,
};
