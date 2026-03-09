const {
  AppError,
  ConflictError,
  NotFoundError,
  ValidationError,
  ServiceUnavailableError,
} = require('../errors');
const logger = require('../utils/logger');
const { isDevelopment, isProduction } = require('../config/env');

function deriveErrorCode(error) {
  if (error.errorCode) {
    return error.errorCode;
  }

  if (error.statusCode >= 500) {
    return 'INTERNAL_ERROR';
  }

  return 'REQUEST_ERROR';
}

function errorHandler(err, req, res, next) { // eslint-disable-line no-unused-vars
  let error;

  if (err?.code === 'P2002') {
    error = new ConflictError('Unique constraint violation (duplicate entry)');
  } else if (err?.code === 'P2025') {
    error = new NotFoundError('Record not found');
  } else if (err?.name === 'MulterError') {
    if (err.code === 'LIMIT_FILE_SIZE') {
      error = new ValidationError('Uploaded file is too large. Maximum size is 5MB');
    } else {
      error = new ValidationError(err.message || 'Invalid file upload');
    }
  } else if (err?.message === 'Only image files are allowed') {
    error = new ValidationError('Only image files are allowed');
  } else if (err?.code === 'P1001' || err?.code === 'P1017') {
    error = new ServiceUnavailableError('Database connection failed');
  } else if (err?.name === 'PrismaClientValidationError') {
    error = new ValidationError('Invalid data format for database');
  } else if (err?.name === 'PrismaClientInitializationError') {
    error = new ServiceUnavailableError('Cannot initialize database connection');
  } else if (err?.message?.toLowerCase().includes('redis')) {
    error = new ServiceUnavailableError('Cache service unavailable');
  } else if (err instanceof AppError) {
    error = err;
  } else if (err?.name === 'ZodError') {
    error = new ValidationError('Request validation failed');
    error.details = err.issues?.map((issue) => ({
      path: issue.path.join('.'),
      message: issue.message,
    }));
  } else if (err instanceof Error) {
    error = new AppError(err.message || 'Internal Server Error', 500, false, 'INTERNAL_ERROR');
  } else {
    error = new AppError('Unknown error', 500, false, 'INTERNAL_ERROR');
  }

  const logEntry = {
    statusCode: error.statusCode,
    message: error.message,
    path: req.originalUrl,
    method: req.method,
    stack: error.stack,
    isOperational: error.isOperational,
  };

  if (error.isOperational) {
    logger.warn(logEntry);
  } else {
    logger.error(logEntry);
  }

  const message = isProduction && !error.isOperational
    ? 'Something went wrong'
    : error.message;
  const errorCode = deriveErrorCode(error);

  res.status(error.statusCode).json({
    status: error.statusCode < 500 ? 'fail' : 'error',
    errorCode,
    message,
    ...(isDevelopment && error.details && { errors: error.details }),
    ...(isDevelopment && { stack: error.stack }),
  });
}

module.exports = errorHandler;
