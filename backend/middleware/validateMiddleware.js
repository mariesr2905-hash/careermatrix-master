const { validationResult } = require('express-validator');

/**
 * Runs after express-validator's check()/body() chains.
 * If any validation errors were collected, responds with 422 and
 * a list of field-level messages. Otherwise passes control onward.
 */
const validate = (req, res, next) => {
  const errors = validationResult(req);

  if (!errors.isEmpty()) {
    return res.status(422).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array().map((e) => ({
        field: e.path,
        message: e.msg,
      })),
    });
  }

  next();
};

module.exports = { validate };
