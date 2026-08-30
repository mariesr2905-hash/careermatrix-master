const { body, param, query } = require('express-validator');

const categories = ['Technical', 'HR', 'Behavioral', 'Aptitude', 'Other'];
const difficulties = ['Easy', 'Medium', 'Hard'];
const interviewTypes = ['Technical', 'HR', 'Behavioral', 'Mixed'];

const createQuestionValidator = [
  body('question').trim().notEmpty().withMessage('Question text is required'),
  body('category').optional().isIn(categories).withMessage(`category must be one of: ${categories.join(', ')}`),
  body('difficulty').optional().isIn(difficulties).withMessage(`difficulty must be one of: ${difficulties.join(', ')}`),
  body('role').optional().trim(),
  body('suggestedAnswer').optional().isLength({ max: 3000 }).withMessage('suggestedAnswer cannot exceed 3000 characters'),
];

const updateQuestionValidator = [
  param('id').isMongoId().withMessage('Invalid question id'),
  body('question').optional().trim().notEmpty().withMessage('Question text cannot be empty'),
  body('category').optional().isIn(categories).withMessage(`category must be one of: ${categories.join(', ')}`),
  body('difficulty').optional().isIn(difficulties).withMessage(`difficulty must be one of: ${difficulties.join(', ')}`),
  body('suggestedAnswer').optional().isLength({ max: 3000 }).withMessage('suggestedAnswer cannot exceed 3000 characters'),
];

const questionIdValidator = [param('id').isMongoId().withMessage('Invalid question id')];

const saveInterviewResultValidator = [
  body('type').optional().isIn(interviewTypes).withMessage(`type must be one of: ${interviewTypes.join(', ')}`),
  body('questionsAttempted')
    .isArray({ min: 1 })
    .withMessage('questionsAttempted must be a non-empty array'),
  body('questionsAttempted.*.questionText')
    .trim()
    .notEmpty()
    .withMessage('Each attempted question requires questionText'),
  body('questionsAttempted.*.userAnswer').optional().isString(),
  body('questionsAttempted.*.score')
    .optional()
    .isFloat({ min: 0, max: 10 })
    .withMessage('score must be between 0 and 10'),
  body('feedback').optional().isLength({ max: 2000 }).withMessage('feedback cannot exceed 2000 characters'),
];

const userIdParamValidator = [param('userId').isMongoId().withMessage('Invalid user id')];

const recordIdValidator = [param('id').isMongoId().withMessage('Invalid interview record id')];

const paginationValidator = [
  query('page').optional().isInt({ min: 1 }).withMessage('page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('limit must be between 1 and 100'),
];

module.exports = {
  createQuestionValidator,
  updateQuestionValidator,
  questionIdValidator,
  saveInterviewResultValidator,
  userIdParamValidator,
  recordIdValidator,
  paginationValidator,
};
