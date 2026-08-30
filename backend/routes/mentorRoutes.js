const express = require('express');
const {
  registerMentor,
  getAllMentors,
  getMentorProfile,
  getMyMentorProfile,
  updateMentorProfile,
  bookMentorSession,
  cancelBooking,
  getBookingHistory,
  getAllBookingsAdmin,
} = require('../controllers/mentorController');
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');
const { validate } = require('../middleware/validateMiddleware');
const {
  registerMentorValidator,
  updateMentorValidator,
  mentorIdValidator,
  bookSessionValidator,
  cancelBookingValidator,
  paginationValidator,
} = require('../validators/mentorValidator');

const router = express.Router();

router.use(protect);

// ---------------- Static/fixed routes first (avoid clashing with /:id) ----------------

// @route   POST /api/mentors/register
router.post('/register', authorize('alumni', 'mentor', 'admin'), registerMentorValidator, validate, registerMentor);

// @route   GET /api/mentors/me/profile
router.get('/me/profile', getMyMentorProfile);

// @route   PUT /api/mentors/me/profile
router.put('/me/profile', updateMentorValidator, validate, updateMentorProfile);

// @route   GET /api/mentors/bookings/admin/all  (BEFORE /bookings/history to avoid route clash)
router.get('/bookings/admin/all', authorize('admin'), getAllBookingsAdmin);

// @route   GET /api/mentors/bookings/history
router.get('/bookings/history', getBookingHistory);

// @route   PUT /api/mentors/bookings/:bookingId/cancel
router.put(
  '/bookings/:bookingId/cancel',
  cancelBookingValidator,
  validate,
  cancelBooking
);

// ---------------- General mentor routes ----------------

// @route   GET /api/mentors
router.get('/', paginationValidator, validate, getAllMentors);

// @route   GET /api/mentors/:id
router.get('/:id', mentorIdValidator, validate, getMentorProfile);

// @route   POST /api/mentors/:id/book
router.post(
  '/:id/book',
  authorize('student', 'alumni'),
  bookSessionValidator,
  validate,
  bookMentorSession
);

module.exports = router;
