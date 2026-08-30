const express = require('express');
const { body, param } = require('express-validator');
const {
  addEducation,
  updateEducation,
  deleteEducation,
  getMyEducation,
  getUserEducation,
} = require('../controllers/educationController');
const { protect } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validateMiddleware');

const router = express.Router();

router.use(protect);

const currentYear = new Date().getFullYear() + 5;

const educationValidationRules = [
  body('institution').trim().notEmpty().withMessage('Institution/College name is required'),
  body('degree').trim().notEmpty().withMessage('Degree is required'),
  body('department').optional().trim(),
  body('course').optional().trim(),
  body('startYear')
    .isInt({ min: 1950, max: currentYear })
    .withMessage('Please provide a valid start year'),
  body('endYear')
    .optional()
    .isInt({ min: 1950, max: currentYear })
    .withMessage('Please provide a valid end year'),
  body('grade').optional().trim().isLength({ max: 20 }).withMessage('Grade cannot exceed 20 characters'),
];

// Separate (not shared/mutated) rule set for updates, where every field is optional.
const educationUpdateValidationRules = [
  body('institution').optional().trim().notEmpty().withMessage('Institution/College name cannot be empty'),
  body('degree').optional().trim().notEmpty().withMessage('Degree cannot be empty'),
  body('department').optional().trim(),
  body('course').optional().trim(),
  body('startYear')
    .optional()
    .isInt({ min: 1950, max: currentYear })
    .withMessage('Please provide a valid start year'),
  body('endYear')
    .optional()
    .isInt({ min: 1950, max: currentYear })
    .withMessage('Please provide a valid end year'),
  body('grade').optional().trim().isLength({ max: 20 }).withMessage('Grade cannot exceed 20 characters'),
];

// @route   POST /api/education
router.post('/', educationValidationRules, validate, addEducation);

// @route   GET /api/education/me
router.get('/me', getMyEducation);

// @route   GET /api/education/user/:userId
router.get(
  '/user/:userId',
  [param('userId').isMongoId().withMessage('Invalid user id')],
  validate,
  getUserEducation
);

// @route   PUT /api/education/:id
router.put(
  '/:id',
  [param('id').isMongoId().withMessage('Invalid education id'), ...educationUpdateValidationRules],
  validate,
  updateEducation
);

// @route   DELETE /api/education/:id
router.delete(
  '/:id',
  [param('id').isMongoId().withMessage('Invalid education id')],
  validate,
  deleteEducation
);

module.exports = router;
