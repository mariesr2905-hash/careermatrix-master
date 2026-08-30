/**
 * Standardized success response shape used across all controllers.
 * Keeps the API contract consistent for the Flutter frontend.
 */
const sendResponse = (res, statusCode, success, message, data = null, extra = {}) => {
  const payload = { success, message, ...extra };
  if (data !== null) payload.data = data;
  return res.status(statusCode).json(payload);
};

module.exports = { sendResponse };
