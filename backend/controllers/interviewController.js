const InterviewQuestion = require('../models/InterviewQuestion');
const MockInterview = require('../models/MockInterview');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const { sendResponse } = require('../utils/apiResponse');

// ---------------- Interview Question CRUD (Admin managed) ----------------

/**
 * @desc    Add a new interview question
 * @route   POST /api/interviews/questions
 * @access  Private/Admin
 */
const addQuestion = asyncHandler(async (req, res) => {
  const { question, category, difficulty, role, suggestedAnswer } = req.body;

  const newQuestion = await InterviewQuestion.create({
    question,
    category,
    difficulty,
    role,
    suggestedAnswer,
    createdBy: req.user._id,
  });

  return sendResponse(res, 201, true, 'Interview question added successfully', newQuestion);
});

/**
 * @desc    Get all interview questions (filterable by category, difficulty, role)
 * @route   GET /api/interviews/questions?category=Technical&difficulty=Medium&role=Backend%20Developer&page=1&limit=10
 * @access  Private
 */
const getAllQuestions = asyncHandler(async (req, res) => {
  const page = Math.max(Number(req.query.page) || 1, 1);
  const limit = Math.min(Number(req.query.limit) || 10, 100);
  const skip = (page - 1) * limit;

  const filter = {};
  if (req.query.category) filter.category = req.query.category;
  if (req.query.difficulty) filter.difficulty = req.query.difficulty;
  if (req.query.role) filter.role = { $regex: req.query.role, $options: 'i' };

  const [questions, total] = await Promise.all([
    InterviewQuestion.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
    InterviewQuestion.countDocuments(filter),
  ]);

  return sendResponse(res, 200, true, 'Interview questions fetched successfully', questions, {
    pagination: { total, page, pages: Math.ceil(total / limit), limit },
  });
});

/**
 * @desc    Update an interview question
 * @route   PUT /api/interviews/questions/:id
 * @access  Private/Admin
 */
const updateQuestion = asyncHandler(async (req, res, next) => {
  const allowedFields = ['question', 'category', 'difficulty', 'role', 'suggestedAnswer'];
  const updates = {};
  allowedFields.forEach((field) => {
    if (req.body[field] !== undefined) updates[field] = req.body[field];
  });

  const updated = await InterviewQuestion.findByIdAndUpdate(req.params.id, updates, {
    new: true,
    runValidators: true,
  });

  if (!updated) {
    return next(new ErrorResponse(`Interview question not found with id ${req.params.id}`, 404));
  }

  return sendResponse(res, 200, true, 'Interview question updated successfully', updated);
});

/**
 * @desc    Delete an interview question
 * @route   DELETE /api/interviews/questions/:id
 * @access  Private/Admin
 */
const deleteQuestion = asyncHandler(async (req, res, next) => {
  const question = await InterviewQuestion.findByIdAndDelete(req.params.id);

  if (!question) {
    return next(new ErrorResponse(`Interview question not found with id ${req.params.id}`, 404));
  }

  return sendResponse(res, 200, true, 'Interview question deleted successfully');
});

// ---------------- Mock Interview Records ----------------

/**
 * @desc    Save a mock interview result for the logged-in user
 * @route   POST /api/interviews/results
 * @access  Private
 */
const saveInterviewResult = asyncHandler(async (req, res) => {
  const { type, questionsAttempted, feedback } = req.body;

  const record = await MockInterview.create({
    user: req.user._id,
    type,
    questionsAttempted,
    feedback,
  });

  return sendResponse(res, 201, true, 'Interview result saved successfully', record);
});

/**
 * @desc    Get the logged-in user's own interview history
 * @route   GET /api/interviews/history/me
 * @access  Private
 */
const getMyInterviewHistory = asyncHandler(async (req, res) => {
  const history = await MockInterview.find({ user: req.user._id }).sort({ dateTaken: -1 });
  return sendResponse(res, 200, true, 'Interview history fetched successfully', history);
});

/**
 * @desc    Get a specific user's interview history (Admin only)
 * @route   GET /api/interviews/history/:userId
 * @access  Private/Admin
 */
const getUserInterviewHistory = asyncHandler(async (req, res) => {
  const history = await MockInterview.find({ user: req.params.userId }).sort({ dateTaken: -1 });
  return sendResponse(res, 200, true, "User's interview history fetched successfully", history);
});

/**
 * @desc    Get all mock interview records across all users (Admin management)
 * @route   GET /api/interviews/results?page=1&limit=10
 * @access  Private/Admin
 */
const getAllInterviewRecords = asyncHandler(async (req, res) => {
  const page = Math.max(Number(req.query.page) || 1, 1);
  const limit = Math.min(Number(req.query.limit) || 10, 100);
  const skip = (page - 1) * limit;

  const [records, total] = await Promise.all([
    MockInterview.find()
      .populate('user', 'name email role')
      .sort({ dateTaken: -1 })
      .skip(skip)
      .limit(limit),
    MockInterview.countDocuments(),
  ]);

  return sendResponse(res, 200, true, 'All interview records fetched successfully', records, {
    pagination: { total, page, pages: Math.ceil(total / limit), limit },
  });
});

/**
 * @desc    Delete a mock interview record (Admin management)
 * @route   DELETE /api/interviews/results/:id
 * @access  Private/Admin
 */
const deleteInterviewRecord = asyncHandler(async (req, res, next) => {
  const record = await MockInterview.findByIdAndDelete(req.params.id);

  if (!record) {
    return next(new ErrorResponse(`Interview record not found with id ${req.params.id}`, 404));
  }

  return sendResponse(res, 200, true, 'Interview record deleted successfully');
});

module.exports = {
  addQuestion,
  getAllQuestions,
  updateQuestion,
  deleteQuestion,
  saveInterviewResult,
  getMyInterviewHistory,
  getUserInterviewHistory,
  getAllInterviewRecords,
  deleteInterviewRecord,
};
