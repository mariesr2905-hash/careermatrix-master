const { body, param, query } = require('express-validator');

const createRequestValidator = [
  param('mentorId').isMongoId().withMessage('Invalid mentor id'),
  body('message').optional().isLength({ max: 1000 }).withMessage('Message cannot exceed 1000 characters'),
];

const requestIdValidator = [param('id').isMongoId().withMessage('Invalid mentorship request id')];

const respondRequestValidator = [
  param('id').isMongoId().withMessage('Invalid mentorship request id'),
  body('responseNote').optional().isLength({ max: 500 }).withMessage('Response note cannot exceed 500 characters'),
];

const getRequestsValidator = [
  query('status')
    .optional()
    .isIn(['Pending', 'Accepted', 'Rejected', 'Cancelled'])
    .withMessage('status must be one of: Pending, Accepted, Rejected, Cancelled'),
  query('role')
    .optional()
    .isIn(['sent', 'received'])
    .withMessage('role must be either sent or received'),
  query('page').optional().isInt({ min: 1 }).withMessage('page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('limit must be between 1 and 100'),
];

module.exports = {
  createRequestValidator,
  requestIdValidator,
  respondRequestValidator,
  getRequestsValidator,
};
