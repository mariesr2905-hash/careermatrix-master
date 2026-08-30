const Placement = require('../models/Placement');
const User = require('../models/User');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const { sendResponse } = require('../utils/apiResponse');
const { sendNotification } = require('../services/notificationService');

/**
 * @desc    Create a placement record for a student
 * @route   POST /api/placements
 * @access  Private/Admin
 */
const createPlacement = asyncHandler(async (req, res, next) => {
  const { student, company, jobTitle, package: pkg, placementType, location, placementDate, status, remarks } =
    req.body;

  const studentUser = await User.findById(student);
  if (!studentUser) {
    return next(new ErrorResponse(`Student not found with id ${student}`, 404));
  }

  const placement = await Placement.create({
    student,
    company,
    jobTitle,
    package: pkg,
    placementType,
    location,
    placementDate,
    status,
    remarks,
    addedBy: req.user._id,
  });

  await sendNotification({
    user: student,
    title: 'Placement Record Added',
    message: `A placement record for ${company} - ${jobTitle} has been added to your profile.`,
    type: 'Placement',
    relatedModel: 'Placement',
    relatedId: placement._id,
    createdBy: req.user._id,
  });

  return sendResponse(res, 201, true, 'Placement record created successfully', placement);
});

/**
 * @desc    Get all placement records with pagination, search, and filters
 * @route   GET /api/placements?page=1&limit=10&status=Placed&company=Acme&search=engineer
 * @access  Private/Admin
 */
const getAllPlacements = asyncHandler(async (req, res) => {
  const page = Math.max(Number(req.query.page) || 1, 1);
  const limit = Math.min(Number(req.query.limit) || 10, 100);
  const skip = (page - 1) * limit;

  const filter = {};
  if (req.query.status) filter.status = req.query.status;
  if (req.query.company) filter.company = { $regex: req.query.company, $options: 'i' };
  if (req.query.placementType) filter.placementType = req.query.placementType;
  if (req.query.search) filter.$text = { $search: req.query.search };

  const [placements, total] = await Promise.all([
    Placement.find(filter)
      .populate('student', 'name email role')
      .populate('addedBy', 'name email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit),
    Placement.countDocuments(filter),
  ]);

  return sendResponse(res, 200, true, 'Placement records fetched successfully', placements, {
    pagination: { total, page, pages: Math.ceil(total / limit), limit },
  });
});

/**
 * @desc    Get a single placement record by ID
 * @route   GET /api/placements/:id
 * @access  Private/Admin
 */
const getPlacementById = asyncHandler(async (req, res, next) => {
  const placement = await Placement.findById(req.params.id)
    .populate('student', 'name email role')
    .populate('addedBy', 'name email');

  if (!placement) {
    return next(new ErrorResponse(`Placement record not found with id ${req.params.id}`, 404));
  }

  return sendResponse(res, 200, true, 'Placement record fetched successfully', placement);
});

/**
 * @desc    Update a placement record (including status management)
 * @route   PUT /api/placements/:id
 * @access  Private/Admin
 */
const updatePlacement = asyncHandler(async (req, res, next) => {
  const allowedFields = [
    'company',
    'jobTitle',
    'package',
    'placementType',
    'location',
    'placementDate',
    'status',
    'remarks',
  ];

  const updates = {};
  allowedFields.forEach((field) => {
    if (req.body[field] !== undefined) updates[field] = req.body[field];
  });

  if (Object.keys(updates).length === 0) {
    return next(new ErrorResponse('No valid fields provided to update', 400));
  }

  const placement = await Placement.findByIdAndUpdate(req.params.id, updates, {
    new: true,
    runValidators: true,
  });

  if (!placement) {
    return next(new ErrorResponse(`Placement record not found with id ${req.params.id}`, 404));
  }

  if (updates.status) {
    await sendNotification({
      user: placement.student,
      title: 'Placement Status Updated',
      message: `Your placement record for ${placement.company} - ${placement.jobTitle} is now marked as '${updates.status}'.`,
      type: 'Placement',
      relatedModel: 'Placement',
      relatedId: placement._id,
      createdBy: req.user._id,
    });
  }

  return sendResponse(res, 200, true, 'Placement record updated successfully', placement);
});

/**
 * @desc    Delete a placement record
 * @route   DELETE /api/placements/:id
 * @access  Private/Admin
 */
const deletePlacement = asyncHandler(async (req, res, next) => {
  const placement = await Placement.findByIdAndDelete(req.params.id);

  if (!placement) {
    return next(new ErrorResponse(`Placement record not found with id ${req.params.id}`, 404));
  }

  return sendResponse(res, 200, true, 'Placement record deleted successfully');
});

/**
 * @desc    Get the logged-in student's own placement history
 * @route   GET /api/placements/me
 * @access  Private (Student, Alumni)
 */
const getMyPlacementHistory = asyncHandler(async (req, res) => {
  const placements = await Placement.find({ student: req.user._id })
    .populate('addedBy', 'name email')
    .sort({ createdAt: -1 });

  return sendResponse(res, 200, true, 'Your placement history fetched successfully', placements);
});

/**
 * @desc    Get a specific student's placement history (Admin only)
 * @route   GET /api/placements/student/:studentId
 * @access  Private/Admin
 */
const getStudentPlacementHistory = asyncHandler(async (req, res) => {
  const placements = await Placement.find({ student: req.params.studentId })
    .populate('addedBy', 'name email')
    .sort({ createdAt: -1 });

  return sendResponse(res, 200, true, "Student's placement history fetched successfully", placements);
});

module.exports = {
  createPlacement,
  getAllPlacements,
  getPlacementById,
  updatePlacement,
  deletePlacement,
  getMyPlacementHistory,
  getStudentPlacementHistory,
};
