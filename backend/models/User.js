const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');

const UserSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
      minlength: [2, 'Name must be at least 2 characters'],
      maxlength: [100, 'Name cannot exceed 100 characters'],
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [
        /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
        'Please provide a valid email address',
      ],
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: [8, 'Password must be at least 8 characters'],
      select: false, // never return password by default
    },
    fullName: {
      type: String,
      trim: true,
    },
    phone: {
      type: String,
      trim: true,
    },
    role: {
      type: String,
      enum: {
        values: ['STUDENT', 'ALUMNI', 'MENTOR', 'COMPANY', 'ADMIN'],
        message: 'Role must be one of: STUDENT, ALUMNI, MENTOR, COMPANY, ADMIN',
      },
      uppercase: true,
      default: 'STUDENT',
    },
    status: {
      type: String,
      enum: {
        values: ['PENDING', 'APPROVED', 'REJECTED', 'ACTIVE', 'DEACTIVATED'],
        message: 'Status must be one of: PENDING, APPROVED, REJECTED, ACTIVE, DEACTIVATED',
      },
      uppercase: true,
      default: 'PENDING',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    isApproved: {
      type: Boolean,
      default: false,
    },
    approvedAt: {
      type: Date,
    },
    approvedBy: {
      type: String,
    },
    rejectedAt: {
      type: Date,
    },
    rejectedBy: {
      type: String,
    },
    rejectionReason: {
      type: String,
    },
    lastLogin: {
      type: Date,
    },
    lastLoginAt: {
      type: Date,
    },
    resetPasswordToken: {
      type: String,
      select: false,
    },
    resetPasswordExpire: {
      type: Date,
      select: false,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
UserSchema.index({ role: 1 });
UserSchema.index({ status: 1 });

// Synchronize name and fullName, and default isApproved/isActive based on status
UserSchema.pre('save', function (next) {
  if (this.fullName && !this.name) this.name = this.fullName;
  if (this.name && !this.fullName) this.fullName = this.name;
  
  // Keep status and isApproved/isActive in sync
  const statusUpper = (this.status || '').toUpperCase();
  if (statusUpper === 'APPROVED' || statusUpper === 'ACTIVE') {
    this.isApproved = true;
    this.isActive = true;
  } else if (statusUpper === 'REJECTED') {
    this.isApproved = false;
    this.isActive = false;
  } else if (statusUpper === 'DEACTIVATED') {
    this.isActive = false;
  } else if (statusUpper === 'PENDING') {
    this.isApproved = false;
  }
  
  next();
});

// Pre-query middleware to normalize role and status filters
UserSchema.pre(['find', 'findOne', 'countDocuments', 'findOneAndUpdate', 'updateOne'], function(next) {
  const query = this.getQuery();
  if (query) {
    if (query.role) {
      if (typeof query.role === 'string') {
        query.role = query.role.toUpperCase();
      } else if (query.role.$in) {
        query.role.$in = query.role.$in.map(r => typeof r === 'string' ? r.toUpperCase() : r);
      } else if (query.role.$ne) {
        query.role.$ne = typeof query.role.$ne === 'string' ? query.role.$ne.toUpperCase() : query.role.$ne;
      }
    }
    if (query.status) {
      if (typeof query.status === 'string') {
        query.status = query.status.toUpperCase();
      } else if (query.status.$in) {
        query.status.$in = query.status.$in.map(s => typeof s === 'string' ? s.toUpperCase() : s);
      } else if (query.status.$ne) {
        query.status.$ne = typeof query.status.$ne === 'string' ? query.status.$ne.toUpperCase() : query.status.$ne;
      }
    }
  }
  next();
});

// Hash password before saving, only if it was modified
UserSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();

  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Instance method: compare entered password with hashed password
UserSchema.methods.matchPassword = async function (enteredPassword) {
  return bcrypt.compare(enteredPassword, this.password);
};

// Instance method: generate and hash password reset token
UserSchema.methods.getResetPasswordToken = function () {
  // Plain token sent to the user via email
  const resetToken = crypto.randomBytes(32).toString('hex');

  // Hashed version stored in DB
  this.resetPasswordToken = crypto
    .createHash('sha256')
    .update(resetToken)
    .digest('hex');

  const expireMinutes = Number(process.env.RESET_PASSWORD_EXPIRE) || 10;
  this.resetPasswordExpire = Date.now() + expireMinutes * 60 * 1000;

  return resetToken;
};

// Never expose sensitive fields even if accidentally selected
UserSchema.methods.toJSON = function () {
  const user = this.toObject();
  delete user.password;
  delete user.resetPasswordToken;
  delete user.resetPasswordExpire;
  delete user.__v;
  return user;
};

module.exports = mongoose.model('User', UserSchema);
