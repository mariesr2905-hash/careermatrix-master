const Education = require('../models/Education');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const { sendResponse } = require('../utils/apiResponse');

/**
 * @desc    Add a new education record for the logged-in user
 * @route   POST /api/education
 * @access  Private
 */
const addEducation = asyncHandler(async (req, res) => {
  const { institution, degree, department, course, startYear, endYear, grade } = req.body;

  const education = await Education.create({
    user: req.user._id,
    institution,
    degree,
    department,
    course,
    startYear,
    endYear,
    grade,
  });

  return sendResponse(res, 201, true, 'Education record added successfully', education);
});

/**
 * @desc    Update an existing education record (owner only)
 * @route   PUT /api/education/:id
 * @access  Private
 */
const updateEducation = asyncHandler(async (req, res, next) => {
  let education = await Education.findById(req.params.id);

  if (!education) {
    return next(new ErrorResponse(`Education record not found with id ${req.params.id}`, 404));
  }

  if (String(education.user) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to update this education record', 403));
  }

  const allowedFields = ['institution', 'degree', 'department', 'course', 'startYear', 'endYear', 'grade'];
  const updates = {};
  allowedFields.forEach((field) => {
    if (req.body[field] !== undefined) updates[field] = req.body[field];
  });

  education = await Education.findByIdAndUpdate(req.params.id, updates, {
    new: true,
    runValidators: true,
  });

  return sendResponse(res, 200, true, 'Education record updated successfully', education);
});

/**
 * @desc    Delete an education record (owner only)
 * @route   DELETE /api/education/:id
 * @access  Private
 */
const deleteEducation = asyncHandler(async (req, res, next) => {
  const education = await Education.findById(req.params.id);

  if (!education) {
    return next(new ErrorResponse(`Education record not found with id ${req.params.id}`, 404));
  }

  if (String(education.user) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to delete this education record', 403));
  }

  await education.deleteOne();

  return sendResponse(res, 200, true, 'Education record deleted successfully');
});

/**
 * @desc    Get all education records for the logged-in user
 * @route   GET /api/education/me
 * @access  Private
 */
const getMyEducation = asyncHandler(async (req, res) => {
  const education = await Education.find({ user: req.user._id }).sort({ startYear: -1 });
  return sendResponse(res, 200, true, 'Education records fetched successfully', education);
});

/**
 * @desc    Get all education records for a specific user
 * @route   GET /api/education/user/:userId
 * @access  Private
 */
const getUserEducation = asyncHandler(async (req, res) => {
  const education = await Education.find({ user: req.params.userId }).sort({ startYear: -1 });
  return sendResponse(res, 200, true, 'Education records fetched successfully', education);
});

module.exports = {
  addEducation,
  updateEducation,
  deleteEducation,
  getMyEducation,
  getUserEducation,
};
