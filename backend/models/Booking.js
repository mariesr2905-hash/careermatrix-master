const mongoose = require('mongoose');

const BookingSchema = new mongoose.Schema(
  {
    mentor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Mentor',
      required: true,
    },
    student: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    sessionDate: {
      type: Date,
      required: [true, 'Session date is required'],
    },
    sessionTime: {
      type: String,
      required: [true, 'Session time slot is required'],
      trim: true,
    },
    topic: {
      type: String,
      maxlength: [300, 'Topic cannot exceed 300 characters'],
    },
    status: {
      type: String,
      enum: ['Pending', 'Confirmed', 'Cancelled', 'Completed'],
      default: 'Pending',
    },
    cancellationReason: {
      type: String,
      maxlength: [300, 'Cancellation reason cannot exceed 300 characters'],
    },
  },
  {
    timestamps: true,
  }
);

BookingSchema.index({ student: 1, createdAt: -1 });
BookingSchema.index({ mentor: 1, sessionDate: 1 });

module.exports = mongoose.model('Booking', BookingSchema);
