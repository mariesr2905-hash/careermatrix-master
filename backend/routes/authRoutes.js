const express = require('express');
const { body } = require('express-validator');
const {
  register,
  login,
  getMe,
  forgotPassword,
  resetPassword,
} = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validateMiddleware');

const router = express.Router();

// @route   POST /api/auth/register
router.post(
  '/register',
  [
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('email').isEmail().withMessage('Please provide a valid email').normalizeEmail(),
    body('password')
      .isLength({ min: 8 })
      .withMessage('Password must be at least 8 characters long'),
    body('role')
      .optional()
      .isIn(['student', 'alumni', 'mentor', 'company', 'admin'])
      .withMessage('Role must be student, alumni, mentor, company, or admin'),
  ],
  validate,
  register
);

// @route   POST /api/auth/login
router.post(
  '/login',
  [
    body('email').isEmail().withMessage('Please provide a valid email').normalizeEmail(),
    body('password').notEmpty().withMessage('Password is required'),
    body('role')
      .optional()
      .isIn(['student', 'alumni', 'mentor', 'company', 'admin'])
      .withMessage('Role must be student, alumni, mentor, company, or admin'),
  ],
  validate,
  login
);

// @route   GET /api/auth/me
router.get('/me', protect, getMe);

// @route   POST /api/auth/forgot-password
router.post(
  '/forgot-password',
  [body('email').isEmail().withMessage('Please provide a valid email').normalizeEmail()],
  validate,
  forgotPassword
);

// @route   PUT /api/auth/reset-password/:resettoken
router.put(
  '/reset-password/:resettoken',
  [
    body('password')
      .isLength({ min: 8 })
      .withMessage('Password must be at least 8 characters long'),
  ],
  validate,
  resetPassword
);

module.exports = router;
