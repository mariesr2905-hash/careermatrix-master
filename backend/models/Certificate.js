const mongoose = require('mongoose');

const CertificateSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    title: {
      type: String,
      required: [true, 'Certificate title is required'],
      trim: true,
      maxlength: [150, 'Title cannot exceed 150 characters'],
    },
    issuer: {
      type: String,
      trim: true,
      maxlength: [150, 'Issuer cannot exceed 150 characters'],
    },
    issueDate: {
      type: Date,
    },
    fileName: {
      type: String, // stored filename on disk
      required: true,
    },
    originalName: {
      type: String,
      required: true,
    },
    filePath: {
      type: String,
      required: true,
    },
    fileSize: {
      type: Number,
    },
    mimeType: {
      type: String,
    },
  },
  {
    timestamps: true,
  }
);

CertificateSchema.index({ user: 1, createdAt: -1 });

module.exports = mongoose.model('Certificate', CertificateSchema);
