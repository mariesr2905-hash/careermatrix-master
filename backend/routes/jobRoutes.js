const express = require('express');
const {
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
} = require('../controllers/jobController');
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');
const { validate } = require('../middleware/validateMiddleware');
const {
  createJobValidator,
  updateJobValidator,
  jobIdValidator,
  applyJobValidator,
  getAllJobsValidator,
} = require('../validators/jobValidator');

const router = express.Router();

router.use(protect);

// @route   GET /api/jobs/applications/admin/all
router.get('/applications/admin/all', authorize('admin'), getAllApplicationsAdmin);

// @route   PUT /api/jobs/applications/:id/status
router.put('/applications/:id/status', updateApplicationStatusAdmin);

// @route   GET /api/jobs/applications/me
// NOTE: defined before /:id routes to avoid "applications" being parsed as an id
router.get('/applications/me', getMyApplications);

// @route   GET /api/jobs/stats/mine
// NOTE: defined before /:id routes to avoid "stats" being parsed as an id
router.get('/stats/mine', authorize('company', 'alumni', 'admin'), getMyPostingStats);

// @route   POST /api/jobs
router.post('/', authorize('alumni', 'company', 'admin'), createJobValidator, validate, createJob);

// @route   GET /api/jobs
router.get('/', getAllJobsValidator, validate, getAllJobs);

// @route   GET /api/jobs/:id
router.get('/:id', jobIdValidator, validate, getJobById);

// @route   PUT /api/jobs/:id
router.put('/:id', updateJobValidator, validate, updateJob);

// @route   DELETE /api/jobs/:id
router.delete('/:id', jobIdValidator, validate, deleteJob);

// @route   POST /api/jobs/:id/apply
router.post(
  '/:id/apply',
  authorize('student', 'alumni'),
  applyJobValidator,
  validate,
  applyForJob
);

// @route   GET /api/jobs/:id/applicants
router.get('/:id/applicants', jobIdValidator, validate, getJobApplicants);

module.exports = router;
