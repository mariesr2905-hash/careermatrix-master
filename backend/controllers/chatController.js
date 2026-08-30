const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const User = require('../models/User');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const { sendResponse } = require('../utils/apiResponse');
const { sendNotification } = require('../services/notificationService');

/**
 * Ensures the logged-in user is a participant of the given conversation.
 * Throws a 403 via next() otherwise. Returns the conversation document.
 */
const getConversationOrFail = async (conversationId, userId, next) => {
  const conversation = await Conversation.findById(conversationId);

  if (!conversation) {
    next(new ErrorResponse(`Conversation not found with id ${conversationId}`, 404));
    return null;
  }

  const isParticipant = conversation.participants.some((p) => String(p) === String(userId));
  if (!isParticipant) {
    next(new ErrorResponse('Not authorized to access this conversation', 403));
    return null;
  }

  return conversation;
};

/**
 * @desc    Create a new conversation with another user, or return the
 *          existing one if it already exists between the two participants.
 * @route   POST /api/chat/conversations
 * @access  Private (Student, Alumni, Mentor-as-Alumni, Admin)
 */
const createConversation = asyncHandler(async (req, res, next) => {
  const { participantId } = req.body;

  if (String(participantId) === String(req.user._id)) {
    return next(new ErrorResponse('You cannot start a conversation with yourself', 400));
  }

  const participant = await User.findById(participantId);
  if (!participant) {
    return next(new ErrorResponse(`User not found with id ${participantId}`, 404));
  }

  let conversation = await Conversation.findOne({
    participants: { $all: [req.user._id, participantId], $size: 2 },
  });

  if (conversation) {
    return sendResponse(res, 200, true, 'Conversation already exists', conversation);
  }

  conversation = await Conversation.create({
    participants: [req.user._id, participantId],
  });

  return sendResponse(res, 201, true, 'Conversation created successfully', conversation);
});

/**
 * @desc    Get all conversations for the logged-in user, most recent first
 * @route   GET /api/chat/conversations?page=1&limit=10
 * @access  Private
 */
const getConversations = asyncHandler(async (req, res) => {
  const page = Math.max(Number(req.query.page) || 1, 1);
  const limit = Math.min(Number(req.query.limit) || 10, 100);
  const skip = (page - 1) * limit;

  const filter = { participants: req.user._id };

  const [conversations, total] = await Promise.all([
    Conversation.find(filter)
      .populate('participants', 'name email role')
      .populate('lastMessage')
      .sort({ lastMessageAt: -1 })
      .skip(skip)
      .limit(limit),
    Conversation.countDocuments(filter),
  ]);

  return sendResponse(res, 200, true, 'Conversations fetched successfully', conversations, {
    pagination: { total, page, pages: Math.ceil(total / limit), limit },
  });
});

/**
 * @desc    Send a message in a conversation
 * @route   POST /api/chat/conversations/:id/messages
 * @access  Private (Participant only)
 */
const sendMessage = asyncHandler(async (req, res, next) => {
  const conversation = await getConversationOrFail(req.params.id, req.user._id, next);
  if (!conversation) return;

  const message = await Message.create({
    conversation: conversation._id,
    sender: req.user._id,
    content: req.body.content,
    readBy: [req.user._id],
  });

  conversation.lastMessage = message._id;
  conversation.lastMessageAt = message.createdAt;
  await conversation.save();

  const recipientId = conversation.participants.find((p) => String(p) !== String(req.user._id));
  if (recipientId) {
    await sendNotification({
      user: recipientId,
      title: 'New Message',
      message: `${req.user.name} sent you a new message.`,
      type: 'Info',
      relatedModel: 'Conversation',
      relatedId: conversation._id,
    });
  }

  return sendResponse(res, 201, true, 'Message sent successfully', message);
});

/**
 * @desc    Get all messages in a conversation, most recent first
 * @route   GET /api/chat/conversations/:id/messages?page=1&limit=20
 * @access  Private (Participant only)
 */
const getConversationMessages = asyncHandler(async (req, res, next) => {
  const conversation = await getConversationOrFail(req.params.id, req.user._id, next);
  if (!conversation) return;

  const page = Math.max(Number(req.query.page) || 1, 1);
  const limit = Math.min(Number(req.query.limit) || 20, 100);
  const skip = (page - 1) * limit;

  const [messages, total] = await Promise.all([
    Message.find({ conversation: conversation._id })
      .populate('sender', 'name email role')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit),
    Message.countDocuments({ conversation: conversation._id }),
  ]);

  return sendResponse(res, 200, true, 'Messages fetched successfully', messages, {
    pagination: { total, page, pages: Math.ceil(total / limit), limit },
  });
});

/**
 * @desc    Mark all unread messages in a conversation as read by the logged-in user
 * @route   PUT /api/chat/conversations/:id/read
 * @access  Private (Participant only)
 */
const markMessagesAsRead = asyncHandler(async (req, res, next) => {
  const conversation = await getConversationOrFail(req.params.id, req.user._id, next);
  if (!conversation) return;

  const result = await Message.updateMany(
    {
      conversation: conversation._id,
      sender: { $ne: req.user._id },
      readBy: { $ne: req.user._id },
    },
    { $addToSet: { readBy: req.user._id } }
  );

  return sendResponse(res, 200, true, 'Messages marked as read', {
    modifiedCount: result.modifiedCount,
  });
});

/**
 * @desc    Delete a message (sender only)
 * @route   DELETE /api/chat/messages/:messageId
 * @access  Private (Sender only)
 */
const deleteMessage = asyncHandler(async (req, res, next) => {
  const message = await Message.findById(req.params.messageId);

  if (!message) {
    return next(new ErrorResponse(`Message not found with id ${req.params.messageId}`, 404));
  }

  if (String(message.sender) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to delete this message', 403));
  }

  const conversationId = message.conversation;
  await message.deleteOne();

  // If the deleted message was the conversation's lastMessage, point it to
  // the next most recent remaining message (or null if none remain).
  const conversation = await Conversation.findById(conversationId);
  if (conversation && String(conversation.lastMessage) === String(req.params.messageId)) {
    const previous = await Message.findOne({ conversation: conversationId }).sort({ createdAt: -1 });
    conversation.lastMessage = previous ? previous._id : null;
    conversation.lastMessageAt = previous ? previous.createdAt : conversation.updatedAt;
    await conversation.save();
  }

  return sendResponse(res, 200, true, 'Message deleted successfully');
});

module.exports = {
  createConversation,
  getConversations,
  sendMessage,
  getConversationMessages,
  markMessagesAsRead,
  deleteMessage,
};
