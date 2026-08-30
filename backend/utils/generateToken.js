const jwt = require('jsonwebtoken');

/**
 * Generates a signed JWT for a given user id and role.
 * @param {String} id - Mongo ObjectId of the user
 * @param {String} role - user role (student | alumni | admin)
 */
const generateToken = (id, role) => {
  return jwt.sign({ id, role }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE || '7d',
  });
};

module.exports = generateToken;
