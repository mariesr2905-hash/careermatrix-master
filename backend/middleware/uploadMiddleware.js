const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

// Ensure upload directories exist at startup
const profileDir = process.env.PROFILE_IMAGE_UPLOAD_PATH || './uploads/profiles';
const resumeDir = process.env.RESUME_UPLOAD_PATH || './uploads/resumes';
const certificateDir = process.env.CERTIFICATE_UPLOAD_PATH || './uploads/certificates';
[profileDir, resumeDir, certificateDir].forEach((dir) => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

/**
 * Generates a collision-safe filename: <userId>-<randomHex>-<timestamp><ext>
 */
const generateFileName = (req, file) => {
  const ext = path.extname(file.originalname).toLowerCase();
  const random = crypto.randomBytes(8).toString('hex');
  const userId = req.user ? req.user._id : 'anonymous';
  return `${userId}-${Date.now()}-${random}${ext}`;
};

// ---------- Profile Image Storage ----------
const profileImageStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, profileDir),
  filename: (req, file, cb) => cb(null, generateFileName(req, file)),
});

const profileImageFilter = (req, file, cb) => {
  const allowedTypes = /jpeg|jpg|png|webp/;
  const extValid = allowedTypes.test(path.extname(file.originalname).toLowerCase());

  if (extValid) {
    return cb(null, true);
  }
  const err = new Error('Only JPEG, JPG, PNG, or WEBP images are allowed');
  err.statusCode = 400;
  cb(err);
};

const uploadProfileImage = multer({
  storage: profileImageStorage,
  fileFilter: profileImageFilter,
  limits: {
    fileSize: Number(process.env.MAX_PROFILE_IMAGE_SIZE) || 2 * 1024 * 1024, // 2MB default
  },
});

// ---------- Resume (PDF) Storage ----------
const resumeStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, resumeDir),
  filename: (req, file, cb) => cb(null, generateFileName(req, file)),
});

const resumeFilter = (req, file, cb) => {
  const isPdfExt = path.extname(file.originalname).toLowerCase() === '.pdf';

  if (isPdfExt) {
    return cb(null, true);
  }
  const err = new Error('Only PDF files are allowed for resumes');
  err.statusCode = 400;
  cb(err);
};

const uploadResume = multer({
  storage: resumeStorage,
  fileFilter: resumeFilter,
  limits: {
    fileSize: Number(process.env.MAX_RESUME_SIZE) || 5 * 1024 * 1024, // 5MB default
  },
});

// ---------- Certificate (PDF/Image) Storage ----------
const certificateStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, certificateDir),
  filename: (req, file, cb) => cb(null, generateFileName(req, file)),
});

const certificateFilter = (req, file, cb) => {
  const allowedTypes = /pdf|jpeg|jpg|png/;
  const extValid = allowedTypes.test(path.extname(file.originalname).toLowerCase());

  if (extValid) {
    return cb(null, true);
  }
  const err = new Error('Only PDF, JPEG, JPG, or PNG files are allowed');
  err.statusCode = 400;
  cb(err);
};

const uploadCertificate = multer({
  storage: certificateStorage,
  fileFilter: certificateFilter,
  limits: {
    fileSize: Number(process.env.MAX_CERTIFICATE_SIZE) || 5 * 1024 * 1024, // 5MB default
  },
});

module.exports = { uploadProfileImage, uploadResume, uploadCertificate };
