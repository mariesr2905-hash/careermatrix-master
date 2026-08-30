const { body, query } = require('express-validator');

const workPreferences = ['Remote', 'On-site', 'Hybrid', 'No preference'];

const preferencesValidator = [
  body('interestedRoles').optional().isArray().withMessage('interestedRoles must be an array of strings'),
  body('preferredIndustries').optional().isArray().withMessage('preferredIndustries must be an array of strings'),
  body('preferredLocations').optional().isArray().withMessage('preferredLocations must be an array of strings'),
  body('workPreference')
    .optional()
    .isIn(workPreferences)
    .withMessage(`workPreference must be one of: ${workPreferences.join(', ')}`),
  body('careerGoals').optional().isLength({ max: 1000 }).withMessage('careerGoals cannot exceed 1000 characters'),
];

const historyValidator = [
  query('page').optional().isInt({ min: 1 }).withMessage('page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('limit must be between 1 and 100'),
];

module.exports = {
  preferencesValidator,
  historyValidator,
};
