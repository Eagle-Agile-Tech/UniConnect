const { ValidationError } = require('../errors');

function validateRequest(schema, source = 'body') {
  return (req, res, next) => {
    const payload = req[source];
    const result = schema.safeParse(payload);

    if (!result.success) {
      const validationError = new ValidationError('Request validation failed');
      validationError.source = source;
      validationError.details = result.error.issues.map((issue) => ({
        path: issue.path.join('.'),
        message: issue.message,
      }));
      return next(validationError);
    }

    req[source] = result.data;
    return next();
  };
}

module.exports = validateRequest;
