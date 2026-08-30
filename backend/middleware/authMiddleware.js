const jwt = require('jsonwebtoken');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const User = require('../models/User');

/**
 * Protect routes - verifies JWT from the Authorization header (Bearer token)
 * or from a signed cookie, then attaches the authenticated user to req.user.
 */
const protect = asyncHandler(async (req, res, next) => {
  let token;

  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer')
  ) {
    token = req.headers.authorization.split(' ')[1];
  } else if (req.cookies && req.cookies.token) {
    token = req.cookies.token;
  } else if (req.query && req.query.token) {
    token = req.query.token;
  }

  if (!token) {
    return next(new ErrorResponse('Not authorized, no token provided', 401));
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const user = await User.findById(decoded.id);

    if (!user) {
      return next(new ErrorResponse('User belonging to this token no longer exists', 401));
    }

    const status = (user.status || '').toUpperCase();
    if (status === 'PENDING') {
      return next(new ErrorResponse('Your account is pending administrator approval. Please wait until an administrator approves your account.', 403));
    }
    if (status === 'REJECTED') {
      return next(new ErrorResponse('Your account registration has been rejected. Please contact the administrator for more information.', 403));
    }
    if (status === 'DEACTIVATED' || !user.isActive) {
      return next(new ErrorResponse('Your account has been deactivated. Please contact the administrator.', 403));
    }
    if (status !== 'APPROVED' && status !== 'ACTIVE') {
      return next(new ErrorResponse('Access denied. Account not approved.', 403));
    }

    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return next(new ErrorResponse('Session expired, please log in again', 401));
    }
    return next(new ErrorResponse('Not authorized, invalid token', 401));
  }
});

module.exports = { protect };
