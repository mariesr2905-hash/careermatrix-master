const mongoose = require('mongoose');

const InternshipApplicationSchema = new mongoose.Schema(
  {
    internship: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Internship',
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
      type: String,
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

InternshipApplicationSchema.index({ internship: 1, applicant: 1 }, { unique: true });

module.exports = mongoose.model('InternshipApplication', InternshipApplicationSchema);
