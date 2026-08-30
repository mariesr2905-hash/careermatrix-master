const { body, param, query } = require('express-validator');

const createPostValidator = [
  body('content')
    .trim()
    .notEmpty()
    .withMessage('Post content is required')
    .isLength({ max: 2000 })
    .withMessage('Post content cannot exceed 2000 characters'),
];

const updatePostValidator = [
  param('id').isMongoId().withMessage('Invalid post id'),
  body('content')
    .trim()
    .notEmpty()
    .withMessage('Post content is required')
    .isLength({ max: 2000 })
    .withMessage('Post content cannot exceed 2000 characters'),
];

const postIdValidator = [param('id').isMongoId().withMessage('Invalid post id')];

const commentValidator = [
  param('id').isMongoId().withMessage('Invalid post id'),
  body('content')
    .trim()
    .notEmpty()
    .withMessage('Comment content is required')
    .isLength({ max: 500 })
    .withMessage('Comment cannot exceed 500 characters'),
];

const commentIdValidator = [param('commentId').isMongoId().withMessage('Invalid comment id')];

const paginationValidator = [
  query('page').optional().isInt({ min: 1 }).withMessage('page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('limit must be between 1 and 100'),
];

module.exports = {
  createPostValidator,
  updatePostValidator,
  postIdValidator,
  commentValidator,
  commentIdValidator,
  paginationValidator,
};
