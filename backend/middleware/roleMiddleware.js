const ErrorResponse = require('../utils/errorResponse');

/**
 * Restricts access to specific roles. Must be used AFTER the `protect`
 * middleware since it relies on req.user being set.
 *
 * Usage: authorize('admin') or authorize('admin', 'alumni')
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return next(new ErrorResponse('Not authorized to access this route', 401));
    }

    const userRoleUpper = (req.user.role || '').toUpperCase();
    const authorizedRolesUpper = roles.map(r => r.toUpperCase());

    if (!authorizedRolesUpper.includes(userRoleUpper)) {
      return next(
        new ErrorResponse(
          `Role '${req.user.role}' is not permitted to access this resource`,
          403
        )
      );
    }
    next();
  };
};

module.exports = { authorize };
