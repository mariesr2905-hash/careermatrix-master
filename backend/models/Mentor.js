const mongoose = require('mongoose');

const MentorSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    expertise: {
      type: [String],
      default: [],
      validate: {
        validator: (arr) => Array.isArray(arr) && arr.length > 0,
        message: 'At least one area of expertise is required',
      },
    },
    experienceYears: {
      type: Number,
      min: 0,
      required: [true, 'Years of experience is required'],
    },
    bio: {
      type: String,
      maxlength: [1000, 'Bio cannot exceed 1000 characters'],
    },
    currentCompany: {
      type: String,
      trim: true,
    },
    currentPosition: {
      type: String,
      trim: true,
    },
    availableSlots: {
      type: [String], // e.g. ["Monday 5:00 PM - 6:00 PM", "Saturday 10:00 AM - 11:00 AM"]
      default: [],
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    rating: {
      type: Number,
      min: 0,
      max: 5,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

MentorSchema.index({ expertise: 1 });

module.exports = mongoose.model('Mentor', MentorSchema);
