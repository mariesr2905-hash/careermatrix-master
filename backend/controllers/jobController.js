const Job = require('../models/Job');
const Internship = require('../models/Internship');
const JobApplication = require('../models/JobApplication');
const InternshipApplication = require('../models/InternshipApplication');
const Resume = require('../models/Resume');
const Skill = require('../models/Skill');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const { sendResponse } = require('../utils/apiResponse');
const { attachMatchScores } = require('../services/matchScoreService');

/**
 * @desc    Create a new job posting
 * @route   POST /api/jobs
 * @access  Private (Alumni, Admin)
 */
const createJob = asyncHandler(async (req, res) => {
  const {
    title,
    description,
    company,
    location,
    jobType,
    skillsRequired,
    experienceRequired,
    salaryRange,
    applicationDeadline,
  } = req.body;

  const job = await Job.create({
    title,
    description,
    company,
    location,
    jobType,
    skillsRequired,
    experienceRequired,
    salaryRange,
    applicationDeadline,
    postedBy: req.user._id,
  });

  return sendResponse(res, 201, true, 'Job posted successfully', job);
});

/**
 * @desc    Get all jobs with pagination, search, and filters
 *          Filters: company, location, skills (comma-separated), jobType, status
 *          Search: free-text keyword across title/description/company
 * @route   GET /api/jobs?page=1&limit=10&search=backend&company=Google&location=Remote&skills=Node.js,MongoDB&jobType=Full-time
 * @access  Private
 */
const getAllJobs = asyncHandler(async (req, res) => {
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
  if (req.query.jobType) {
    filter.jobType = req.query.jobType;
  }
  if (req.query.status) {
    filter.status = req.query.status;
  }
  if (req.query.search) {
    filter.$text = { $search: req.query.search };
  }

  const [jobs, total] = await Promise.all([
    Job.find(filter)
      .populate('postedBy', 'name email role')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit),
    Job.countDocuments(filter),
  ]);

  const userSkills = await Skill.find({ user: req.user._id }).distinct('skillName');
  const jobsWithMatch = attachMatchScores(jobs, userSkills);

  return sendResponse(res, 200, true, 'Jobs fetched successfully', jobsWithMatch, {
    pagination: { total, page, pages: Math.ceil(total / limit), limit },
  });
});

/**
 * @desc    Get a single job by ID
 * @route   GET /api/jobs/:id
 * @access  Private
 */
const getJobById = asyncHandler(async (req, res, next) => {
  const job = await Job.findById(req.params.id).populate('postedBy', 'name email role');

  if (!job) {
    return next(new ErrorResponse(`Job not found with id ${req.params.id}`, 404));
  }

  return sendResponse(res, 200, true, 'Job fetched successfully', job);
});

/**
 * @desc    Update a job (owner or admin only)
 * @route   PUT /api/jobs/:id
 * @access  Private (Owner/Admin)
 */
const updateJob = asyncHandler(async (req, res, next) => {
  const job = await Job.findById(req.params.id);

  if (!job) {
    return next(new ErrorResponse(`Job not found with id ${req.params.id}`, 404));
  }

  if (String(job.postedBy) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to update this job', 403));
  }

  const allowedFields = [
    'title',
    'description',
    'company',
    'location',
    'jobType',
    'skillsRequired',
    'experienceRequired',
    'salaryRange',
    'applicationDeadline',
    'status',
  ];

  allowedFields.forEach((field) => {
    if (req.body[field] !== undefined) job[field] = req.body[field];
  });

  await job.save();

  return sendResponse(res, 200, true, 'Job updated successfully', job);
});

/**
 * @desc    Delete a job (owner or admin only)
 * @route   DELETE /api/jobs/:id
 * @access  Private (Owner/Admin)
 */
const deleteJob = asyncHandler(async (req, res, next) => {
  const job = await Job.findById(req.params.id);

  if (!job) {
    return next(new ErrorResponse(`Job not found with id ${req.params.id}`, 404));
  }

  if (String(job.postedBy) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to delete this job', 403));
  }

  await JobApplication.deleteMany({ job: job._id });
  await job.deleteOne();

  return sendResponse(res, 200, true, 'Job deleted successfully');
});

/**
 * @desc    Apply for a job
 * @route   POST /api/jobs/:id/apply
 * @access  Private (Student, Alumni)
 */
