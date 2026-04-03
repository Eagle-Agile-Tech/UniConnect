// src/middlewares/validate.js
// SIMPLE VALIDATION - Will be enhanced later

/**
 * Simple validation middleware
 * Checks if required fields exist
 */
const validate = (schema) => {
  return (req, res, next) => {
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
