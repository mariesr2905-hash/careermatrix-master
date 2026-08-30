const express = require('express');
const { param } = require('express-validator');
const {
  uploadResume,
  updateResume,
  deleteResume,
  downloadOwnResume,
  downloadResumeByUserId,
  getMyResumeMeta,
  getResumeAnalysis,
} = require('../controllers/resumeController');
const { protect } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validateMiddleware');
const { uploadResume: uploadResumeMiddleware } = require('../middleware/uploadMiddleware');

const router = express.Router();

router.use(protect);

// @route   POST /api/resume/upload
router.post('/upload', uploadResumeMiddleware.single('resume'), uploadResume);

// @route   PUT /api/resume/update
router.put('/update', uploadResumeMiddleware.single('resume'), updateResume);

// @route   DELETE /api/resume
router.delete('/', deleteResume);

// @route   GET /api/resume/download
router.get('/download', downloadOwnResume);

// @route   GET /api/resume/me
// NOTE: defined before /download/:userId is irrelevant (different path
// segment), but kept near the other "me"-style reads for clarity.
router.get('/me', getMyResumeMeta);

// @route   GET /api/resume/analysis
router.get('/analysis', getResumeAnalysis);

// @route   GET /api/resume/download/:userId
router.get(
  '/download/:userId',
  [param('userId').isMongoId().withMessage('Invalid user id')],
  validate,
  downloadResumeByUserId
);

module.exports = router;
