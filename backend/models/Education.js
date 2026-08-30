const mongoose = require('mongoose');

const EducationSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    institution: {
      type: String,
      required: [true, 'Institution/College name is required'],
      trim: true,
      maxlength: [150, 'Institution name cannot exceed 150 characters'],
    },
    degree: {
      type: String,
      required: [true, 'Degree is required'],
      trim: true,
      maxlength: [100, 'Degree cannot exceed 100 characters'],
    },
    department: {
      type: String,
      trim: true,
      maxlength: [100, 'Department cannot exceed 100 characters'],
    },
    course: {
      type: String,
      trim: true,
      maxlength: [100, 'Course cannot exceed 100 characters'],
    },
    startYear: {
      type: Number,
      required: [true, 'Start year is required'],
      min: [1950, 'Start year seems invalid'],
      max: [2100, 'Start year seems invalid'],
    },
    endYear: {
      type: Number,
      min: [1950, 'End year seems invalid'],
      max: [2100, 'End year seems invalid'],
    },
    grade: {
      type: String, // CGPA or percentage, kept as free text to support both
      trim: true,
      maxlength: [20, 'Grade cannot exceed 20 characters'],
    },
  },
  {
    timestamps: true,
  }
);

EducationSchema.index({ user: 1, startYear: -1 });

module.exports = mongoose.model('Education', EducationSchema);
