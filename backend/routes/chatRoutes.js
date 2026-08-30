const express = require('express');
const {
  createConversation,
  getConversations,
  sendMessage,
  getConversationMessages,
  markMessagesAsRead,
  deleteMessage,
} = require('../controllers/chatController');
const { protect } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validateMiddleware');
const {
  createConversationValidator,
  conversationIdValidator,
  sendMessageValidator,
  messageIdValidator,
  paginationValidator,
} = require('../validators/chatValidator');

const router = express.Router();

router.use(protect);

// @route   POST /api/chat/conversations
router.post('/conversations', createConversationValidator, validate, createConversation);

// @route   GET /api/chat/conversations
router.get('/conversations', paginationValidator, validate, getConversations);

// @route   POST /api/chat/conversations/:id/messages
router.post('/conversations/:id/messages', sendMessageValidator, validate, sendMessage);

// @route   GET /api/chat/conversations/:id/messages
router.get(
  '/conversations/:id/messages',
  conversationIdValidator,
  paginationValidator,
  validate,
  getConversationMessages
);

// @route   PUT /api/chat/conversations/:id/read
router.put('/conversations/:id/read', conversationIdValidator, validate, markMessagesAsRead);

// @route   DELETE /api/chat/messages/:messageId
router.delete('/messages/:messageId', messageIdValidator, validate, deleteMessage);

module.exports = router;
