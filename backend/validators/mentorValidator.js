const { body, param, query } = require('express-validator');

const registerMentorValidator = [
  body('expertise')
    .isArray({ min: 1 })
    .withMessage('expertise must be a non-empty array of strings'),
  body('experienceYears')
    .isFloat({ min: 0 })
    .withMessage('experienceYears must be a positive number'),
  body('bio').optional().isLength({ max: 1000 }).withMessage('bio cannot exceed 1000 characters'),
  body('currentCompany').optional().trim(),
  body('currentPosition').optional().trim(),
  body('availableSlots').optional().isArray().withMessage('availableSlots must be an array of strings'),
];

const updateMentorValidator = [
  body('expertise').optional().isArray({ min: 1 }).withMessage('expertise must be a non-empty array'),
  body('experienceYears').optional().isFloat({ min: 0 }).withMessage('experienceYears must be a positive number'),
  body('bio').optional().isLength({ max: 1000 }).withMessage('bio cannot exceed 1000 characters'),
  body('availableSlots').optional().isArray().withMessage('availableSlots must be an array of strings'),
  body('isActive').optional().isBoolean().withMessage('isActive must be a boolean'),
];

const mentorIdValidator = [param('id').isMongoId().withMessage('Invalid mentor id')];

const bookSessionValidator = [
  param('id').isMongoId().withMessage('Invalid mentor id'),
  body('sessionDate').isISO8601().withMessage('sessionDate must be a valid date'),
  body('sessionTime').trim().notEmpty().withMessage('sessionTime is required'),
  body('topic').optional().isLength({ max: 300 }).withMessage('topic cannot exceed 300 characters'),
];

const bookingIdValidator = [param('bookingId').isMongoId().withMessage('Invalid booking id')];

const cancelBookingValidator = [
  param('bookingId').isMongoId().withMessage('Invalid booking id'),
  body('cancellationReason').optional().isLength({ max: 300 }).withMessage('cancellationReason cannot exceed 300 characters'),
];

const paginationValidator = [
  query('page').optional().isInt({ min: 1 }).withMessage('page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('limit must be between 1 and 100'),
];

module.exports = {
  registerMentorValidator,
  updateMentorValidator,
  mentorIdValidator,
  bookSessionValidator,
  bookingIdValidator,
  cancelBookingValidator,
  paginationValidator,
};
