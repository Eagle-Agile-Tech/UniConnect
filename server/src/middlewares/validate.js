// src/middlewares/validate.js
// SIMPLE VALIDATION - Will be enhanced later
const { validationResult } = require("express-validator");

/**
 * Simple validation middleware
 * Checks if required fields exist
 */
const validate = (schema) => {
  return async (req, res, next) => {
    // Support express-validator chains used by engagement module.
    if (Array.isArray(schema)) {
      await Promise.all(schema.map((chain) => chain.run(req)));
      const result = validationResult(req);

      if (!result.isEmpty()) {
        return res.status(400).json({
          error: "Validation failed",
          code: "ERR_VALIDATION",
          details: result.array().map((issue) => ({
            field: issue.path,
            message: issue.msg,
          })),
        });
      }

      return next();
    }

    const errors = [];

    // Basic validation - check required fields exist
    Object.keys(schema).forEach((field) => {
      const fieldSchema = schema[field];

      // Check if field is required and exists
      if (fieldSchema.required) {
        const value = req.body[field];

        if (value === undefined || value === null) {
          errors.push({
            field,
            message: `${field} is required`,
          });
        } else if (
          fieldSchema.notEmpty &&
          typeof value === "string" &&
          value.trim() === ""
        ) {
          errors.push({
            field,
            message: `${field} cannot be empty`,
          });
        }
      }
    });

    if (errors.length > 0) {
      return res.status(400).json({
        error: "Validation failed",
        code: "ERR_VALIDATION",
        details: errors,
      });
    }

    next();
  };
};

module.exports = {
  validate,
};
