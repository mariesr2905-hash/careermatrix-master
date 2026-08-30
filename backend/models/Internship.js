const mongoose = require('mongoose');

const InternshipSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Internship title is required'],
      trim: true,
      maxlength: [150, 'Title cannot exceed 150 characters'],
    },
    description: {
      type: String,
      required: [true, 'Internship description is required'],
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
    duration: {
      type: String,
      required: [true, 'Duration is required (e.g. "3 months")'],
      trim: true,
    },
    stipend: {
      type: Number,
      min: 0,
      default: 0,
    },
    skillsRequired: {
      type: [String],
      default: [],
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

InternshipSchema.index({ title: 'text', description: 'text', company: 'text' });
InternshipSchema.index({ location: 1 });
InternshipSchema.index({ skillsRequired: 1 });
InternshipSchema.index({ status: 1 });

module.exports = mongoose.model('Internship', InternshipSchema);
