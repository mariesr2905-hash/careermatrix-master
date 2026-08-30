const Notification = require('../models/Notification');
const User = require('../models/User');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const { sendResponse } = require('../utils/apiResponse');
const { sendNotification, sendBulkNotifications } = require('../services/notificationService');

/**
 * @desc    Create a notification for a specific user (Admin only)
 * @route   POST /api/notifications
 * @access  Private/Admin
 */
const createNotification = asyncHandler(async (req, res, next) => {
  const { userId, title, message, type } = req.body;

  const targetUser = await User.findById(userId);
  if (!targetUser) {
    return next(new ErrorResponse(`User not found with id ${userId}`, 404));
  }

  const notification = await sendNotification({
    user: userId,
    title,
    message,
    type,
    createdBy: req.user._id,
  });

  if (!notification) {
    return next(new ErrorResponse('Failed to create notification', 500));
  }

  return sendResponse(res, 201, true, 'Notification created successfully', notification);
});

/**
 * @desc    Broadcast a notification to all users of a role (or all users) — Admin only
 * @route   POST /api/notifications/broadcast
 * @access  Private/Admin
 */
const broadcastNotification = asyncHandler(async (req, res, next) => {
  const { role, title, message, type } = req.body;

  const filter = role === 'all' ? {} : { role };
  const users = await User.find(filter).select('_id');

  if (users.length === 0) {
    return next(new ErrorResponse('No matching users found to notify', 404));
  }

  const notifications = await sendBulkNotifications({
    users: users.map((u) => u._id),
    title,
    message,
    type,
    createdBy: req.user._id,
  });

  return sendResponse(res, 201, true, `Notification broadcast to ${notifications.length} user(s)`, {
    count: notifications.length,
  });
});

/**
 * @desc    Get the logged-in user's own notifications (paginated, filterable)
 * @route   GET /api/notifications/me?page=1&limit=10&isRead=false&type=JobAlert
 * @access  Private
 */
const getUserNotifications = asyncHandler(async (req, res) => {
  const page = Math.max(Number(req.query.page) || 1, 1);
  const limit = Math.min(Number(req.query.limit) || 10, 100);
  const skip = (page - 1) * limit;

  const filter = { user: req.user._id };
  if (req.query.isRead !== undefined) filter.isRead = req.query.isRead === 'true';
  if (req.query.type) filter.type = req.query.type;

  const [notifications, total, unreadCount] = await Promise.all([
    Notification.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
    Notification.countDocuments(filter),
    Notification.countDocuments({ user: req.user._id, isRead: false }),
  ]);

  return sendResponse(res, 200, true, 'Notifications fetched successfully', notifications, {
    pagination: { total, page, pages: Math.ceil(total / limit), limit },
    unreadCount,
  });
});

/**
 * @desc    Mark a single notification as read (owner only)
 * @route   PUT /api/notifications/:id/read
 * @access  Private
 */
const markAsRead = asyncHandler(async (req, res, next) => {
  const notification = await Notification.findById(req.params.id);

  if (!notification) {
    return next(new ErrorResponse(`Notification not found with id ${req.params.id}`, 404));
  }

  if (String(notification.user) !== String(req.user._id)) {
    return next(new ErrorResponse('Not authorized to update this notification', 403));
  }

  notification.isRead = true;
  await notification.save();

  return sendResponse(res, 200, true, 'Notification marked as read', notification);
});

/**
 * @desc    Mark all of the logged-in user's notifications as read
 * @route   PUT /api/notifications/read-all
 * @access  Private
 */
const markAllAsRead = asyncHandler(async (req, res) => {
  const result = await Notification.updateMany(
    { user: req.user._id, isRead: false },
    { $set: { isRead: true } }
  );

  return sendResponse(res, 200, true, 'All notifications marked as read', {
    modifiedCount: result.modifiedCount,
  });
});

/**
 * @desc    Delete a notification (owner or admin)
 * @route   DELETE /api/notifications/:id
 * @access  Private
 */
const deleteNotification = asyncHandler(async (req, res, next) => {
  const notification = await Notification.findById(req.params.id);

  if (!notification) {
    return next(new ErrorResponse(`Notification not found with id ${req.params.id}`, 404));
  }

  if (String(notification.user) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to delete this notification', 403));
  }

  await notification.deleteOne();

  return sendResponse(res, 200, true, 'Notification deleted successfully');
});

module.exports = {
  createNotification,
  broadcastNotification,
  getUserNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
};
