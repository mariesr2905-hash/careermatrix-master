const mongoose = require('mongoose');

const InterviewQuestionSchema = new mongoose.Schema(
  {
    question: {
      type: String,
      required: [true, 'Question text is required'],
      trim: true,
      maxlength: [1000, 'Question cannot exceed 1000 characters'],
    },
    category: {
      type: String,
      enum: ['Technical', 'HR', 'Behavioral', 'Aptitude', 'Other'],
      default: 'Technical',
    },
    difficulty: {
      type: String,
      enum: ['Easy', 'Medium', 'Hard'],
      default: 'Medium',
    },
    role: {
      type: String,
      trim: true,
      default: 'General',
    },
    suggestedAnswer: {
      type: String,
      maxlength: [3000, 'Suggested answer cannot exceed 3000 characters'],
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

InterviewQuestionSchema.index({ category: 1, difficulty: 1, role: 1 });

module.exports = mongoose.model('InterviewQuestion', InterviewQuestionSchema);
