const User = require('../models/User');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const generateToken = require('../utils/generateToken');
const { sendResponse } = require('../utils/apiResponse');
const { sendEmail } = require('../services/emailService');
const { hashToken } = require('../services/tokenService');

/**
 * @desc    Register a new user
 * @route   POST /api/auth/register
 * @access  Public
 */
const register = asyncHandler(async (req, res, next) => {
  const { name, email, password, role } = req.body;

  // Validate required fields
  if (!name || !email || !password || !role) {
    return next(
      new ErrorResponse(
        'Name, email, password and role are required',
        400
      )
    );
  }

  // Convert role to uppercase
  const roleUpper = role.toUpperCase().trim();

  // Allowed roles
  const allowedRoles = [
    'STUDENT',
    'ALUMNI',
    'MENTOR',
    'COMPANY',
    'ADMIN',
  ];

  // Validate role
  if (!allowedRoles.includes(roleUpper)) {
    return next(new ErrorResponse('Invalid user role', 400));
  }

  // Check existing user
  const existingUser = await User.findOne({
    email: email.toLowerCase().trim(),
  });

  if (existingUser) {
    return next(
      new ErrorResponse(
        'An account with this email already exists',
        400
      )
    );
  }

  const isAdmin = roleUpper === 'ADMIN';

  // Create user
  const user = await User.create({
    name: name.trim(),
    fullName: name.trim(),
    email: email.toLowerCase().trim(),
    password,
    role: roleUpper,

    // Admin automatically approved
    status: isAdmin ? 'APPROVED' : 'PENDING',

    isActive: true,
  });

  // ADMIN REGISTRATION
  if (isAdmin) {
    const token = generateToken(user._id, user.role);

    return sendResponse(
      res,
      201,
      true,
      'Admin account registered successfully.',
      {
        user,
        token,
        pending: false,
      }
    );
  }

  // Other users
  return sendResponse(
    res,
    201,
    true,
    'Your account has been submitted successfully. Please wait for administrator approval.',
    {
      user,
      pending: true,
    }
  );
});


/**
 * @desc    Login user
 * @route   POST /api/auth/login
 * @access  Public
 */
const login = asyncHandler(async (req, res, next) => {
  const { email, password, role } = req.body;

  if (!email || !password) {
    return next(
      new ErrorResponse(
        'Email and password are required',
        400
      )
    );
  }

  // Find user with password
  const user = await User.findOne({
    email: email.toLowerCase().trim(),
  }).select('+password');

  if (!user) {
    return next(
      new ErrorResponse(
        'Invalid email or password',
        401
      )
    );
  }

  // Check password
  const isMatch = await user.matchPassword(password);

  if (!isMatch) {
    return next(
      new ErrorResponse(
        'Invalid email or password',
        401
      )
    );
  }

  // Check account status
  const status = (user.status || '').toUpperCase();

  if (status === 'PENDING') {
    return next(
      new ErrorResponse(
        'Your account is pending administrator approval.',
        403
      )
    );
  }

  if (status === 'REJECTED') {
    return next(
      new ErrorResponse(
        'Your account registration has been rejected. Please contact the administrator.',
        403
      )
    );
  }

  if (status === 'DEACTIVATED' || user.isActive === false) {
    return next(
      new ErrorResponse(
        'Your account has been deactivated. Please contact the administrator.',
        403
      )
    );
  }

  // Role validation
  if (role) {
    const requestedRole = role.toUpperCase().trim();
    const userRole = user.role.toUpperCase();

    if (requestedRole !== userRole) {
      return next(
        new ErrorResponse(
          `No ${role} account found with these credentials`,
          401
        )
      );
    }
  }

  // Update login time
  user.lastLogin = Date.now();
  user.lastLoginAt = Date.now();

  await user.save({
    validateBeforeSave: false,
  });

  // Generate token
  const token = generateToken(user._id, user.role);

  return sendResponse(
    res,
    200,
    true,
    'Login successful',
    {
      user,
      token,
    }
  );
});


/**
 * @desc    Get current logged-in user
 * @route   GET /api/auth/me
 * @access  Private
 */
const getMe = asyncHandler(async (req, res) => {
  return sendResponse(
    res,
    200,
    true,
    'Current user fetched successfully',
    {
      user: req.user,
    }
  );
});


/**
 * @desc    Forgot password
 * @route   POST /api/auth/forgot-password
 * @access  Public
 */
const forgotPassword = asyncHandler(async (req, res, next) => {
  const { email } = req.body;

  if (!email) {
    return next(
      new ErrorResponse(
        'Email is required',
        400
      )
    );
  }

  const user = await User.findOne({
    email: email.toLowerCase().trim(),
  });

  const genericMessage =
    'If an account exists for this email, a password reset link has been sent.';

  if (!user) {
    return sendResponse(
      res,
      200,
      true,
      genericMessage
    );
  }

  const resetToken = user.getResetPasswordToken();

  await user.save({
    validateBeforeSave: false,
  });

  const resetUrl =
    `${process.env.CLIENT_URL}/reset-password/${resetToken}`;

  const message =
    `You requested a password reset for your Career Matrix account.\n\n` +
    `Please use the link below:\n\n${resetUrl}\n\n` +
    `If you did not request this, please ignore this email.`;

  try {
    await sendEmail({
      to: user.email,
      subject: 'Career Matrix - Password Reset Request',
      text: message,

      html: `
        <h3>Career Matrix Password Reset</h3>
        <p>You requested a password reset.</p>
        <p>
          <a href="${resetUrl}">
            Reset Password
          </a>
        </p>
        <p>If you did not request this, please ignore this email.</p>
      `,
    });

    return sendResponse(
      res,
      200,
      true,
      genericMessage
    );

  } catch (error) {

    user.resetPasswordToken = undefined;
    user.resetPasswordExpire = undefined;

    await user.save({
      validateBeforeSave: false,
    });

    return next(
      new ErrorResponse(
        'Email could not be sent. Please try again later.',
        500
      )
    );
  }
});


/**
 * @desc    Reset password
 * @route   PUT /api/auth/reset-password/:resettoken
 * @access  Public
 */
const resetPassword = asyncHandler(async (req, res, next) => {
  const { password } = req.body;

  if (!password) {
    return next(
      new ErrorResponse(
        'Password is required',
        400
      )
    );
  }

  const hashedToken = hashToken(req.params.resettoken);

  const user = await User.findOne({
    resetPasswordToken: hashedToken,

    resetPasswordExpire: {
      $gt: Date.now(),
    },
  });

  if (!user) {
    return next(
      new ErrorResponse(
        'Invalid or expired reset token',
        400
      )
    );
  }

  user.password = password;

  user.resetPasswordToken = undefined;
  user.resetPasswordExpire = undefined;

  await user.save();

  const token = generateToken(user._id, user.role);

  return sendResponse(
    res,
    200,
    true,
    'Password reset successful',
    {
      user,
      token,
    }
  );
});


module.exports = {
  register,
  login,
  getMe,
  forgotPassword,
  resetPassword,
};
