const MentorshipRequest = require('../models/MentorshipRequest');
const Mentor = require('../models/Mentor');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const { sendResponse } = require('../utils/apiResponse');
const { sendNotification } = require('../services/notificationService');

/**
 * @desc    Create a mentorship request to a mentor
 * @route   POST /api/mentorship/:mentorId/request
 * @access  Private (Student, Alumni)
 */
const createMentorshipRequest = asyncHandler(async (req, res, next) => {
  const mentor = await Mentor.findById(req.params.mentorId);

  if (!mentor) {
    return next(new ErrorResponse(`Mentor not found with id ${req.params.mentorId}`, 404));
  }

  if (!mentor.isActive) {
    return next(new ErrorResponse('This mentor is not currently accepting mentorship requests', 400));
  }

  if (String(mentor.user) === String(req.user._id)) {
    return next(new ErrorResponse('You cannot send a mentorship request to yourself', 400));
  }

  const existingPending = await MentorshipRequest.findOne({
    requester: req.user._id,
    mentor: mentor._id,
    status: { $in: ['Pending', 'Accepted'] },
  });

  if (existingPending) {
    return next(
      new ErrorResponse(
        `You already have a ${existingPending.status.toLowerCase()} mentorship request with this mentor`,
        400
      )
    );
  }

  const mentorshipRequest = await MentorshipRequest.create({
    requester: req.user._id,
    mentor: mentor._id,
    message: req.body.message,
  });

  await sendNotification({
    user: mentor.user,
    title: 'New Mentorship Request',
    message: `${req.user.name} has sent you a mentorship request.`,
    type: 'MentorshipRequest',
    relatedModel: 'MentorshipRequest',
    relatedId: mentorshipRequest._id,
  });

  return sendResponse(res, 201, true, 'Mentorship request sent successfully', mentorshipRequest);
});

/**
 * @desc    Get mentorship requests for the logged-in user.
 *          role=sent -> requests you sent as a requester
 *          role=received -> requests sent to you as a mentor
 *          (omit role to get both, grouped)
 * @route   GET /api/mentorship?role=sent&status=Pending&page=1&limit=10
 * @access  Private
 */
const getMentorshipRequests = asyncHandler(async (req, res) => {
  const page = Math.max(Number(req.query.page) || 1, 1);
  const limit = Math.min(Number(req.query.limit) || 10, 100);
  const skip = (page - 1) * limit;

  const statusFilter = req.query.status ? { status: req.query.status } : {};

  const mentorProfile = await Mentor.findOne({ user: req.user._id });

  const buildQuery = (filter) =>
    MentorshipRequest.find(filter)
      .populate('requester', 'name email role')
      .populate({ path: 'mentor', populate: { path: 'user', select: 'name email role' } })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

  if (req.query.role === 'sent') {
    const filter = { requester: req.user._id, ...statusFilter };
    const [requests, total] = await Promise.all([
      buildQuery(filter),
      MentorshipRequest.countDocuments(filter),
    ]);
    return sendResponse(res, 200, true, 'Sent mentorship requests fetched successfully', requests, {
      pagination: { total, page, pages: Math.ceil(total / limit), limit },
    });
  }

  if (req.query.role === 'received') {
    if (!mentorProfile) {
      return sendResponse(res, 200, true, 'Received mentorship requests fetched successfully', []);
    }
    const filter = { mentor: mentorProfile._id, ...statusFilter };
    const [requests, total] = await Promise.all([
      buildQuery(filter),
      MentorshipRequest.countDocuments(filter),
    ]);
    return sendResponse(res, 200, true, 'Received mentorship requests fetched successfully', requests, {
      pagination: { total, page, pages: Math.ceil(total / limit), limit },
    });
  }

  // No role specified -> return both groups
  const sentFilter = { requester: req.user._id, ...statusFilter };
  const receivedFilter = mentorProfile ? { mentor: mentorProfile._id, ...statusFilter } : null;

  const [sent, received] = await Promise.all([
    MentorshipRequest.find(sentFilter)
      .populate({ path: 'mentor', populate: { path: 'user', select: 'name email role' } })
      .sort({ createdAt: -1 }),
    receivedFilter
      ? MentorshipRequest.find(receivedFilter)
        .populate('requester', 'name email role')
        .sort({ createdAt: -1 })
      : Promise.resolve([]),
  ]);

  return sendResponse(res, 200, true, 'Mentorship requests fetched successfully', { sent, received });
});

/**
 * @desc    Accept a mentorship request (mentor only)
 * @route   PUT /api/mentorship/:id/accept
 * @access  Private (Mentor - owner of the mentor profile)
 */
const acceptMentorshipRequest = asyncHandler(async (req, res, next) => {
  const request = await MentorshipRequest.findById(req.params.id).populate('mentor');

  if (!request) {
    return next(new ErrorResponse(`Mentorship request not found with id ${req.params.id}`, 404));
  }

  if (String(request.mentor.user) !== String(req.user._id)) {
    return next(new ErrorResponse('Not authorized to respond to this mentorship request', 403));
  }

  if (request.status !== 'Pending') {
    return next(new ErrorResponse(`This request has already been ${request.status.toLowerCase()}`, 400));
  }

  request.status = 'Accepted';
  request.respondedAt = new Date();
  request.responseNote = req.body.responseNote;
  await request.save();

  await sendNotification({
    user: request.requester,
    title: 'Mentorship Request Accepted',
    message: `${req.user.name} has accepted your mentorship request.`,
    type: 'MentorshipRequest',
    relatedModel: 'MentorshipRequest',
    relatedId: request._id,
  });

  return sendResponse(res, 200, true, 'Mentorship request accepted', request);
});

