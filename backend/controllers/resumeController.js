const fs = require('fs');
const path = require('path');
const Resume = require('../models/Resume');
const Skill = require('../models/Skill');
const Profile = require('../models/Profile');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const { sendResponse } = require('../utils/apiResponse');
const { generateResumeAnalysis } = require('../services/aiRecommendationService');

/**
 * Removes a file from disk if it exists, silently ignoring errors.
 */
const safeUnlink = (filePath) => {
  if (!filePath) return;
  const resolved = path.resolve(filePath);
  fs.access(resolved, fs.constants.F_OK, (err) => {
    if (!err) fs.unlink(resolved, () => {});
  });
};

/**
 * @desc    Upload a resume (PDF) for the logged-in user
 * @route   POST /api/resume/upload
 * @access  Private
 */
const uploadResume = asyncHandler(async (req, res, next) => {
  if (!req.file) {
    return next(new ErrorResponse('Please upload a PDF resume file', 400));
  }

  const existing = await Resume.findOne({ user: req.user._id });
  if (existing) {
    safeUnlink(req.file.path); // clean up the newly uploaded file
    return next(
      new ErrorResponse('A resume already exists for this user. Use update instead.', 400)
    );
  }

  const resume = await Resume.create({
    user: req.user._id,
    fileName: req.file.filename,
    originalName: req.file.originalname,
    filePath: req.file.path,
    fileSize: req.file.size,
    mimeType: req.file.mimetype,
  });

  return sendResponse(res, 201, true, 'Resume uploaded successfully', resume);
});

/**
 * @desc    Replace the logged-in user's existing resume
 * @route   PUT /api/resume/update
 * @access  Private
 */
const updateResume = asyncHandler(async (req, res, next) => {
  if (!req.file) {
    return next(new ErrorResponse('Please upload a PDF resume file', 400));
  }

  const resume = await Resume.findOne({ user: req.user._id });

  if (!resume) {
    safeUnlink(req.file.path);
    return next(new ErrorResponse('No existing resume found. Please upload one first.', 404));
  }

  // Remove old file from disk
  safeUnlink(resume.filePath);

  resume.fileName = req.file.filename;
  resume.originalName = req.file.originalname;
  resume.filePath = req.file.path;
  resume.fileSize = req.file.size;
  resume.mimeType = req.file.mimetype;
  await resume.save();

  return sendResponse(res, 200, true, 'Resume updated successfully', resume);
});

/**
 * @desc    Delete the logged-in user's resume
 * @route   DELETE /api/resume
 * @access  Private
 */
const deleteResume = asyncHandler(async (req, res, next) => {
  const resume = await Resume.findOne({ user: req.user._id });

  if (!resume) {
    return next(new ErrorResponse('No resume found for this user', 404));
  }

  safeUnlink(resume.filePath);
  await resume.deleteOne();

  return sendResponse(res, 200, true, 'Resume deleted successfully');
});

/**
 * @desc    Download the logged-in user's own resume
 * @route   GET /api/resume/download
 * @access  Private
 */
const downloadOwnResume = asyncHandler(async (req, res, next) => {
  const resume = await Resume.findOne({ user: req.user._id });

  if (!resume) {
    return next(new ErrorResponse('No resume found for this user', 404));
  }

  const filePath = path.resolve(resume.filePath);
  if (!fs.existsSync(filePath)) {
    return next(new ErrorResponse('Resume file is missing from the server', 404));
  }

  return res.download(filePath, resume.originalName);
});

/**
 * @desc    Download a specific user's resume (e.g. recruiter/admin viewing an applicant)
 * @route   GET /api/resume/download/:userId
 * @access  Private
 */
const downloadResumeByUserId = asyncHandler(async (req, res, next) => {
  const resume = await Resume.findOne({ user: req.params.userId });

  if (!resume) {
    return next(new ErrorResponse('No resume found for this user', 404));
  }

  const filePath = path.resolve(resume.filePath);
  if (!fs.existsSync(filePath)) {
    return next(new ErrorResponse('Resume file is missing from the server', 404));
  }

  return res.download(filePath, resume.originalName);
});

/**
 * @desc    Get metadata about the logged-in user's resume (filename,
 *          size, upload date) without downloading the file bytes.
 * @route   GET /api/resume/me
 * @access  Private
 */
const getMyResumeMeta = asyncHandler(async (req, res, next) => {
  const resume = await Resume.findOne({ user: req.user._id });
  if (!resume) {
    return next(new ErrorResponse('No resume found. Please upload one first.', 404));
  }
  return sendResponse(res, 200, true, 'Resume metadata fetched successfully', {
    fileName: resume.originalName || resume.fileName,
    fileSizeBytes: resume.fileSize,
    uploadedAt: resume.createdAt,
    updatedAt: resume.updatedAt,
  });
});

/**
 * @desc    Deterministic resume analysis computed from the user's actual
 *          resume/skills/profile data (real backend logic, not mock data).
 * @route   GET /api/resume/analysis
 * @access  Private
 */
const getResumeAnalysis = asyncHandler(async (req, res) => {
  const [resume, skills, profile] = await Promise.all([
    Resume.findOne({ user: req.user._id }),
    Skill.find({ user: req.user._id }),
    Profile.findOne({ user: req.user._id }),
  ]);

  const analysis = generateResumeAnalysis({ hasResume: !!resume, skills, profile });
  return sendResponse(res, 200, true, 'Resume analysis generated successfully', analysis);
});

module.exports = {
  uploadResume,
  updateResume,
  deleteResume,
  downloadOwnResume,
  downloadResumeByUserId,
  getMyResumeMeta,
  getResumeAnalysis,
};
