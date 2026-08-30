const crypto = require('crypto');

/**
 * Hashes a plain reset token using SHA-256 so it can be compared
 * against the hashed value stored in the database.
 * (The plain token is only ever sent to the user, never persisted.)
 */
const hashToken = (plainToken) => {
  return crypto.createHash('sha256').update(plainToken).digest('hex');
};

module.exports = { hashToken };
