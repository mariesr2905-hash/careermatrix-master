const express = require('express');
const {
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
} = require('../controllers/internshipController');
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');
const { validate } = require('../middleware/validateMiddleware');
const {
  createInternshipValidator,
  updateInternshipValidator,
  internshipIdValidator,
  applyInternshipValidator,
  getAllInternshipsValidator,
} = require('../validators/internshipValidator');

const router = express.Router();

router.use(protect);

// @route   GET /api/internships/applications/admin/all
router.get('/applications/admin/all', authorize('admin'), getAllInternshipApplicationsAdmin);

// @route   PUT /api/internships/applications/:id/status
router.put('/applications/:id/status', updateInternshipApplicationStatusAdmin);

// @route   GET /api/internships/applications/me
router.get('/applications/me', getMyApplications);

// @route   POST /api/internships
router.post('/', authorize('alumni', 'company', 'admin'), createInternshipValidator, validate, createInternship);

// @route   GET /api/internships
router.get('/', getAllInternshipsValidator, validate, getAllInternships);

// @route   GET /api/internships/:id
router.get('/:id', internshipIdValidator, validate, getInternshipById);

// @route   PUT /api/internships/:id
router.put('/:id', updateInternshipValidator, validate, updateInternship);

// @route   DELETE /api/internships/:id
router.delete('/:id', internshipIdValidator, validate, deleteInternship);

// @route   POST /api/internships/:id/apply
router.post(
  '/:id/apply',
  authorize('student', 'alumni'),
  applyInternshipValidator,
  validate,
  applyForInternship
);

// @route   GET /api/internships/:id/applicants
router.get('/:id/applicants', internshipIdValidator, validate, getInternshipApplicants);

module.exports = router;
