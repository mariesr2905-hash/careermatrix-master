const mongoose = require('mongoose');

const CareerPreferenceSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    interestedRoles: {
      type: [String],
      default: [],
    },
    preferredIndustries: {
      type: [String],
      default: [],
    },
    preferredLocations: {
      type: [String],
      default: [],
    },
    workPreference: {
      type: String,
      enum: ['Remote', 'On-site', 'Hybrid', 'No preference'],
      default: 'No preference',
    },
    careerGoals: {
      type: String,
      maxlength: [1000, 'Career goals cannot exceed 1000 characters'],
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('CareerPreference', CareerPreferenceSchema);
