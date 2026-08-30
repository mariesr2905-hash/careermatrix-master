const express = require('express');
const {
  upsertCareerPreferences,
  getCareerPreferences,
  generateRecommendations,
  getLatestRecommendations,
  getRecommendationHistory,
  getRecommendedCourses,
} = require('../controllers/careerRecommendationController');
const { protect } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validateMiddleware');
const { preferencesValidator, historyValidator } = require('../validators/careerValidator');

const router = express.Router();

router.use(protect);

// @route   PUT /api/career/preferences
router.put('/preferences', preferencesValidator, validate, upsertCareerPreferences);

// @route   GET /api/career/preferences
router.get('/preferences', getCareerPreferences);

// @route   POST /api/career/recommendations/generate
router.post('/recommendations/generate', generateRecommendations);

// @route   GET /api/career/recommendations/latest
router.get('/recommendations/latest', getLatestRecommendations);

// @route   GET /api/career/recommendations/history
router.get('/recommendations/history', historyValidator, validate, getRecommendationHistory);

// @route   GET /api/career/courses
router.get('/courses', getRecommendedCourses);

module.exports = router;
