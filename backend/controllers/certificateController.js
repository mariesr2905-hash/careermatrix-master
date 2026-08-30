const fs = require('fs');
const path = require('path');
const Certificate = require('../models/Certificate');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const { sendResponse } = require('../utils/apiResponse');

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
 * @desc    Add a new certificate for the logged-in user (multipart upload)
 * @route   POST /api/certificates
 * @access  Private
 */
const addCertificate = asyncHandler(async (req, res, next) => {
  if (!req.file) {
    return next(new ErrorResponse('Please upload a certificate file (PDF, JPG or PNG)', 400));
  }

  const { title, issuer, issueDate } = req.body;

  const certificate = await Certificate.create({
    user: req.user._id,
    title,
    issuer,
    issueDate: issueDate || undefined,
    fileName: req.file.filename,
    originalName: req.file.originalname,
    filePath: req.file.path,
    fileSize: req.file.size,
    mimeType: req.file.mimetype,
  });

  return sendResponse(res, 201, true, 'Certificate added successfully', certificate);
});

/**
 * @desc    Update certificate details (owner only). Optionally replaces the file.
 * @route   PUT /api/certificates/:id
 * @access  Private
 */
const updateCertificate = asyncHandler(async (req, res, next) => {
  let certificate = await Certificate.findById(req.params.id);

  if (!certificate) {
    return next(new ErrorResponse(`Certificate not found with id ${req.params.id}`, 404));
  }

  if (String(certificate.user) !== String(req.user._id) && req.user.role !== 'admin') {
    if (req.file) safeUnlink(req.file.path);
    return next(new ErrorResponse('Not authorized to update this certificate', 403));
  }

  const { title, issuer, issueDate } = req.body;
  if (title !== undefined) certificate.title = title;
  if (issuer !== undefined) certificate.issuer = issuer;
  if (issueDate !== undefined) certificate.issueDate = issueDate;

  if (req.file) {
    safeUnlink(certificate.filePath);
    certificate.fileName = req.file.filename;
    certificate.originalName = req.file.originalname;
    certificate.filePath = req.file.path;
    certificate.fileSize = req.file.size;
    certificate.mimeType = req.file.mimetype;
  }

  await certificate.save();

  return sendResponse(res, 200, true, 'Certificate updated successfully', certificate);
});

/**
 * @desc    Delete a certificate (owner only)
 * @route   DELETE /api/certificates/:id
 * @access  Private
 */
const deleteCertificate = asyncHandler(async (req, res, next) => {
  const certificate = await Certificate.findById(req.params.id);

  if (!certificate) {
    return next(new ErrorResponse(`Certificate not found with id ${req.params.id}`, 404));
  }

  if (String(certificate.user) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to delete this certificate', 403));
  }

  safeUnlink(certificate.filePath);
  await certificate.deleteOne();

  return sendResponse(res, 200, true, 'Certificate deleted successfully');
});

/**
 * @desc    Get all certificates for the logged-in user
 * @route   GET /api/certificates/me
 * @access  Private
 */
const getMyCertificates = asyncHandler(async (req, res) => {
  const certificates = await Certificate.find({ user: req.user._id }).sort({ createdAt: -1 });
  return sendResponse(res, 200, true, 'Certificates fetched successfully', certificates);
});

/**
 * @desc    Download/view the logged-in user's own certificate file
 * @route   GET /api/certificates/:id/download
 * @access  Private
 */
const downloadCertificate = asyncHandler(async (req, res, next) => {
  const certificate = await Certificate.findById(req.params.id);

  if (!certificate) {
    return next(new ErrorResponse('Certificate not found', 404));
  }

  if (String(certificate.user) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to view this certificate', 403));
  }

  const filePath = path.resolve(certificate.filePath);
  if (!fs.existsSync(filePath)) {
    return next(new ErrorResponse('Certificate file is missing from the server', 404));
  }

  return res.download(filePath, certificate.originalName);
});

module.exports = {
  addCertificate,
  updateCertificate,
  deleteCertificate,
  getMyCertificates,
  downloadCertificate,
};
