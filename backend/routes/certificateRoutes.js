const express = require('express');
const { body, param } = require('express-validator');
const {
  addCertificate,
  updateCertificate,
  deleteCertificate,
  getMyCertificates,
  downloadCertificate,
} = require('../controllers/certificateController');
const { protect } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validateMiddleware');
const { uploadCertificate: uploadCertificateMiddleware } = require('../middleware/uploadMiddleware');

const router = express.Router();

router.use(protect);

// @route   POST /api/certificates
router.post(
  '/',
  uploadCertificateMiddleware.single('certificate'),
  [body('title').trim().notEmpty().withMessage('Certificate title is required')],
  validate,
  addCertificate
);

// @route   GET /api/certificates/me
router.get('/me', getMyCertificates);

// @route   GET /api/certificates/:id/download
router.get(
  '/:id/download',
  [param('id').isMongoId().withMessage('Invalid certificate id')],
  validate,
  downloadCertificate
);

// @route   PUT /api/certificates/:id
router.put(
  '/:id',
  uploadCertificateMiddleware.single('certificate'),
  [
    param('id').isMongoId().withMessage('Invalid certificate id'),
    body('title').optional().trim().notEmpty().withMessage('Certificate title cannot be empty'),
  ],
  validate,
  updateCertificate
);

// @route   DELETE /api/certificates/:id
router.delete(
  '/:id',
  [param('id').isMongoId().withMessage('Invalid certificate id')],
  validate,
  deleteCertificate
);

module.exports = router;
