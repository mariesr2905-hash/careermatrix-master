const Internship = require('../models/Internship');
const InternshipApplication = require('../models/InternshipApplication');
const Resume = require('../models/Resume');
const Skill = require('../models/Skill');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const { sendResponse } = require('../utils/apiResponse');
const { attachMatchScores } = require('../services/matchScoreService');

/**
 * @desc    Create a new internship posting
 * @route   POST /api/internships
 * @access  Private (Alumni, Admin)
 */
const createInternship = asyncHandler(async (req, res) => {
  const {
    title,
    description,
    company,
    location,
    duration,
    stipend,
    skillsRequired,
    applicationDeadline,
  } = req.body;

  const internship = await Internship.create({
    title,
    description,
    company,
    location,
    duration,
    stipend,
    skillsRequired,
    applicationDeadline,
    postedBy: req.user._id,
  });

  return sendResponse(res, 201, true, 'Internship posted successfully', internship);
});

/**
 * @desc    Get all internships with pagination, search, and filters
 * @route   GET /api/internships?page=1&limit=10&search=frontend&company=Acme&location=Remote&skills=React
 * @access  Private
 */
const getAllInternships = asyncHandler(async (req, res) => {
  const page = Math.max(Number(req.query.page) || 1, 1);
  const limit = Math.min(Number(req.query.limit) || 10, 100);
  const skip = (page - 1) * limit;

  const filter = {};

  if (req.query.postedByMe === 'true') {
    filter.postedBy = req.user._id;
  }
  if (req.query.company) {
    filter.company = { $regex: req.query.company, $options: 'i' };
  }
  if (req.query.location) {
    filter.location = { $regex: req.query.location, $options: 'i' };
  }
  if (req.query.skills) {
    const skillsArray = req.query.skills.split(',').map((s) => s.trim());
    filter.skillsRequired = { $in: skillsArray.map((s) => new RegExp(`^${s}$`, 'i')) };
  }
  if (req.query.status) {
    filter.status = req.query.status;
  }
  if (req.query.search) {
    filter.$text = { $search: req.query.search };
  }

  const [internships, total] = await Promise.all([
    Internship.find(filter)
      .populate('postedBy', 'name email role')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit),
    Internship.countDocuments(filter),
  ]);

  const userSkills = await Skill.find({ user: req.user._id }).distinct('skillName');
  const internshipsWithMatch = attachMatchScores(internships, userSkills);

  return sendResponse(res, 200, true, 'Internships fetched successfully', internshipsWithMatch, {
    pagination: { total, page, pages: Math.ceil(total / limit), limit },
  });
});

/**
 * @desc    Get a single internship by ID
 * @route   GET /api/internships/:id
 * @access  Private
 */
const getInternshipById = asyncHandler(async (req, res, next) => {
  const internship = await Internship.findById(req.params.id).populate(
    'postedBy',
    'name email role'
  );

  if (!internship) {
    return next(new ErrorResponse(`Internship not found with id ${req.params.id}`, 404));
  }

  return sendResponse(res, 200, true, 'Internship fetched successfully', internship);
});

/**
 * @desc    Update an internship (owner or admin only)
 * @route   PUT /api/internships/:id
 * @access  Private (Owner/Admin)
 */
const updateInternship = asyncHandler(async (req, res, next) => {
  const internship = await Internship.findById(req.params.id);

  if (!internship) {
    return next(new ErrorResponse(`Internship not found with id ${req.params.id}`, 404));
  }

  if (String(internship.postedBy) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to update this internship', 403));
  }

  const allowedFields = [
    'title',
    'description',
    'company',
    'location',
    'duration',
    'stipend',
    'skillsRequired',
    'applicationDeadline',
    'status',
  ];

  allowedFields.forEach((field) => {
    if (req.body[field] !== undefined) internship[field] = req.body[field];
  });

  await internship.save();

  return sendResponse(res, 200, true, 'Internship updated successfully', internship);
});

/**
 * @desc    Delete an internship (owner or admin only)
 * @route   DELETE /api/internships/:id
 * @access  Private (Owner/Admin)
 */
