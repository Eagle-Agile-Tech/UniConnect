// server/src/modules/engagement/validations/comment.validation.js
const { body, param } = require("express-validator");

const validateComment = [
  param("postId").isUUID().withMessage("Invalid post ID format"),

  body("comment")
    .notEmpty()
    .withMessage("Comment cannot be empty")
    .isLength({ max: 2000 })
    .withMessage("Comment must be less than 2000 characters"),

  body("createdAt").optional().isISO8601().withMessage("Invalid date format"),

  body("parentCommentId")
    .optional()
    .isUUID()
    .withMessage("Invalid parent comment ID format"),
];

module.exports = { validateComment };
