const express = require('express');
const { body, param } = require('express-validator');
const {
  addSkill,
  updateSkill,
  deleteSkill,
  getMySkills,
  getUserSkills,
} = require('../controllers/skillController');
const { protect } = require('../middleware/authMiddleware');
const { validate } = require('../middleware/validateMiddleware');

const router = express.Router();

router.use(protect);

const skillCategories = ['Technical', 'Soft Skill', 'Language', 'Tool', 'Other'];
const proficiencyLevels = ['Beginner', 'Intermediate', 'Advanced', 'Expert'];

// @route   POST /api/skills
router.post(
  '/',
  [
    body('skillName').trim().notEmpty().withMessage('Skill name is required'),
    body('category').optional().isIn(skillCategories).withMessage(`Category must be one of: ${skillCategories.join(', ')}`),
    body('proficiencyLevel').optional().isIn(proficiencyLevels).withMessage(`Proficiency must be one of: ${proficiencyLevels.join(', ')}`),
  ],
  validate,
  addSkill
);

// @route   GET /api/skills/me
router.get('/me', getMySkills);

// @route   GET /api/skills/user/:userId
router.get(
  '/user/:userId',
  [param('userId').isMongoId().withMessage('Invalid user id')],
  validate,
  getUserSkills
);

// @route   PUT /api/skills/:id
router.put(
  '/:id',
  [
    param('id').isMongoId().withMessage('Invalid skill id'),
    body('skillName').optional().trim().notEmpty().withMessage('Skill name cannot be empty'),
    body('category').optional().isIn(skillCategories).withMessage(`Category must be one of: ${skillCategories.join(', ')}`),
    body('proficiencyLevel').optional().isIn(proficiencyLevels).withMessage(`Proficiency must be one of: ${proficiencyLevels.join(', ')}`),
  ],
  validate,
  updateSkill
);

// @route   DELETE /api/skills/:id
router.delete(
  '/:id',
  [param('id').isMongoId().withMessage('Invalid skill id')],
  validate,
  deleteSkill
);

module.exports = router;
