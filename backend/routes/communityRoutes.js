const express = require('express');
const {
  createPost,
  getAllPosts,
  getPostById,
  updatePost,
  deletePost,
  likePost,
  commentOnPost,
  getPostComments,
  deleteComment,
} = require('../controllers/communityController');
const { protect } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validateMiddleware');
const {
  createPostValidator,
  updatePostValidator,
  postIdValidator,
  commentValidator,
  commentIdValidator,
  paginationValidator,
} = require('../validators/communityValidator');

const router = express.Router();

router.use(protect);

// @route   POST /api/community/posts
router.post('/posts', createPostValidator, validate, createPost);

// @route   GET /api/community/posts
router.get('/posts', paginationValidator, validate, getAllPosts);

// @route   GET /api/community/posts/:id
router.get('/posts/:id', postIdValidator, validate, getPostById);

// @route   PUT /api/community/posts/:id
router.put('/posts/:id', updatePostValidator, validate, updatePost);

// @route   DELETE /api/community/posts/:id
router.delete('/posts/:id', postIdValidator, validate, deletePost);

// @route   PUT /api/community/posts/:id/like
router.put('/posts/:id/like', postIdValidator, validate, likePost);

// @route   POST /api/community/posts/:id/comments
router.post('/posts/:id/comments', commentValidator, validate, commentOnPost);

// @route   GET /api/community/posts/:id/comments
router.get('/posts/:id/comments', postIdValidator, validate, getPostComments);

// @route   DELETE /api/community/comments/:commentId
router.delete('/comments/:commentId', commentIdValidator, validate, deleteComment);

module.exports = router;