/**
 * @desc    Reject a mentorship request (mentor only)
 * @route   PUT /api/mentorship/:id/reject
 * @access  Private (Mentor - owner of the mentor profile)
 */
const rejectMentorshipRequest = asyncHandler(async (req, res, next) => {
  const request = await MentorshipRequest.findById(req.params.id).populate('mentor');

  if (!request) {
    return next(new ErrorResponse(`Mentorship request not found with id ${req.params.id}`, 404));
  }

  if (String(request.mentor.user) !== String(req.user._id)) {
    return next(new ErrorResponse('Not authorized to respond to this mentorship request', 403));
  }

  if (request.status !== 'Pending') {
    return next(new ErrorResponse(`This request has already been ${request.status.toLowerCase()}`, 400));
  }

  request.status = 'Rejected';
  request.respondedAt = new Date();
  request.responseNote = req.body.responseNote;
  await request.save();

  await sendNotification({
    user: request.requester,
    title: 'Mentorship Request Declined',
    message: `${req.user.name} was unable to accept your mentorship request at this time.`,
    type: 'MentorshipRequest',
    relatedModel: 'MentorshipRequest',
    relatedId: request._id,
  });

  return sendResponse(res, 200, true, 'Mentorship request rejected', request);
});

/**
 * @desc    Cancel a mentorship request (requester only). Allowed while
 *          Pending, or to end an already Accepted mentorship.
 * @route   PUT /api/mentorship/:id/cancel
 * @access  Private (Requester)
 */
const cancelMentorshipRequest = asyncHandler(async (req, res, next) => {
  const request = await MentorshipRequest.findById(req.params.id).populate('mentor');

  if (!request) {
    return next(new ErrorResponse(`Mentorship request not found with id ${req.params.id}`, 404));
  }

  if (String(request.requester) !== String(req.user._id)) {
    return next(new ErrorResponse('Not authorized to cancel this mentorship request', 403));
  }

  if (!['Pending', 'Accepted'].includes(request.status)) {
    return next(new ErrorResponse(`This request cannot be cancelled from status '${request.status}'`, 400));
  }

  request.status = 'Cancelled';
  request.respondedAt = new Date();
  await request.save();

  if (request.mentor) {
    await sendNotification({
      user: request.mentor.user,
      title: 'Mentorship Request Cancelled',
      message: `${req.user.name} has cancelled their mentorship request.`,
      type: 'MentorshipRequest',
      relatedModel: 'MentorshipRequest',
      relatedId: request._id,
    });
  }

  return sendResponse(res, 200, true, 'Mentorship request cancelled', request);
});

/**
 * @desc    Get the logged-in user's full mentorship history
 *          (as requester and, if applicable, as mentor), regardless of status
 * @route   GET /api/mentorship/history
 * @access  Private
 */
const getMentorshipHistory = asyncHandler(async (req, res) => {
  const mentorProfile = await Mentor.findOne({ user: req.user._id });

  const [asRequester, asMentor] = await Promise.all([
    MentorshipRequest.find({ requester: req.user._id })
      .populate({ path: 'mentor', populate: { path: 'user', select: 'name email role' } })
      .sort({ createdAt: -1 }),
    mentorProfile
      ? MentorshipRequest.find({ mentor: mentorProfile._id })
        .populate('requester', 'name email role')
        .sort({ createdAt: -1 })
      : Promise.resolve([]),
  ]);

  return sendResponse(res, 200, true, 'Mentorship history fetched successfully', {
    asRequester,
    asMentor,
  });
});

/**
 * @desc    Get ALL mentorship requests across the platform (Admin only)
 * @route   GET /api/mentorship/admin/all
 * @access  Private/Admin
 */
const getAllMentorshipRequestsAdmin = asyncHandler(async (req, res) => {
  const page = Math.max(Number(req.query.page) || 1, 1);
  const limit = Math.min(Number(req.query.limit) || 50, 200);
  const skip = (page - 1) * limit;

  const filter = {};
  if (req.query.status) filter.status = req.query.status;

  const [requests, total] = await Promise.all([
    MentorshipRequest.find(filter)
      .populate('requester', 'name email role')
      .populate({ path: 'mentor', populate: { path: 'user', select: 'name email role' } })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit),
    MentorshipRequest.countDocuments(filter),
  ]);

  return sendResponse(res, 200, true, 'All mentorship requests fetched successfully', requests, {
    pagination: { total, page, pages: Math.ceil(total / limit), limit },
  });
});

module.exports = {
  createMentorshipRequest,
  getMentorshipRequests,
  acceptMentorshipRequest,
  rejectMentorshipRequest,
  cancelMentorshipRequest,
  getMentorshipHistory,
  getAllMentorshipRequestsAdmin,
};
