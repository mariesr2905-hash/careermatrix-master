const express = require('express');
const {
  createMentorshipRequest,
  getMentorshipRequests,
  acceptMentorshipRequest,
  rejectMentorshipRequest,
  cancelMentorshipRequest,
  getMentorshipHistory,
  getAllMentorshipRequestsAdmin,
} = require('../controllers/mentorshipController');
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');
const { validate } = require('../middleware/validateMiddleware');
const {
  createRequestValidator,
  requestIdValidator,
  respondRequestValidator,
  getRequestsValidator,
} = require('../validators/mentorshipValidator');

const router = express.Router();

router.use(protect);

// @route   GET /api/mentorship/admin/all  (must be before /:id routes)
router.get('/admin/all', authorize('admin'), getAllMentorshipRequestsAdmin);

// @route   GET /api/mentorship/history
// NOTE: defined before /:id routes to avoid "history" being parsed as an id
router.get('/history', getMentorshipHistory);

// @route   POST /api/mentorship/:mentorId/request
router.post(
  '/:mentorId/request',
  authorize('student', 'alumni'),
  createRequestValidator,
  validate,
  createMentorshipRequest
);

// @route   GET /api/mentorship
router.get('/', getRequestsValidator, validate, getMentorshipRequests);

// @route   PUT /api/mentorship/:id/accept
router.put('/:id/accept', respondRequestValidator, validate, acceptMentorshipRequest);

// @route   PUT /api/mentorship/:id/reject
router.put('/:id/reject', respondRequestValidator, validate, rejectMentorshipRequest);

// @route   PUT /api/mentorship/:id/cancel
router.put('/:id/cancel', requestIdValidator, validate, cancelMentorshipRequest);

module.exports = router;
