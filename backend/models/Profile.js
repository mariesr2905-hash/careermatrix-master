const mongoose = require('mongoose');

const ProfileSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    bio: {
      type: String,
      maxlength: [500, 'Bio cannot exceed 500 characters'],
      default: '',
    },
    phone: {
      type: String,
      match: [/^[0-9+\-\s()]{7,20}$/, 'Please provide a valid phone number'],
    },
    address: {
      type: String,
      maxlength: 250,
    },
    department: {
      type: String,
      trim: true,
    },
    graduationYear: {
      type: Number,
      min: [1950, 'Graduation year seems invalid'],
      max: [2100, 'Graduation year seems invalid'],
    },
    currentPosition: {
      type: String,
      trim: true,
    },
    company: {
      type: String,
      trim: true,
    },
    linkedin: {
      type: String,
      match: [/^https?:\/\/.+/, 'LinkedIn must be a valid URL'],
    },
    github: {
      type: String,
      match: [/^https?:\/\/.+/, 'GitHub must be a valid URL'],
    },
    profileImage: {
      type: String, // relative path to uploaded image
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Profile', ProfileSchema);
