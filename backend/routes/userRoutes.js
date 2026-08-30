const express = require('express');
const { body, param } = require('express-validator');
const multer = require('multer');
const {
  getAllUsers,
  getUserById,
  createUser,
  updateUser,
  deleteUser,
  getCandidates,
  getDashboardStats,
  getAdminUserDetails,
  getExcelTemplate,
  validateExcelImport,
  confirmExcelImport,
  bulkUpdateStatus,
} = require('../controllers/userController');
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');
const { validate } = require('../middleware/validateMiddleware');

const upload = multer({ dest: 'uploads/' });
const router = express.Router();

// @route   GET /api/users/candidates
// NOTE: defined before the admin-only block below so company/alumni users
// (not just admins) can browse candidates.
router.get('/candidates', protect, authorize('company', 'alumni', 'admin'), getCandidates);

// All routes below require authentication + admin role
router.use(protect, authorize('admin'));

// @route   GET /api/users/admin/dashboard-stats
router.get('/admin/dashboard-stats', getDashboardStats);

// @route   GET /api/users/admin/excel/template/:role
router.get('/admin/excel/template/:role', getExcelTemplate);

// @route   POST /api/users/admin/excel/validate
router.post('/admin/excel/validate', upload.single('file'), validateExcelImport);

// @route   POST /api/users/admin/excel/import
router.post('/admin/excel/import', confirmExcelImport);

// @route   PUT /api/users/admin/bulk-status
router.put('/admin/bulk-status', bulkUpdateStatus);

// @route   GET /api/users
router.get('/', getAllUsers);

// @route   POST /api/users
// Admin creates a Student/Alumni/Mentor/Company/Admin account directly.
// Uses the same User model + bcrypt hashing as /api/auth/register.
router.post(
  '/',
  [
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('email').isEmail().withMessage('Please provide a valid email').normalizeEmail(),
    body('password')
      .isLength({ min: 8 })
      .withMessage('Password must be at least 8 characters long'),
    body('role')
      .optional()
      .isIn(['student', 'alumni', 'mentor', 'company', 'admin', 'STUDENT', 'ALUMNI', 'MENTOR', 'COMPANY', 'ADMIN'])
      .withMessage('Role must be student, alumni, mentor, company, or admin'),
  ],
  validate,
  createUser
);

// @route   GET /api/users/:id/admin-details
router.get(
  '/:id/admin-details',
  [param('id').isMongoId().withMessage('Invalid user id')],
  validate,
  getAdminUserDetails
);

// @route   GET /api/users/:id
router.get(
  '/:id',
  [param('id').isMongoId().withMessage('Invalid user id')],
  validate,
  getUserById
);

// @route   PUT /api/users/:id
router.put(
  '/:id',
  [
    param('id').isMongoId().withMessage('Invalid user id'),
    body('email').optional().isEmail().withMessage('Please provide a valid email'),
    body('role')
      .optional()
      .isIn(['student', 'alumni', 'mentor', 'company', 'admin', 'STUDENT', 'ALUMNI', 'MENTOR', 'COMPANY', 'ADMIN'])
      .withMessage('Role must be student, alumni, mentor, company, or admin'),
    body('status')
      .optional()
      .isIn(['PENDING', 'APPROVED', 'REJECTED', 'ACTIVE', 'DEACTIVATED'])
      .withMessage('Status must be PENDING, APPROVED, REJECTED, ACTIVE, or DEACTIVATED'),
    body('isActive').optional().isBoolean().withMessage('isActive must be a boolean'),
    body('isApproved').optional().isBoolean().withMessage('isApproved must be a boolean'),
  ],
  validate,
  updateUser
);

// @route   DELETE /api/users/:id
router.delete(
  '/:id',
  [param('id').isMongoId().withMessage('Invalid user id')],
  validate,
  deleteUser
);

module.exports = router;
