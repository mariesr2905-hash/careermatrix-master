const { body, param, query } = require('express-validator');

const placementTypes = ['Full-time', 'Internship', 'Internship + PPO'];
const placementStatuses = ['Applied', 'Shortlisted', 'Offered', 'Placed', 'Rejected', 'Withdrawn'];

const createPlacementValidator = [
  body('student').isMongoId().withMessage('A valid student id is required'),
  body('company').trim().notEmpty().withMessage('Company name is required'),
  body('jobTitle').trim().notEmpty().withMessage('Job title is required'),
  body('placementDate').isISO8601().withMessage('placementDate must be a valid date'),
  body('package').optional().isFloat({ min: 0 }).withMessage('package must be a positive number'),
  body('placementType').optional().isIn(placementTypes).withMessage(`placementType must be one of: ${placementTypes.join(', ')}`),
  body('status').optional().isIn(placementStatuses).withMessage(`status must be one of: ${placementStatuses.join(', ')}`),
  body('location').optional().trim(),
  body('remarks').optional().isLength({ max: 500 }).withMessage('remarks cannot exceed 500 characters'),
];

const updatePlacementValidator = [
  param('id').isMongoId().withMessage('Invalid placement id'),
  body('company').optional().trim().notEmpty().withMessage('Company name cannot be empty'),
  body('jobTitle').optional().trim().notEmpty().withMessage('Job title cannot be empty'),
  body('placementDate').optional().isISO8601().withMessage('placementDate must be a valid date'),
  body('package').optional().isFloat({ min: 0 }).withMessage('package must be a positive number'),
  body('placementType').optional().isIn(placementTypes).withMessage(`placementType must be one of: ${placementTypes.join(', ')}`),
  body('status').optional().isIn(placementStatuses).withMessage(`status must be one of: ${placementStatuses.join(', ')}`),
  body('remarks').optional().isLength({ max: 500 }).withMessage('remarks cannot exceed 500 characters'),
];

const placementIdValidator = [param('id').isMongoId().withMessage('Invalid placement id')];

const studentIdValidator = [param('studentId').isMongoId().withMessage('Invalid student id')];

const getAllPlacementsValidator = [
  query('page').optional().isInt({ min: 1 }).withMessage('page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('limit must be between 1 and 100'),
  query('status').optional().isIn(placementStatuses).withMessage(`status must be one of: ${placementStatuses.join(', ')}`),
];

module.exports = {
  createPlacementValidator,
  updatePlacementValidator,
  placementIdValidator,
  studentIdValidator,
  getAllPlacementsValidator,
};
