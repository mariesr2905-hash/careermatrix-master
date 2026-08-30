const mongoose = require('mongoose');

const SkillSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    skillName: {
      type: String,
      required: [true, 'Skill name is required'],
      trim: true,
      maxlength: [100, 'Skill name cannot exceed 100 characters'],
    },
    category: {
      type: String,
      enum: ['Technical', 'Soft Skill', 'Language', 'Tool', 'Other'],
      default: 'Technical',
    },
    proficiencyLevel: {
      type: String,
      enum: ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
      default: 'Beginner',
    },
  },
  {
    timestamps: true,
  }
);

// Prevent the same user from adding the exact same skill twice
SkillSchema.index({ user: 1, skillName: 1 }, { unique: true });

module.exports = mongoose.model('Skill', SkillSchema);
