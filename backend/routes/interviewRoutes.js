const express = require('express');
const {
  addQuestion,
  getAllQuestions,
  updateQuestion,
  deleteQuestion,
  saveInterviewResult,
  getMyInterviewHistory,
  getUserInterviewHistory,
  getAllInterviewRecords,
  deleteInterviewRecord,
} = require('../controllers/interviewController');
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');
const { validate } = require('../middleware/validateMiddleware');
const {
  createQuestionValidator,
  updateQuestionValidator,
  questionIdValidator,
  saveInterviewResultValidator,
  userIdParamValidator,
  recordIdValidator,
  paginationValidator,
} = require('../validators/interviewValidator');

const router = express.Router();

router.use(protect);

// ---------------- Interview Questions (Admin CRUD) ----------------

// @route   POST /api/interviews/questions
router.post('/questions', authorize('admin'), createQuestionValidator, validate, addQuestion);

// @route   GET /api/interviews/questions
router.get('/questions', paginationValidator, validate, getAllQuestions);

// @route   PUT /api/interviews/questions/:id
router.put(
  '/questions/:id',
  authorize('admin'),
  updateQuestionValidator,
  validate,
  updateQuestion
);

// @route   DELETE /api/interviews/questions/:id
router.delete(
  '/questions/:id',
  authorize('admin'),
  questionIdValidator,
  validate,
  deleteQuestion
);

// ---------------- Mock Interview Results ----------------

// @route   POST /api/interviews/results
router.post('/results', saveInterviewResultValidator, validate, saveInterviewResult);

// @route   GET /api/interviews/results  (Admin - all records)
router.get('/results', authorize('admin'), paginationValidator, validate, getAllInterviewRecords);

// @route   DELETE /api/interviews/results/:id  (Admin)
router.delete(
  '/results/:id',
  authorize('admin'),
  recordIdValidator,
  validate,
  deleteInterviewRecord
);

// ---------------- Interview History ----------------

// @route   GET /api/interviews/history/me
router.get('/history/me', getMyInterviewHistory);

// @route   GET /api/interviews/history/:userId  (Admin)
router.get(
  '/history/:userId',
  authorize('admin'),
  userIdParamValidator,
  validate,
  getUserInterviewHistory
);

module.exports = router;
