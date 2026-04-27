const {
  AppError,
  ConflictError,
  NotFoundError,
  ValidationError,
  BadRequestError,
  UnauthorizedError,
  ForbiddenError,
  RateLimitError,
  UnprocessableEntityError,
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

  if (err?.name === 'PrismaClientKnownRequestError') {
    switch (err.code) {
      case 'P2002':
        error = new ConflictError(`Unique constraint violation${err.meta?.target ? ` on ${err.meta.target}` : ''}`);
        if (err.meta) error.details = { ...error.details, meta: err.meta };
        break;
      case 'P2000':
        error = new ValidationError('Value too long for database field');
        if (err.meta) error.details = { ...error.details, meta: err.meta };
        break;
      case 'P2001':
      case 'P2025':
        error = new NotFoundError('Record not found');
        if (err.meta) error.details = { ...error.details, meta: err.meta };
        break;
      case 'P2003':
        error = new ConflictError('Foreign key constraint failed');
        if (err.meta) error.details = { ...error.details, meta: err.meta };
        break;
      case 'P2004':
        error = new BadRequestError('Constraint failed on the database');
        if (err.meta) error.details = { ...error.details, meta: err.meta };
        break;
      case 'P2011':
        error = new UnprocessableEntityError('Null constraint violation');
        if (err.meta) error.details = { ...error.details, meta: err.meta };
        break;
      case 'P2012':
        error = new UnprocessableEntityError('Missing required value');
        if (err.meta) error.details = { ...error.details, meta: err.meta };
        break;
      case 'P2021':
        error = new ServiceUnavailableError('Database table does not exist');
        if (err.meta) error.details = { ...error.details, meta: err.meta };
        break;
      case 'P2022':
        error = new ServiceUnavailableError('Database column does not exist');
        if (err.meta) error.details = { ...error.details, meta: err.meta };
        break;
      case 'P2034':
        error = new ServiceUnavailableError('Database transaction failed (deadlock)');
        if (err.meta) error.details = { ...error.details, meta: err.meta };
        break;
      case 'P3009':
        error = new ServiceUnavailableError('Migration failed and blocked new migrations');
        break;
      default:
        error = new AppError('Database request error', 500, false, 'DB_REQUEST_ERROR');
    }
  } else if (err?.name === 'MulterError') {
    if (err.code === 'LIMIT_FILE_SIZE') {
      error = new ValidationError('Uploaded file is too large. Maximum size is 5MB');
    } else if (err.code === 'LIMIT_FILE_COUNT') {
      error = new ValidationError('Too many files uploaded');
    } else if (err.code === 'LIMIT_UNEXPECTED_FILE') {
      error = new ValidationError('Unexpected file field in upload');
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
  } else if (err?.name === 'JsonWebTokenError') {
    error = new UnauthorizedError('Invalid authentication token');
  } else if (err?.name === 'TokenExpiredError') {
    error = new UnauthorizedError('Authentication token expired');
  } else if (err?.name === 'NotBeforeError') {
    error = new UnauthorizedError('Authentication token not active');
  } else if (err?.type === 'entity.too.large' || err?.status === 413) {
    error = new ValidationError('Request payload is too large');
  } else if (err?.code === 'LIMIT_RATE' || err?.status === 429) {
    error = new RateLimitError('Too many requests');
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
    ...(error.details && { details: error.details }),
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

  const isValidationError = error instanceof ValidationError;
  const validationPayload = isValidationError
    ? {
        validation: {
          source: error.source || 'body',
          ...(isDevelopment && error.details && { errors: error.details }),
        },
      }
    : {};

  res.status(error.statusCode).json({
    status: error.statusCode < 500 ? 'fail' : 'error',
    errorCode,
    message,
    ...(isDevelopment && error.details && { errors: error.details }),
    ...validationPayload,
    ...(isDevelopment && { stack: error.stack }),
  });
}

module.exports = errorHandler;
