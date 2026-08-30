const ErrorResponse = require('../utils/errorResponse');

/**
 * Handles requests to routes that do not exist.
 */
const notFound = (req, res, next) => {
  const error = new ErrorResponse(`Route not found - ${req.originalUrl}`, 404);
  next(error);
};

/**
 * Centralized error handler. Normalizes Mongoose, JWT, and Multer errors
 * into a consistent JSON error response.
 */
const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;
  error.statusCode = err.statusCode;

  console.error(err.stack || err);

  // Mongoose bad ObjectId
  if (err.name === 'CastError') {
    error = new ErrorResponse(`Resource not found with id of ${err.value}`, 404);
  }

  // Mongoose duplicate key
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue || {})[0] || 'field';
    error = new ErrorResponse(`Duplicate value entered for '${field}'. Please use another value`, 400);
  }

  // Mongoose validation error
  if (err.name === 'ValidationError') {
    const message = Object.values(err.errors).map((val) => val.message);
    error = new ErrorResponse(message.join(', '), 400);
  }

  // Multer file upload errors
  if (err.name === 'MulterError') {
    error = new ErrorResponse(`File upload error: ${err.message}`, 400);
  }

  // JWT errors (fallback, most are already caught in authMiddleware)
  if (err.name === 'JsonWebTokenError') {
    error = new ErrorResponse('Invalid token', 401);
  }
  if (err.name === 'TokenExpiredError') {
    error = new ErrorResponse('Token expired', 401);
  }

  res.status(error.statusCode || 500).json({
    success: false,
    message: error.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};

module.exports = { notFound, errorHandler };
