const express = require('express');
const { body, param } = require('express-validator');
const {
  createProfile,
  getMyProfile,
  getProfileByUserId,
  updateProfile,
  uploadProfileImage,
} = require('../controllers/profileController');
const { protect } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validateMiddleware');
const { uploadProfileImage: uploadProfileImageMiddleware } = require('../middleware/uploadMiddleware');

const router = express.Router();

router.use(protect);

const profileValidationRules = [
  body('phone').optional().matches(/^[0-9+\-\s()]{7,20}$/).withMessage('Invalid phone number'),
  body('graduationYear').optional().isInt({ min: 1950, max: 2100 }).withMessage('Invalid graduation year'),
  body('linkedin').optional().isURL().withMessage('LinkedIn must be a valid URL'),
  body('github').optional().isURL().withMessage('GitHub must be a valid URL'),
  body('bio').optional().isLength({ max: 500 }).withMessage('Bio cannot exceed 500 characters'),
];

// @route   POST /api/profile
router.post('/', profileValidationRules, validate, createProfile);

// @route   GET /api/profile/me
router.get('/me', getMyProfile);

// @route   PUT /api/profile
router.put('/', profileValidationRules, validate, updateProfile);

// @route   PUT /api/profile/upload-image
router.put('/upload-image', uploadProfileImageMiddleware.single('image'), uploadProfileImage);

// @route   GET /api/profile/:userId
router.get(
  '/:userId',
  [param('userId').isMongoId().withMessage('Invalid user id')],
  validate,
  getProfileByUserId
);

module.exports = router;
