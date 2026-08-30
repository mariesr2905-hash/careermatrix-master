/**
 * Custom error class that carries an HTTP status code alongside the message.
 * Thrown from controllers/services and caught by the global error middleware.
 */
class ErrorResponse extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    Error.captureStackTrace(this, this.constructor);
  }
}

module.exports = ErrorResponse;
