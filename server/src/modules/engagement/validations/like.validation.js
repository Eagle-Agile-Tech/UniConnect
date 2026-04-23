// server/src/modules/engagement/validations/like.validation.js
const { body, param } = require("express-validator");

const validateLike = [
  param("postId").isUUID().withMessage("Invalid post ID format"),

  body("type")
    .optional()
    .isIn(["LIKE", "LOVE", "INSIGHTFUL", "SUPPORT", "CELEBRATE"])
    .withMessage("Invalid reaction type"),
];

module.exports = { validateLike };
