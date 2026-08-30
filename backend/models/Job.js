const mongoose = require('mongoose');

const JobSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Job title is required'],
      trim: true,
      maxlength: [150, 'Job title cannot exceed 150 characters'],
    },
    description: {
      type: String,
      required: [true, 'Job description is required'],
      maxlength: [5000, 'Description cannot exceed 5000 characters'],
    },
    company: {
      type: String,
      required: [true, 'Company name is required'],
      trim: true,
    },
    location: {
      type: String,
      required: [true, 'Location is required'],
      trim: true,
    },
    jobType: {
      type: String,
      enum: ['Full-time', 'Part-time', 'Contract', 'Remote'],
      default: 'Full-time',
    },
    skillsRequired: {
      type: [String],
      default: [],
    },
    experienceRequired: {
      type: String,
      trim: true,
      default: 'Not specified',
    },
    salaryRange: {
      min: { type: Number, min: 0 },
      max: { type: Number, min: 0 },
    },
    applicationDeadline: {
      type: Date,
    },
    postedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    status: {
      type: String,
      enum: ['Open', 'Closed'],
      default: 'Open',
    },
  },
  {
    timestamps: true,
  }
);

// Text index for keyword search across title, description, company
JobSchema.index({ title: 'text', description: 'text', company: 'text' });
// Compound indexes for common filters
JobSchema.index({ location: 1 });
JobSchema.index({ skillsRequired: 1 });
JobSchema.index({ status: 1 });

module.exports = mongoose.model('Job', JobSchema);
