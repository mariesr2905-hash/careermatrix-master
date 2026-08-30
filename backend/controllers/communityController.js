const Post = require('../models/Post');
const Comment = require('../models/Comment');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const { sendResponse } = require('../utils/apiResponse');

/**
 * @desc    Create a new community post
 * @route   POST /api/community/posts
 * @access  Private
 */
const createPost = asyncHandler(async (req, res) => {
  const post = await Post.create({
    user: req.user._id,
    content: req.body.content,
  });

  return sendResponse(res, 201, true, 'Post created successfully', post);
});

/**
 * @desc    Get all posts (paginated, most recent first)
 * @route   GET /api/community/posts?page=1&limit=10
 * @access  Private
 */
const getAllPosts = asyncHandler(async (req, res) => {
  const page = Math.max(Number(req.query.page) || 1, 1);
  const limit = Math.min(Number(req.query.limit) || 10, 100);
  const skip = (page - 1) * limit;

  const [posts, total] = await Promise.all([
    Post.find()
      .populate('user', 'name role')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit),
    Post.countDocuments(),
  ]);

  return sendResponse(res, 200, true, 'Posts fetched successfully', posts, {
    pagination: { total, page, pages: Math.ceil(total / limit), limit },
  });
});

/**
 * @desc    Get a single post by ID
 * @route   GET /api/community/posts/:id
 * @access  Private
 */
const getPostById = asyncHandler(async (req, res, next) => {
  const post = await Post.findById(req.params.id).populate('user', 'name role');

  if (!post) {
    return next(new ErrorResponse(`Post not found with id ${req.params.id}`, 404));
  }

  return sendResponse(res, 200, true, 'Post fetched successfully', post);
});

/**
 * @desc    Update a post (owner only)
 * @route   PUT /api/community/posts/:id
 * @access  Private (Owner)
 */
const updatePost = asyncHandler(async (req, res, next) => {
  const post = await Post.findById(req.params.id);

  if (!post) {
    return next(new ErrorResponse(`Post not found with id ${req.params.id}`, 404));
  }

  if (String(post.user) !== String(req.user._id)) {
    return next(new ErrorResponse('Not authorized to update this post', 403));
  }

  post.content = req.body.content;
  await post.save();

  return sendResponse(res, 200, true, 'Post updated successfully', post);
});

/**
 * @desc    Delete a post (owner or admin) — also removes its comments
 * @route   DELETE /api/community/posts/:id
 * @access  Private (Owner/Admin)
 */
const deletePost = asyncHandler(async (req, res, next) => {
  const post = await Post.findById(req.params.id);

  if (!post) {
    return next(new ErrorResponse(`Post not found with id ${req.params.id}`, 404));
  }

  if (String(post.user) !== String(req.user._id) && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to delete this post', 403));
  }

  await Comment.deleteMany({ post: post._id });
  await post.deleteOne();

  return sendResponse(res, 200, true, 'Post deleted successfully');
});

/**
 * @desc    Like or unlike a post (toggle)
 * @route   PUT /api/community/posts/:id/like
 * @access  Private
 */
const likePost = asyncHandler(async (req, res, next) => {
  const post = await Post.findById(req.params.id);

  if (!post) {
    return next(new ErrorResponse(`Post not found with id ${req.params.id}`, 404));
  }

  const alreadyLiked = post.likes.some((id) => String(id) === String(req.user._id));

  if (alreadyLiked) {
    post.likes = post.likes.filter((id) => String(id) !== String(req.user._id));
  } else {
    post.likes.push(req.user._id);
  }

  await post.save();

  return sendResponse(res, 200, true, alreadyLiked ? 'Post unliked' : 'Post liked', {
    likesCount: post.likes.length,
    liked: !alreadyLiked,
  });
});

/**
 * @desc    Add a comment to a post
 * @route   POST /api/community/posts/:id/comments
 * @access  Private
 */
const commentOnPost = asyncHandler(async (req, res, next) => {
  const post = await Post.findById(req.params.id);

  if (!post) {
    return next(new ErrorResponse(`Post not found with id ${req.params.id}`, 404));
  }

  const comment = await Comment.create({
    post: post._id,
    user: req.user._id,
    content: req.body.content,
  });

  post.commentsCount += 1;
  await post.save();

  return sendResponse(res, 201, true, 'Comment added successfully', comment);
});

/**
 * @desc    Get all comments for a post
 * @route   GET /api/community/posts/:id/comments
 * @access  Private
 */
const getPostComments = asyncHandler(async (req, res, next) => {
  const post = await Post.findById(req.params.id);

  if (!post) {
    return next(new ErrorResponse(`Post not found with id ${req.params.id}`, 404));
  }

  const comments = await Comment.find({ post: post._id })
    .populate('user', 'name role')
    .sort({ createdAt: -1 });

  return sendResponse(res, 200, true, 'Comments fetched successfully', comments);
});

/**
 * @desc    Delete a comment (owner of the comment, post owner, or admin)
 * @route   DELETE /api/community/comments/:commentId
 * @access  Private
 */
const deleteComment = asyncHandler(async (req, res, next) => {
  const comment = await Comment.findById(req.params.commentId);

  if (!comment) {
    return next(new ErrorResponse(`Comment not found with id ${req.params.commentId}`, 404));
  }

  const post = await Post.findById(comment.post);

  const isCommentOwner = String(comment.user) === String(req.user._id);
  const isPostOwner = post && String(post.user) === String(req.user._id);
  const isAdmin = req.user.role === 'admin';

  if (!isCommentOwner && !isPostOwner && !isAdmin) {
    return next(new ErrorResponse('Not authorized to delete this comment', 403));
  }

  await comment.deleteOne();

  if (post) {
    post.commentsCount = Math.max(0, post.commentsCount - 1);
    await post.save();
  }

  return sendResponse(res, 200, true, 'Comment deleted successfully');
});

module.exports = {
  createPost,
  getAllPosts,
  getPostById,
  updatePost,
  deletePost,
  likePost,
  commentOnPost,
  getPostComments,
  deleteComment,
};