const applyForJob = asyncHandler(async (req, res, next) => {
  const job = await Job.findById(req.params.id);

  if (!job) {
    return next(new ErrorResponse(`Job not found with id ${req.params.id}`, 404));
  }

  if (job.status !== 'Open') {
    return next(new ErrorResponse('This job is no longer accepting applications', 400));
  }

  if (job.applicationDeadline && job.applicationDeadline < new Date()) {
    return next(new ErrorResponse('The application deadline for this job has passed', 400));
  }

  const existing = await JobApplication.findOne({ job: job._id, applicant: req.user._id });
  if (existing) {
    return next(new ErrorResponse('You have already applied for this job', 400));
  }

  // Attach the applicant's existing resume path, if any
  const resume = await Resume.findOne({ user: req.user._id });

  const application = await JobApplication.create({
    job: job._id,
    applicant: req.user._id,
    coverLetter: req.body.coverLetter,
    resumePath: resume ? resume.filePath : undefined,
  });

  return sendResponse(res, 201, true, 'Application submitted successfully', application);
});

/**
 * @desc    Get the logged-in user's own job applications
 * @route   GET /api/jobs/applications/me
 * @access  Private
 */
const getMyApplications = asyncHandler(async (req, res) => {
  const applications = await JobApplication.find({ applicant: req.user._id })
    .populate('job', 'title company location status')
    .sort({ createdAt: -1 });

  return sendResponse(res, 200, true, 'Your applications fetched successfully', applications);
});

/**
 * @desc    Get all applicants for a specific job (owner or admin only)
 * @route   GET /api/jobs/:id/applicants
 * @access  Private (Owner/Admin)
 */
const getJobApplicants = asyncHandler(async (req, res, next) => {
  const job = await Job.findById(req.params.id);

  if (!job) {
    return next(new ErrorResponse(`Job not found with id ${req.params.id}`, 404));
  }

  if (String(job.postedBy) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to view applicants for this job', 403));
  }

  const applicants = await JobApplication.find({ job: job._id })
    .populate('applicant', 'name email role')
    .sort({ createdAt: -1 });

  return sendResponse(res, 200, true, 'Applicants fetched successfully', applicants);
});

/**
 * @desc    Aggregate stats for the logged-in company/alumni/admin's own
 *          postings (jobs + internships): active count and total
 *          applications received. Real, computed-from-Mongo data — not
 *          hardcoded frontend numbers.
 * @route   GET /api/jobs/stats/mine
 * @access  Private/Company,Alumni,Admin
 */
const getMyPostingStats = asyncHandler(async (req, res) => {
  const [jobIds, internshipIds] = await Promise.all([
    Job.find({ postedBy: req.user._id }).distinct('_id'),
    Internship.find({ postedBy: req.user._id }).distinct('_id'),
  ]);

  const [jobApplications, internshipApplications] = await Promise.all([
    JobApplication.countDocuments({ job: { $in: jobIds } }),
    InternshipApplication.countDocuments({ internship: { $in: internshipIds } }),
  ]);

  return sendResponse(res, 200, true, 'Posting stats fetched successfully', {
    activePostings: jobIds.length + internshipIds.length,
    totalApplications: jobApplications + internshipApplications,
  });
});

/**
 * @desc    Get all job applications (Admin only)
 * @route   GET /api/jobs/applications/admin/all
 * @access  Private/Admin
 */
const getAllApplicationsAdmin = asyncHandler(async (req, res) => {
  const applications = await JobApplication.find()
    .populate('applicant', 'name email role')
    .populate('job', 'title company location status')
    .sort({ createdAt: -1 });

  return sendResponse(res, 200, true, 'All job applications fetched successfully', applications);
});

/**
 * @desc    Update job application status (Admin or job owner)
 * @route   PUT /api/jobs/applications/:id/status
 * @access  Private (Owner/Admin)
 */
const updateApplicationStatusAdmin = asyncHandler(async (req, res, next) => {
  const { status } = req.body;
  const application = await JobApplication.findById(req.params.id).populate('job');

  if (!application) {
    return next(new ErrorResponse(`Job application not found with id ${req.params.id}`, 404));
  }

  if (application.job && String(application.job.postedBy) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to update this application status', 403));
  }

  application.status = status;
  await application.save();

  return sendResponse(res, 200, true, 'Application status updated successfully', application);
});

module.exports = {
  createJob,
  getAllJobs,
  getJobById,
  updateJob,
  deleteJob,
  applyForJob,
  getMyApplications,
  getJobApplicants,
  getMyPostingStats,
  getAllApplicationsAdmin,
  updateApplicationStatusAdmin,
};
