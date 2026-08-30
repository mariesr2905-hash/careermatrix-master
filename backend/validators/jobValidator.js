const { body, param, query } = require('express-validator');

const jobTypes = ['Full-time', 'Part-time', 'Contract', 'Remote'];

const createJobValidator = [
  body('title').trim().notEmpty().withMessage('Job title is required'),
  body('description').trim().notEmpty().withMessage('Job description is required'),
  body('company').trim().notEmpty().withMessage('Company name is required'),
  body('location').trim().notEmpty().withMessage('Location is required'),
  body('jobType').optional().isIn(jobTypes).withMessage(`jobType must be one of: ${jobTypes.join(', ')}`),
  body('skillsRequired').optional().isArray().withMessage('skillsRequired must be an array of strings'),
  body('salaryRange.min').optional().isFloat({ min: 0 }).withMessage('salaryRange.min must be a positive number'),
  body('salaryRange.max').optional().isFloat({ min: 0 }).withMessage('salaryRange.max must be a positive number'),
  body('applicationDeadline').optional().isISO8601().withMessage('applicationDeadline must be a valid date'),
];

const updateJobValidator = [
  param('id').isMongoId().withMessage('Invalid job id'),
  body('title').optional().trim().notEmpty().withMessage('Job title cannot be empty'),
  body('description').optional().trim().notEmpty().withMessage('Job description cannot be empty'),
  body('company').optional().trim().notEmpty().withMessage('Company name cannot be empty'),
  body('location').optional().trim().notEmpty().withMessage('Location cannot be empty'),
  body('jobType').optional().isIn(jobTypes).withMessage(`jobType must be one of: ${jobTypes.join(', ')}`),
  body('skillsRequired').optional().isArray().withMessage('skillsRequired must be an array of strings'),
  body('status').optional().isIn(['Open', 'Closed']).withMessage('status must be Open or Closed'),
  body('applicationDeadline').optional().isISO8601().withMessage('applicationDeadline must be a valid date'),
];

const jobIdValidator = [param('id').isMongoId().withMessage('Invalid job id')];

const applyJobValidator = [
  param('id').isMongoId().withMessage('Invalid job id'),
  body('coverLetter').optional().isLength({ max: 2000 }).withMessage('Cover letter cannot exceed 2000 characters'),
];

const getAllJobsValidator = [
  query('page').optional().isInt({ min: 1 }).withMessage('page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('limit must be between 1 and 100'),
];

module.exports = {
  createJobValidator,
  updateJobValidator,
  jobIdValidator,
  applyJobValidator,
  getAllJobsValidator,
};
