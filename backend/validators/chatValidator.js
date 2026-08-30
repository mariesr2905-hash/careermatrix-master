const { body, param, query } = require('express-validator');

const createConversationValidator = [
  body('participantId').isMongoId().withMessage('A valid participantId is required'),
];

const conversationIdValidator = [param('id').isMongoId().withMessage('Invalid conversation id')];

const sendMessageValidator = [
  param('id').isMongoId().withMessage('Invalid conversation id'),
  body('content')
    .trim()
    .notEmpty()
    .withMessage('Message content is required')
    .isLength({ max: 2000 })
    .withMessage('Message cannot exceed 2000 characters'),
];

const messageIdValidator = [param('messageId').isMongoId().withMessage('Invalid message id')];

const paginationValidator = [
  query('page').optional().isInt({ min: 1 }).withMessage('page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('limit must be between 1 and 100'),
];

module.exports = {
  createConversationValidator,
  conversationIdValidator,
  sendMessageValidator,
  messageIdValidator,
  paginationValidator,
};
