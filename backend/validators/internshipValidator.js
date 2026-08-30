const { body, param, query } = require('express-validator');

const createInternshipValidator = [
  body('title').trim().notEmpty().withMessage('Internship title is required'),
  body('description').trim().notEmpty().withMessage('Internship description is required'),
  body('company').trim().notEmpty().withMessage('Company name is required'),
  body('location').trim().notEmpty().withMessage('Location is required'),
  body('duration').trim().notEmpty().withMessage('Duration is required'),
  body('stipend').optional().isFloat({ min: 0 }).withMessage('Stipend must be a positive number'),
  body('skillsRequired').optional().isArray().withMessage('skillsRequired must be an array of strings'),
  body('applicationDeadline').optional().isISO8601().withMessage('applicationDeadline must be a valid date'),
];

const updateInternshipValidator = [
  param('id').isMongoId().withMessage('Invalid internship id'),
  body('title').optional().trim().notEmpty().withMessage('Title cannot be empty'),
  body('description').optional().trim().notEmpty().withMessage('Description cannot be empty'),
  body('company').optional().trim().notEmpty().withMessage('Company name cannot be empty'),
  body('location').optional().trim().notEmpty().withMessage('Location cannot be empty'),
  body('duration').optional().trim().notEmpty().withMessage('Duration cannot be empty'),
  body('stipend').optional().isFloat({ min: 0 }).withMessage('Stipend must be a positive number'),
  body('skillsRequired').optional().isArray().withMessage('skillsRequired must be an array of strings'),
  body('status').optional().isIn(['Open', 'Closed']).withMessage('status must be Open or Closed'),
  body('applicationDeadline').optional().isISO8601().withMessage('applicationDeadline must be a valid date'),
];

const internshipIdValidator = [param('id').isMongoId().withMessage('Invalid internship id')];

const applyInternshipValidator = [
  param('id').isMongoId().withMessage('Invalid internship id'),
  body('coverLetter').optional().isLength({ max: 2000 }).withMessage('Cover letter cannot exceed 2000 characters'),
];

const getAllInternshipsValidator = [
  query('page').optional().isInt({ min: 1 }).withMessage('page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('limit must be between 1 and 100'),
];

module.exports = {
  createInternshipValidator,
  updateInternshipValidator,
  internshipIdValidator,
  applyInternshipValidator,
  getAllInternshipsValidator,
};
