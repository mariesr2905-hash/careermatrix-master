const Skill = require('../models/Skill');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const { sendResponse } = require('../utils/apiResponse');

/**
 * @desc    Add a new skill for the logged-in user
 * @route   POST /api/skills
 * @access  Private
 */
const addSkill = asyncHandler(async (req, res, next) => {
  const { skillName, category, proficiencyLevel } = req.body;

  const existing = await Skill.findOne({
    user: req.user._id,
    skillName: new RegExp(`^${skillName}$`, 'i'),
  });

  if (existing) {
    return next(new ErrorResponse('This skill already exists in your profile', 400));
  }

  const skill = await Skill.create({
    user: req.user._id,
    skillName,
    category,
    proficiencyLevel,
  });

  return sendResponse(res, 201, true, 'Skill added successfully', skill);
});

/**
 * @desc    Update an existing skill (owner only)
 * @route   PUT /api/skills/:id
 * @access  Private
 */
const updateSkill = asyncHandler(async (req, res, next) => {
  let skill = await Skill.findById(req.params.id);

  if (!skill) {
    return next(new ErrorResponse(`Skill not found with id ${req.params.id}`, 404));
  }

  if (String(skill.user) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to update this skill', 403));
  }

  const allowedFields = ['skillName', 'category', 'proficiencyLevel'];
  const updates = {};
  allowedFields.forEach((field) => {
    if (req.body[field] !== undefined) updates[field] = req.body[field];
  });

  skill = await Skill.findByIdAndUpdate(req.params.id, updates, {
    new: true,
    runValidators: true,
  });

  return sendResponse(res, 200, true, 'Skill updated successfully', skill);
});

/**
 * @desc    Delete a skill (owner only)
 * @route   DELETE /api/skills/:id
 * @access  Private
 */
const deleteSkill = asyncHandler(async (req, res, next) => {
  const skill = await Skill.findById(req.params.id);

  if (!skill) {
    return next(new ErrorResponse(`Skill not found with id ${req.params.id}`, 404));
  }

  if (String(skill.user) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to delete this skill', 403));
  }

  await skill.deleteOne();

  return sendResponse(res, 200, true, 'Skill deleted successfully');
});

/**
 * @desc    Get all skills for the logged-in user
 * @route   GET /api/skills/me
 * @access  Private
 */
const getMySkills = asyncHandler(async (req, res) => {
  const skills = await Skill.find({ user: req.user._id }).sort({ createdAt: -1 });
  return sendResponse(res, 200, true, 'Skills fetched successfully', skills);
});

/**
 * @desc    Get all skills for a specific user
 * @route   GET /api/skills/user/:userId
 * @access  Private
 */
const getUserSkills = asyncHandler(async (req, res) => {
  const skills = await Skill.find({ user: req.params.userId }).sort({ createdAt: -1 });
  return sendResponse(res, 200, true, 'Skills fetched successfully', skills);
});

module.exports = {
  addSkill,
  updateSkill,
  deleteSkill,
  getMySkills,
  getUserSkills,
};
