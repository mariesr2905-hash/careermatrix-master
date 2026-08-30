const Notification = require('../models/Notification');

/**
 * Creates a single notification for one user.
 * Used both by the Notification module's controller and by other modules
 * (e.g. Mentorship, Placement) that need to notify a user of an event.
 *
 * Failures here are logged but never thrown, so a notification issue never
 * breaks the primary action (e.g. accepting a mentorship request) that
 * triggered it.
 *
 * @param {Object} params
 * @param {String} params.user - recipient user id (required)
 * @param {String} params.title - required
 * @param {String} params.message - required
 * @param {String} [params.type] - one of the Notification model's enum values
 * @param {String} [params.relatedModel] - e.g. 'MentorshipRequest'
 * @param {String} [params.relatedId] - id of the related document
 * @param {String} [params.createdBy] - admin/user id who triggered it
 */
const sendNotification = async ({
  user,
  title,
  message,
  type = 'Info',
  relatedModel,
  relatedId,
  createdBy,
}) => {
  try {
    if (!user || !title || !message) {
      console.warn('[notificationService] Missing required fields, skipping notification creation');
      return null;
    }

    const notification = await Notification.create({
      user,
      title,
      message,
      type,
      relatedModel,
      relatedId,
      createdBy,
    });

    return notification;
  } catch (error) {
    console.error(`[notificationService] Failed to create notification: ${error.message}`);
    return null;
  }
};

/**
 * Creates the same notification for multiple recipients at once (bulk insert).
 * Used for admin broadcasts.
 */
const sendBulkNotifications = async ({ users, title, message, type = 'Info', createdBy }) => {
  try {
    if (!Array.isArray(users) || users.length === 0 || !title || !message) {
      console.warn('[notificationService] Missing required fields, skipping bulk notification creation');
      return [];
    }

    const docs = users.map((userId) => ({
      user: userId,
      title,
      message,
      type,
      createdBy,
    }));

    return await Notification.insertMany(docs);
  } catch (error) {
    console.error(`[notificationService] Failed to create bulk notifications: ${error.message}`);
    return [];
  }
};

module.exports = { sendNotification, sendBulkNotifications };
