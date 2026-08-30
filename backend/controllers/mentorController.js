const Mentor = require('../models/Mentor');
const Booking = require('../models/Booking');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const { sendResponse } = require('../utils/apiResponse');

/**
 * @desc    Register the logged-in alumni user as a mentor
 * @route   POST /api/mentors/register
 * @access  Private (Alumni)
 */
const registerMentor = asyncHandler(async (req, res, next) => {
  const existing = await Mentor.findOne({ user: req.user._id });
  if (existing) {
    return next(new ErrorResponse('You are already registered as a mentor', 400));
  }

  const { expertise, experienceYears, bio, currentCompany, currentPosition, availableSlots } =
    req.body;

  const mentor = await Mentor.create({
    user: req.user._id,
    expertise,
    experienceYears,
    bio,
    currentCompany,
    currentPosition,
    availableSlots,
  });

  return sendResponse(res, 201, true, 'Mentor registration successful', mentor);
});

/**
 * @desc    Get all active mentors (optionally filter by expertise)
 * @route   GET /api/mentors?expertise=React&page=1&limit=10
 * @access  Private
 */
const getAllMentors = asyncHandler(async (req, res) => {
  const page = Math.max(Number(req.query.page) || 1, 1);
  const limit = Math.min(Number(req.query.limit) || 10, 100);
  const skip = (page - 1) * limit;

  const filter = { isActive: true };
  if (req.query.expertise) {
    filter.expertise = { $regex: req.query.expertise, $options: 'i' };
  }

  const [mentors, total] = await Promise.all([
    Mentor.find(filter)
      .populate('user', 'name email role')
      .sort({ rating: -1, createdAt: -1 })
      .skip(skip)
      .limit(limit),
    Mentor.countDocuments(filter),
  ]);

  return sendResponse(res, 200, true, 'Mentors fetched successfully', mentors, {
    pagination: { total, page, pages: Math.ceil(total / limit), limit },
  });
});

/**
 * @desc    Get a mentor's public profile by mentor ID
 * @route   GET /api/mentors/:id
 * @access  Private
 */
const getMentorProfile = asyncHandler(async (req, res, next) => {
  const mentor = await Mentor.findById(req.params.id).populate('user', 'name email role');

  if (!mentor) {
    return next(new ErrorResponse(`Mentor not found with id ${req.params.id}`, 404));
  }

  return sendResponse(res, 200, true, 'Mentor profile fetched successfully', mentor);
});

/**
 * @desc    Get the logged-in user's own mentor profile
 * @route   GET /api/mentors/me/profile
 * @access  Private (Mentor)
 */
const getMyMentorProfile = asyncHandler(async (req, res, next) => {
  const mentor = await Mentor.findOne({ user: req.user._id }).populate('user', 'name email role');

  if (!mentor) {
    return next(new ErrorResponse('You are not registered as a mentor', 404));
  }

  return sendResponse(res, 200, true, 'Mentor profile fetched successfully', mentor);
});

/**
 * @desc    Update the logged-in user's own mentor profile
 * @route   PUT /api/mentors/me/profile
 * @access  Private (Mentor)
 */
const updateMentorProfile = asyncHandler(async (req, res, next) => {
  const allowedFields = [
    'expertise',
    'experienceYears',
    'bio',
    'currentCompany',
    'currentPosition',
    'availableSlots',
    'isActive',
  ];

  const updates = {};
  allowedFields.forEach((field) => {
    if (req.body[field] !== undefined) updates[field] = req.body[field];
  });

  const mentor = await Mentor.findOneAndUpdate({ user: req.user._id }, updates, {
    new: true,
    runValidators: true,
  });

  if (!mentor) {
    return next(new ErrorResponse('You are not registered as a mentor', 404));
  }

  return sendResponse(res, 200, true, 'Mentor profile updated successfully', mentor);
});

/**
 * @desc    Book a session with a mentor
 * @route   POST /api/mentors/:id/book
 * @access  Private (Student, Alumni)
 */
const bookMentorSession = asyncHandler(async (req, res, next) => {
  const mentor = await Mentor.findById(req.params.id);

  if (!mentor) {
    return next(new ErrorResponse(`Mentor not found with id ${req.params.id}`, 404));
  }

  if (!mentor.isActive) {
    return next(new ErrorResponse('This mentor is not currently accepting bookings', 400));
  }

  if (String(mentor.user) === String(req.user._id)) {
    return next(new ErrorResponse('You cannot book a session with yourself', 400));
  }

  const { sessionDate, sessionTime, topic } = req.body;

  const booking = await Booking.create({
    mentor: mentor._id,
    student: req.user._id,
    sessionDate,
    sessionTime,
    topic,
  });

  return sendResponse(res, 201, true, 'Mentor session booked successfully', booking);
});

/**
 * @desc    Cancel a booking (student who booked it, the mentor, or admin)
 * @route   PUT /api/mentors/bookings/:bookingId/cancel
 * @access  Private
 */
const cancelBooking = asyncHandler(async (req, res, next) => {
  const booking = await Booking.findById(req.params.bookingId).populate('mentor');

  if (!booking) {
    return next(new ErrorResponse(`Booking not found with id ${req.params.bookingId}`, 404));
  }

  const isStudent = String(booking.student) === String(req.user._id);
  const isMentor = booking.mentor && String(booking.mentor.user) === String(req.user._id);
  const isAdmin = req.user.role === 'admin';

  if (!isStudent && !isMentor && !isAdmin) {
    return next(new ErrorResponse('Not authorized to cancel this booking', 403));
  }

  if (booking.status === 'Cancelled') {
    return next(new ErrorResponse('This booking is already cancelled', 400));
  }

  if (booking.status === 'Completed') {
    return next(new ErrorResponse('A completed session cannot be cancelled', 400));
  }

  booking.status = 'Cancelled';
  booking.cancellationReason = req.body.cancellationReason;
  await booking.save();

  return sendResponse(res, 200, true, 'Booking cancelled successfully', booking);
});

/**
 * @desc    Get the logged-in user's booking history
 *          (sessions booked as a student, and — if they are a mentor — sessions received)
 * @route   GET /api/mentors/bookings/history
 * @access  Private
 */
const getBookingHistory = asyncHandler(async (req, res) => {
  const studentBookings = await Booking.find({ student: req.user._id })
    .populate({ path: 'mentor', populate: { path: 'user', select: 'name email' } })
    .sort({ createdAt: -1 });

  const mentorProfile = await Mentor.findOne({ user: req.user._id });

  let mentorBookings = [];
  if (mentorProfile) {
    mentorBookings = await Booking.find({ mentor: mentorProfile._id })
      .populate('student', 'name email')
      .sort({ createdAt: -1 });
  }

  return sendResponse(res, 200, true, 'Booking history fetched successfully', {
    asStudent: studentBookings,
    asMentor: mentorBookings,
  });
});

/**
 * @desc    Get all session bookings across the platform (Admin only)
 * @route   GET /api/mentors/bookings/admin/all
 * @access  Private/Admin
 */
const getAllBookingsAdmin = asyncHandler(async (req, res) => {
  const bookings = await Booking.find()
    .populate('student', 'name email role')
    .populate({ path: 'mentor', populate: { path: 'user', select: 'name email role' } })
    .sort({ createdAt: -1 });

  return sendResponse(res, 200, true, 'All bookings fetched successfully', bookings);
});

module.exports = {
  registerMentor,
  getAllMentors,
  getMentorProfile,
  getMyMentorProfile,
  updateMentorProfile,
  bookMentorSession,
  cancelBooking,
  getBookingHistory,
  getAllBookingsAdmin,
};
