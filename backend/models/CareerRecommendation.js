const mongoose = require('mongoose');

const RecommendedCareerSchema = new mongoose.Schema(
  {
    role: {
      type: String,
      required: true,
    },
    matchScore: {
      type: Number, // 0-100
      min: 0,
      max: 100,
      required: true,
    },
    reason: {
      type: String,
      maxlength: 500,
    },
    matchedSkills: {
      type: [String],
      default: [],
    },
    missingSkills: {
      type: [String],
      default: [],
    },
  },
  { _id: false }
);

const CareerRecommendationSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    recommendations: {
      type: [RecommendedCareerSchema],
      default: [],
    },
    basedOn: {
      skills: { type: [String], default: [] },
      interestedRoles: { type: [String], default: [] },
      department: { type: String },
    },
    generatedBy: {
      type: String, // identifies the engine version, e.g. 'rule-based-v1' or 'openai-gpt-4'
      default: 'rule-based-v1',
    },
    generatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

CareerRecommendationSchema.index({ user: 1, generatedAt: -1 });

module.exports = mongoose.model('CareerRecommendation', CareerRecommendationSchema);
