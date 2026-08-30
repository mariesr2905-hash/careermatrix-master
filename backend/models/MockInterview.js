const mongoose = require('mongoose');

const AttemptedQuestionSchema = new mongoose.Schema(
  {
    question: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'InterviewQuestion',
    },
    questionText: {
      type: String,
      required: true,
    },
    userAnswer: {
      type: String,
      default: '',
    },
    score: {
      type: Number,
      min: 0,
      max: 10,
      default: 0,
    },
  },
  { _id: false }
);

const MockInterviewSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    type: {
      type: String,
      enum: ['Technical', 'HR', 'Behavioral', 'Mixed'],
      default: 'Technical',
    },
    questionsAttempted: {
      type: [AttemptedQuestionSchema],
      default: [],
      validate: {
        validator: (arr) => Array.isArray(arr) && arr.length > 0,
        message: 'At least one attempted question is required',
      },
    },
    overallScore: {
      type: Number,
      min: 0,
      max: 10,
      default: 0,
    },
    feedback: {
      type: String,
      maxlength: [2000, 'Feedback cannot exceed 2000 characters'],
    },
    dateTaken: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

MockInterviewSchema.index({ user: 1, dateTaken: -1 });

// Auto-calculate overallScore as the average of individual question scores
MockInterviewSchema.pre('save', function (next) {
  if (this.questionsAttempted && this.questionsAttempted.length > 0) {
    const total = this.questionsAttempted.reduce((sum, q) => sum + (q.score || 0), 0);
    this.overallScore = Number((total / this.questionsAttempted.length).toFixed(2));
  }
  next();
});

module.exports = mongoose.model('MockInterview', MockInterviewSchema);
