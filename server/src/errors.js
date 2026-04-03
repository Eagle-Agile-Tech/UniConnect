class AppError extends Error {
  constructor(message, statusCode, isOperational = true, errorCode = 'APP_ERROR', details) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = isOperational;
    this.errorCode = errorCode;
    this.details = details;

    Error.captureStackTrace(this, this.constructor);
  }
}

class BadRequestError extends AppError {
  constructor(message = 'Bad Request') {
    super(message, 400, true, 'BAD_REQUEST');
  }
}

class ValidationError extends AppError {
  constructor(message = 'Validation failed') {
    super(message, 400, true, 'VALIDATION_ERROR');
  }
}

class NotFoundError extends AppError {
  constructor(message = 'Resource not found') {
    super(message, 404, true, 'NOT_FOUND');
  }
}

class ConflictError extends AppError {
  constructor(message = 'Conflict – resource already exists') {
    super(message, 409, true, 'CONFLICT');
  }
}

class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized') {
    super(message, 401, true, 'UNAUTHORIZED');
  }
}

class ForbiddenError extends AppError {
  constructor(message = 'Forbidden') {
    super(message, 403, true, 'FORBIDDEN');
  }
}

class RateLimitError extends AppError {
  constructor(message = 'Too many requests') {
    super(message, 429, true, 'RATE_LIMIT');
  }
}

class UnprocessableEntityError extends AppError {
  constructor(message = 'Unprocessable entity') {
    super(message, 422, true, 'UNPROCESSABLE_ENTITY');
  }
}

class ServiceUnavailableError extends AppError {
  constructor(message = 'Service temporarily unavailable') {
    super(message, 503, false, 'SERVICE_UNAVAILABLE');
  }
}

module.exports = {
  AppError,
  BadRequestError,
  ValidationError,
  NotFoundError,
  ConflictError,
  UnauthorizedError,
  ForbiddenError,
  RateLimitError,
  UnprocessableEntityError,
  ServiceUnavailableError,
};
