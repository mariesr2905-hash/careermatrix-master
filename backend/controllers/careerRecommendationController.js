const CareerPreference = require('../models/CareerPreference');
const CareerRecommendation = require('../models/CareerRecommendation');
const Skill = require('../models/Skill');
const Profile = require('../models/Profile');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const { sendResponse } = require('../utils/apiResponse');
const { generateCareerRecommendations, generateCourseRecommendations } = require('../services/aiRecommendationService');

/**
 * @desc    Create or update the logged-in user's career preferences
 * @route   PUT /api/career/preferences
 * @access  Private
 */
const upsertCareerPreferences = asyncHandler(async (req, res) => {
  const allowedFields = [
    'interestedRoles',
    'preferredIndustries',
    'preferredLocations',
    'workPreference',
    'careerGoals',
  ];

  const updates = {};
  allowedFields.forEach((field) => {
    if (req.body[field] !== undefined) updates[field] = req.body[field];
  });

  const preferences = await CareerPreference.findOneAndUpdate(
    { user: req.user._id },
    { $set: updates, $setOnInsert: { user: req.user._id } },
    { new: true, upsert: true, runValidators: true, setDefaultsOnInsert: true }
  );

  return sendResponse(res, 200, true, 'Career preferences saved successfully', preferences);
});

/**
 * @desc    Get the logged-in user's career preferences
 * @route   GET /api/career/preferences
 * @access  Private
 */
const getCareerPreferences = asyncHandler(async (req, res, next) => {
  const preferences = await CareerPreference.findOne({ user: req.user._id });

  if (!preferences) {
    return next(new ErrorResponse('No career preferences found. Please create them first.', 404));
  }

  return sendResponse(res, 200, true, 'Career preferences fetched successfully', preferences);
});

/**
 * @desc    Analyze the logged-in user's skills, profile, and preferences,
 *          then generate and store fresh career recommendations.
 * @route   POST /api/career/recommendations/generate
 * @access  Private
 */
const generateRecommendations = asyncHandler(async (req, res, next) => {
  const [skills, profile, preferences] = await Promise.all([
    Skill.find({ user: req.user._id }),
    Profile.findOne({ user: req.user._id }),
    CareerPreference.findOne({ user: req.user._id }),
  ]);

  if (!skills || skills.length === 0) {
    return next(
      new ErrorResponse('Add at least one skill to your profile before generating recommendations', 400)
    );
  }

  const skillNames = skills.map((s) => s.skillName);
  const interestedRoles = preferences ? preferences.interestedRoles : [];
  const department = profile ? profile.department : undefined;

  const recommendations = await generateCareerRecommendations({
    skills: skillNames,
    interestedRoles,
    department,
  });

  const record = await CareerRecommendation.create({
    user: req.user._id,
    recommendations,
    basedOn: {
      skills: skillNames,
      interestedRoles,
      department,
    },
  });

  return sendResponse(res, 201, true, 'Career recommendations generated successfully', record);
});

/**
 * @desc    Get the logged-in user's most recently generated recommendations
 * @route   GET /api/career/recommendations/latest
 * @access  Private
 */
const getLatestRecommendations = asyncHandler(async (req, res, next) => {
  const latest = await CareerRecommendation.findOne({ user: req.user._id }).sort({ generatedAt: -1 });

  if (!latest) {
    return next(
      new ErrorResponse('No recommendations found. Please generate recommendations first.', 404)
    );
  }

  return sendResponse(res, 200, true, 'Latest career recommendations fetched successfully', latest);
});

/**
 * @desc    Get the logged-in user's full career recommendation history
 * @route   GET /api/career/recommendations/history?page=1&limit=10
 * @access  Private
 */
const getRecommendationHistory = asyncHandler(async (req, res) => {
  const page = Math.max(Number(req.query.page) || 1, 1);
  const limit = Math.min(Number(req.query.limit) || 10, 100);
  const skip = (page - 1) * limit;

  const [history, total] = await Promise.all([
    CareerRecommendation.find({ user: req.user._id })
      .sort({ generatedAt: -1 })
      .skip(skip)
      .limit(limit),
    CareerRecommendation.countDocuments({ user: req.user._id }),
  ]);

  return sendResponse(res, 200, true, 'Career recommendation history fetched successfully', history, {
    pagination: { total, page, pages: Math.ceil(total / limit), limit },
  });
});

/**
 * @desc    Get deterministic, skill-gap-based course recommendations for
 *          the logged-in user (real backend logic, not mock data).
 * @route   GET /api/career/courses
 * @access  Private
 */
const getRecommendedCourses = asyncHandler(async (req, res) => {
  const skills = await Skill.find({ user: req.user._id });
  const courses = generateCourseRecommendations({ skills });
  return sendResponse(res, 200, true, 'Recommended courses fetched successfully', courses);
});

module.exports = {
  upsertCareerPreferences,
  getCareerPreferences,
  generateRecommendations,
  getLatestRecommendations,
  getRecommendationHistory,
  getRecommendedCourses,
};
