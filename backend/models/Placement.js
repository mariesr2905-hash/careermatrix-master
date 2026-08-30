const mongoose = require('mongoose');

const PlacementSchema = new mongoose.Schema(
  {
    student: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    company: {
      type: String,
      required: [true, 'Company name is required'],
      trim: true,
    },
    jobTitle: {
      type: String,
      required: [true, 'Job title is required'],
      trim: true,
    },
    package: {
      type: Number, // annual CTC
      min: 0,
    },
    placementType: {
      type: String,
      enum: ['Full-time', 'Internship', 'Internship + PPO'],
      default: 'Full-time',
    },
    location: {
      type: String,
      trim: true,
    },
    placementDate: {
      type: Date,
      required: [true, 'Placement date is required'],
    },
    status: {
      type: String,
      enum: ['Applied', 'Shortlisted', 'Offered', 'Placed', 'Rejected', 'Withdrawn'],
      default: 'Applied',
    },
    remarks: {
      type: String,
      maxlength: [500, 'Remarks cannot exceed 500 characters'],
    },
    addedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User', // admin who recorded this placement
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

PlacementSchema.index({ student: 1, createdAt: -1 });
PlacementSchema.index({ company: 'text', jobTitle: 'text' });
PlacementSchema.index({ status: 1 });

module.exports = mongoose.model('Placement', PlacementSchema);
