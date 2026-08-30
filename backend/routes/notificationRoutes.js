const express = require('express');
const {
  createNotification,
  broadcastNotification,
  getUserNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
} = require('../controllers/notificationController');
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');
const { validate } = require('../middleware/validateMiddleware');
const {
  createNotificationValidator,
  broadcastNotificationValidator,
  notificationIdValidator,
  getNotificationsValidator,
} = require('../validators/notificationValidator');

const router = express.Router();

router.use(protect);

// @route   GET /api/notifications/me
router.get('/me', getNotificationsValidator, validate, getUserNotifications);

// @route   PUT /api/notifications/read-all
router.put('/read-all', markAllAsRead);

// @route   POST /api/notifications  (Admin - notify a specific user)
router.post('/', authorize('admin'), createNotificationValidator, validate, createNotification);

// @route   POST /api/notifications/broadcast  (Admin - notify all users of a role)
router.post(
  '/broadcast',
  authorize('admin'),
  broadcastNotificationValidator,
  validate,
  broadcastNotification
);

// @route   PUT /api/notifications/:id/read
router.put('/:id/read', notificationIdValidator, validate, markAsRead);

// @route   DELETE /api/notifications/:id
router.delete('/:id', notificationIdValidator, validate, deleteNotification);

module.exports = router;
