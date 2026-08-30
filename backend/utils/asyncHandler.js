/**
 * Wraps an async controller function and forwards any thrown error
 * to Express's error-handling middleware via next().
 * Eliminates repetitive try/catch blocks in controllers.
 *
 * @param {Function} fn - async (req, res, next) => {...}
 */
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

module.exports = asyncHandler;
