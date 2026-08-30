const mongoose = require('mongoose');

const MentorshipRequestSchema = new mongoose.Schema(
  {
    requester: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    mentor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Mentor',
      required: true,
    },
    message: {
      type: String,
      maxlength: [1000, 'Message cannot exceed 1000 characters'],
    },
    status: {
      type: String,
      enum: ['Pending', 'Accepted', 'Rejected', 'Cancelled'],
      default: 'Pending',
    },
    respondedAt: {
      type: Date,
    },
    responseNote: {
      type: String,
      maxlength: [500, 'Response note cannot exceed 500 characters'],
    },
  },
  {
    timestamps: true,
  }
);

MentorshipRequestSchema.index({ requester: 1, createdAt: -1 });
MentorshipRequestSchema.index({ mentor: 1, status: 1 });

module.exports = mongoose.model('MentorshipRequest', MentorshipRequestSchema);
