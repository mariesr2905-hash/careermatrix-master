const { body, param, query } = require('express-validator');

const notificationTypes = [
  'Info',
  'JobAlert',
  'InternshipAlert',
  'MentorshipRequest',
  'Booking',
  'Placement',
  'System',
  'Community',
  'Other',
];

const createNotificationValidator = [
  body('userId').isMongoId().withMessage('A valid userId is required'),
  body('title').trim().notEmpty().withMessage('Title is required'),
  body('message').trim().notEmpty().withMessage('Message is required'),
  body('type').optional().isIn(notificationTypes).withMessage(`type must be one of: ${notificationTypes.join(', ')}`),
];

const broadcastNotificationValidator = [
  body('role')
    .isIn(['student', 'alumni', 'admin', 'all'])
    .withMessage('role must be one of: student, alumni, admin, all'),
  body('title').trim().notEmpty().withMessage('Title is required'),
  body('message').trim().notEmpty().withMessage('Message is required'),
  body('type').optional().isIn(notificationTypes).withMessage(`type must be one of: ${notificationTypes.join(', ')}`),
];

const notificationIdValidator = [param('id').isMongoId().withMessage('Invalid notification id')];

const getNotificationsValidator = [
  query('page').optional().isInt({ min: 1 }).withMessage('page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('limit must be between 1 and 100'),
  query('isRead').optional().isBoolean().withMessage('isRead must be a boolean'),
  query('type').optional().isIn(notificationTypes).withMessage(`type must be one of: ${notificationTypes.join(', ')}`),
];

module.exports = {
  createNotificationValidator,
  broadcastNotificationValidator,
  notificationIdValidator,
  getNotificationsValidator,
};
