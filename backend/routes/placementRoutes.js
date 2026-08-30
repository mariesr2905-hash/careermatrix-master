const express = require('express');
const {
  createPlacement,
  getAllPlacements,
  getPlacementById,
  updatePlacement,
  deletePlacement,
  getMyPlacementHistory,
  getStudentPlacementHistory,
} = require('../controllers/placementController');
const { protect } = require('../middleware/authMiddleware');
const { authorize } = require('../middleware/roleMiddleware');
const { validate } = require('../middleware/validateMiddleware');
const {
  createPlacementValidator,
  updatePlacementValidator,
  placementIdValidator,
  studentIdValidator,
  getAllPlacementsValidator,
} = require('../validators/placementValidator');

const router = express.Router();

router.use(protect);

// @route   GET /api/placements/me
// NOTE: defined before /:id routes to avoid "me" being parsed as an id
router.get('/me', authorize('student', 'alumni'), getMyPlacementHistory);

// @route   GET /api/placements/student/:studentId
router.get(
  '/student/:studentId',
  authorize('admin'),
  studentIdValidator,
  validate,
  getStudentPlacementHistory
);

// @route   POST /api/placements
router.post('/', authorize('admin'), createPlacementValidator, validate, createPlacement);

// @route   GET /api/placements
router.get('/', authorize('admin'), getAllPlacementsValidator, validate, getAllPlacements);

// @route   GET /api/placements/:id
router.get('/:id', authorize('admin'), placementIdValidator, validate, getPlacementById);

// @route   PUT /api/placements/:id
router.put('/:id', authorize('admin'), updatePlacementValidator, validate, updatePlacement);

// @route   DELETE /api/placements/:id
router.delete('/:id', authorize('admin'), placementIdValidator, validate, deletePlacement);

module.exports = router;
