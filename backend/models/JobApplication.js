const mongoose = require('mongoose');

const JobApplicationSchema = new mongoose.Schema(
  {
    job: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Job',
      required: true,
    },
    applicant: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    coverLetter: {
      type: String,
      maxlength: [2000, 'Cover letter cannot exceed 2000 characters'],
    },
    resumePath: {
      type: String, // snapshot of the applicant's resume file path at time of applying
    },
    status: {
      type: String,
      enum: ['Applied', 'Shortlisted', 'Rejected', 'Selected'],
      default: 'Applied',
    },
  },
  {
    timestamps: true,
  }
);

// Prevent a user from applying to the same job more than once
JobApplicationSchema.index({ job: 1, applicant: 1 }, { unique: true });

module.exports = mongoose.model('JobApplication', JobApplicationSchema);