const deleteInternship = asyncHandler(async (req, res, next) => {
  const internship = await Internship.findById(req.params.id);

  if (!internship) {
    return next(new ErrorResponse(`Internship not found with id ${req.params.id}`, 404));
  }

  if (String(internship.postedBy) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to delete this internship', 403));
  }

  await InternshipApplication.deleteMany({ internship: internship._id });
  await internship.deleteOne();

  return sendResponse(res, 200, true, 'Internship deleted successfully');
});

/**
 * @desc    Apply for an internship
 * @route   POST /api/internships/:id/apply
 * @access  Private (Student, Alumni)
 */
const applyForInternship = asyncHandler(async (req, res, next) => {
  const internship = await Internship.findById(req.params.id);

  if (!internship) {
    return next(new ErrorResponse(`Internship not found with id ${req.params.id}`, 404));
  }

  if (internship.status !== 'Open') {
    return next(new ErrorResponse('This internship is no longer accepting applications', 400));
  }

  if (internship.applicationDeadline && internship.applicationDeadline < new Date()) {
    return next(new ErrorResponse('The application deadline for this internship has passed', 400));
  }

  const existing = await InternshipApplication.findOne({
    internship: internship._id,
    applicant: req.user._id,
  });
  if (existing) {
    return next(new ErrorResponse('You have already applied for this internship', 400));
  }

  const resume = await Resume.findOne({ user: req.user._id });

  const application = await InternshipApplication.create({
    internship: internship._id,
    applicant: req.user._id,
    coverLetter: req.body.coverLetter,
    resumePath: resume ? resume.filePath : undefined,
  });

  return sendResponse(res, 201, true, 'Application submitted successfully', application);
});

/**
 * @desc    Get the logged-in user's own internship applications
 * @route   GET /api/internships/applications/me
 * @access  Private
 */
const getMyApplications = asyncHandler(async (req, res) => {
  const applications = await InternshipApplication.find({ applicant: req.user._id })
    .populate('internship', 'title company location status')
    .sort({ createdAt: -1 });

  return sendResponse(res, 200, true, 'Your applications fetched successfully', applications);
});

/**
 * @desc    Get all applicants for a specific internship (owner or admin only)
 * @route   GET /api/internships/:id/applicants
 * @access  Private (Owner/Admin)
 */
const getInternshipApplicants = asyncHandler(async (req, res, next) => {
  const internship = await Internship.findById(req.params.id);

  if (!internship) {
    return next(new ErrorResponse(`Internship not found with id ${req.params.id}`, 404));
  }

  if (String(internship.postedBy) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to view applicants for this internship', 403));
  }

  const applicants = await InternshipApplication.find({ internship: internship._id })
    .populate('applicant', 'name email role')
    .sort({ createdAt: -1 });

  return sendResponse(res, 200, true, 'Applicants fetched successfully', applicants);
});

/**
 * @desc    Get all internship applications (Admin only)
 * @route   GET /api/internships/applications/admin/all
 * @access  Private/Admin
 */
const getAllInternshipApplicationsAdmin = asyncHandler(async (req, res) => {
  const applications = await InternshipApplication.find()
    .populate('applicant', 'name email role')
    .populate('internship', 'title company location status')
    .sort({ createdAt: -1 });

  return sendResponse(res, 200, true, 'All internship applications fetched successfully', applications);
});

/**
 * @desc    Update internship application status (Admin or owner)
 * @route   PUT /api/internships/applications/:id/status
 * @access  Private (Owner/Admin)
 */
const updateInternshipApplicationStatusAdmin = asyncHandler(async (req, res, next) => {
  const { status } = req.body;
  const application = await InternshipApplication.findById(req.params.id).populate('internship');

  if (!application) {
    return next(new ErrorResponse(`Internship application not found with id ${req.params.id}`, 404));
  }

  if (
    application.internship &&
    String(application.internship.postedBy) !== String(req.user._id) &&
    req.user.role !== 'admin'
  ) {
    return next(new ErrorResponse('Not authorized to update this application status', 403));
  }

  application.status = status;
  await application.save();

  return sendResponse(res, 200, true, 'Internship application status updated successfully', application);
});

module.exports = {
  createInternship,
  getAllInternships,
  getInternshipById,
  updateInternship,
  deleteInternship,
  applyForInternship,
  getMyApplications,
  getInternshipApplicants,
  getAllInternshipApplicationsAdmin,
  updateInternshipApplicationStatusAdmin,
};
