const User = require('../models/User');
const Skill = require('../models/Skill');
const Profile = require('../models/Profile');
const Job = require('../models/Job');
const Internship = require('../models/Internship');
const JobApplication = require('../models/JobApplication');
const InternshipApplication = require('../models/InternshipApplication');
const Mentor = require('../models/Mentor');
const Booking = require('../models/Booking');
const Placement = require('../models/Placement');
const Education = require('../models/Education');
const Resume = require('../models/Resume');
const MentorshipRequest = require('../models/MentorshipRequest');
const asyncHandler = require('../utils/asyncHandler');
const ErrorResponse = require('../utils/errorResponse');
const { sendResponse } = require('../utils/apiResponse');

/**
 * @desc    Get all users (supports pagination, search, and role filter)
 * @route   GET /api/users?page=1&limit=10&role=student&search=john
 * @access  Private/Admin
 */
const getAllUsers = asyncHandler(async (req, res) => {
  const page = Math.max(Number(req.query.page) || 1, 1);
  const limit = Math.min(Number(req.query.limit) || 10, 100);
  const skip = (page - 1) * limit;

  const filter = {};
  if (req.query.role) filter.role = req.query.role;
  if (req.query.status) filter.status = req.query.status;
  
  if (req.query.department) {
    const profileMatches = await Profile.find({
      department: { $regex: req.query.department, $options: 'i' },
    }).distinct('user');
    filter._id = { $in: profileMatches };
  }

  if (req.query.search) {
    filter.$or = [
      { name: { $regex: req.query.search, $options: 'i' } },
      { email: { $regex: req.query.search, $options: 'i' } },
    ];
  }

  const [users, total] = await Promise.all([
    User.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit),
    User.countDocuments(filter),
  ]);

  return sendResponse(res, 200, true, 'Users fetched successfully', users, {
    pagination: {
      total,
      page,
      pages: Math.ceil(total / limit),
      limit,
    },
  });
});

/**
 * @desc    Get single user by ID
 * @route   GET /api/users/:id
 * @access  Private/Admin
 */
const getUserById = asyncHandler(async (req, res, next) => {
  const user = await User.findById(req.params.id);

  if (!user) {
    return next(new ErrorResponse(`User not found with id ${req.params.id}`, 404));
  }

  return sendResponse(res, 200, true, 'User fetched successfully', user);
});

/**
 * @desc    Create a new user account (used by Admin to create Student /
 *          Alumni / Mentor / Company / Admin accounts). Reuses the same
 *          User model + bcrypt password hashing as the public register
 *          endpoint - this is NOT a second auth system, just an
 *          admin-only entry point into it.
 * @route   POST /api/users
 * @access  Private/Admin
 */
const createUser = asyncHandler(async (req, res, next) => {
  const { name, email, password, role } = req.body;

  const existingUser = await User.findOne({ email: email.toLowerCase() });
  if (existingUser) {
    return next(new ErrorResponse('An account with this email already exists', 400));
  }

  const roleUpper = (role || 'STUDENT').toUpperCase();
  let finalStatus = 'PENDING';
  if (req.body.status) {
    finalStatus = req.body.status.toUpperCase();
  }
  if (req.body.approveImmediately) {
    finalStatus = 'APPROVED';
  }

  const user = await User.create({
    name,
    fullName: name,
    email,
    password,
    role: roleUpper,
    status: finalStatus,
    approvedAt: (finalStatus === 'APPROVED' || finalStatus === 'ACTIVE') ? Date.now() : undefined,
    approvedBy: (finalStatus === 'APPROVED' || finalStatus === 'ACTIVE') ? req.user.name : undefined,
  });

  return sendResponse(res, 201, true, 'User created successfully', user);
});

/**
 * @desc    Update a user (admin only - can change role/isActive/status)
 * @route   PUT /api/users/:id
 * @access  Private/Admin
 */
const updateUser = asyncHandler(async (req, res, next) => {
  const allowedFields = [
    'name',
    'fullName',
    'email',
    'role',
    'isActive',
    'isApproved',
    'status',
    'rejectionReason',
    'phone',
  ];
  const updates = {};

  allowedFields.forEach((field) => {
    if (req.body[field] !== undefined) updates[field] = req.body[field];
  });

  // Handle status updates and email notifications
  if (req.body.status) {
    const statusUpper = req.body.status.toUpperCase();
    updates.status = statusUpper;
    if (statusUpper === 'APPROVED' || statusUpper === 'ACTIVE') {
      updates.isApproved = true;
      updates.isActive = true;
      updates.approvedAt = Date.now();
      updates.approvedBy = req.user.name;
    } else if (statusUpper === 'REJECTED') {
      updates.isApproved = false;
      updates.isActive = false;
      updates.rejectedAt = Date.now();
      updates.rejectedBy = req.user.name;
      if (req.body.rejectionReason) {
        updates.rejectionReason = req.body.rejectionReason;
      }
    } else if (statusUpper === 'DEACTIVATED') {
      updates.isActive = false;
    }
  }

  let user = await User.findById(req.params.id);
  if (!user) {
    return next(new ErrorResponse(`User not found with id ${req.params.id}`, 404));
  }

  const oldStatus = user.status;

  // Apply updates
  user = await User.findByIdAndUpdate(req.params.id, updates, {
    new: true,
    runValidators: true,
  });

  // Send status change notification email if status changed
  if (req.body.status && oldStatus !== req.body.status) {
    const statusUpper = req.body.status.toUpperCase();
    const { sendEmail } = require('../services/emailService');
    try {
      if (statusUpper === 'APPROVED' || statusUpper === 'ACTIVE') {
        await sendEmail({
          to: user.email,
          subject: 'Your Career Matrix account has been approved!',
          text: `Hello ${user.name},\n\nYour Career Matrix account has been approved. You can now log in.\n\nBest regards,\nCareer Matrix Team`,
          html: `<p>Hello <strong>${user.name}</strong>,</p><p>Your Career Matrix account has been approved. You can now log in.</p><p>Best regards,<br>Career Matrix Team</p>`,
        });
      } else if (statusUpper === 'REJECTED') {
        const reason = req.body.rejectionReason || 'No reason provided';
        await sendEmail({
          to: user.email,
          subject: 'Career Matrix Registration Update',
          text: `Hello ${user.name},\n\nWe regret to inform you that your Career Matrix registration has been rejected.\n\nReason: ${reason}\n\nPlease contact the administrator for more details.\n\nBest regards,\nCareer Matrix Team`,
          html: `<p>Hello <strong>${user.name}</strong>,</p><p>We regret to inform you that your Career Matrix registration has been rejected.</p><p><strong>Reason:</strong> ${reason}</p><p>Please contact the administrator for more details.</p><p>Best regards,<br>Career Matrix Team</p>`,
        });
      }
    } catch (err) {
      console.error('Failed to send status update email:', err);
    }
  }

  // Handle nested profile upsert
  if (req.body.profile) {
    await Profile.findOneAndUpdate(
      { user: req.params.id },
      { ...req.body.profile, user: req.params.id },
      { new: true, upsert: true, runValidators: true }
    );
  }

  // Handle nested mentor profile upsert
  if (req.body.mentorProfile) {
    await Mentor.findOneAndUpdate(
      { user: req.params.id },
      { ...req.body.mentorProfile, user: req.params.id },
      { new: true, upsert: true, runValidators: true }
    );
  }

  // Re-fetch final state
  const updatedUser = await User.findById(req.params.id);

  return sendResponse(res, 200, true, 'User updated successfully', updatedUser);
});

/**
 * @desc    Delete a user
 * @route   DELETE /api/users/:id
 * @access  Private/Admin
 */
const deleteUser = asyncHandler(async (req, res, next) => {
  if (req.params.id === String(req.user._id)) {
    return next(new ErrorResponse('Admins cannot delete their own account via this route', 400));
  }

  const user = await User.findByIdAndDelete(req.params.id);

  if (!user) {
    return next(new ErrorResponse(`User not found with id ${req.params.id}`, 404));
  }

  return sendResponse(res, 200, true, 'User deleted successfully');
});

/**
 * @desc    Browse candidates (students/alumni) with their skills for
 *          companies to evaluate. Unlike getAllUsers (admin-only, full
 *          user records), this is a lighter, role-restricted view.
 * @route   GET /api/users/candidates?skill=React&page=1&limit=10
 * @access  Private/Company,Alumni,Admin
 */
const getCandidates = asyncHandler(async (req, res) => {
  const page = Math.max(Number(req.query.page) || 1, 1);
  const limit = Math.min(Number(req.query.limit) || 10, 100);
  const skip = (page - 1) * limit;

  const userFilter = { role: 'student', isActive: { $ne: false } };
  if (req.query.search) {
    userFilter.$or = [
      { name: { $regex: req.query.search, $options: 'i' } },
      { email: { $regex: req.query.search, $options: 'i' } },
    ];
  }

  let userIdsWithSkill = null;
  if (req.query.skill) {
    const skillMatches = await Skill.find({
      skillName: { $regex: req.query.skill, $options: 'i' },
    }).distinct('user');
    userIdsWithSkill = skillMatches;
    userFilter._id = { $in: skillMatches };
  }

  const [users, total] = await Promise.all([
    User.find(userFilter).select('name email role createdAt').sort({ createdAt: -1 }).skip(skip).limit(limit),
    User.countDocuments(userFilter),
  ]);

  const userIds = users.map((u) => u._id);
  const [skills, profiles] = await Promise.all([
    Skill.find({ user: { $in: userIds } }).select('user skillName proficiencyLevel'),
    Profile.find({ user: { $in: userIds } }).select('user currentPosition company graduationYear'),
  ]);

  const skillsByUser = {};
  skills.forEach((s) => {
    const key = String(s.user);
    if (!skillsByUser[key]) skillsByUser[key] = [];
    skillsByUser[key].push({ skillName: s.skillName, proficiencyLevel: s.proficiencyLevel });
  });
  const profileByUser = {};
  profiles.forEach((p) => {
    profileByUser[String(p.user)] = p;
  });

  const candidates = users.map((u) => ({
    _id: u._id,
    name: u.name,
    email: u.email,
    role: u.role,
    skills: skillsByUser[String(u._id)] || [],
    profile: profileByUser[String(u._id)] || null,
  }));

  return sendResponse(res, 200, true, 'Candidates fetched successfully', candidates, {
    pagination: { total, page, pages: Math.ceil(total / limit), limit },
  });
});

/**
 * @desc    Get dashboard statistics for Admin Overview
 * @route   GET /api/users/admin/dashboard-stats
 * @access  Private/Admin
 */
const getDashboardStats = asyncHandler(async (req, res) => {
  const [
    studentsCount,
    alumniCount,
    mentorsCount,
    companiesCount,
    jobsCount,
    internshipsCount,
    jobAppsCount,
    internshipAppsCount,
    placementsCount,
    totalBookings,
    completedBookings,
    pendingApprovalsCount,
  ] = await Promise.all([
    User.countDocuments({ role: 'student' }),
    User.countDocuments({ role: 'alumni' }),
    User.countDocuments({ role: 'mentor' }),
    User.countDocuments({ role: 'company' }),
    Job.countDocuments({}),
    Internship.countDocuments({}),
    JobApplication.countDocuments({}),
    InternshipApplication.countDocuments({}),
    Placement.countDocuments({ status: 'Placed' }),
    Booking.countDocuments({}),
    Booking.countDocuments({ status: 'Completed' }),
    User.countDocuments({ status: 'PENDING' }),
  ]);

  const totalStudentsAndAlumni = studentsCount + alumniCount;
  const placementRate = totalStudentsAndAlumni > 0 ? (placementsCount / totalStudentsAndAlumni) : 0.0;
  const sessionCompletion = totalBookings > 0 ? (completedBookings / totalBookings) : 0.0;
  const avgCareerHealth = 0.76; 

  return sendResponse(res, 200, true, 'Dashboard stats fetched successfully', {
    students: studentsCount,
    alumni: alumniCount,
    mentors: mentorsCount,
    companies: companiesCount,
    jobs: jobsCount,
    internships: internshipsCount,
    jobApplications: jobAppsCount,
    internshipApplications: internshipAppsCount,
    placements: placementsCount,
    placementRate,
    sessionCompletion,
    avgCareerHealth,
    pendingApprovals: pendingApprovalsCount,
  });
});

/**
 * @desc    Get detailed user profiles and linked data for Admin inspection
 * @route   GET /api/users/:id/admin-details
 * @access  Private/Admin
 */
const getAdminUserDetails = asyncHandler(async (req, res, next) => {
  const user = await User.findById(req.params.id);
  if (!user) {
    return next(new ErrorResponse(`User not found with id ${req.params.id}`, 404));
  }

  const userId = user._id;
  const role = user.role;

  const [profile, skills, education, resume] = await Promise.all([
    Profile.findOne({ user: userId }),
    Skill.find({ user: userId }),
    Education.find({ user: userId }),
    Resume.findOne({ user: userId }),
  ]);

  let extraData = {};

  if (role === 'student' || role === 'alumni') {
    const [jobApps, internshipApps] = await Promise.all([
      JobApplication.find({ applicant: userId }).populate('job'),
      InternshipApplication.find({ applicant: userId }).populate('internship'),
    ]);
    extraData.applications = {
      jobs: jobApps,
      internships: internshipApps,
    };
  } else if (role === 'mentor') {
    const mentorProfile = await Mentor.findOne({ user: userId });
    let bookings = [];
    if (mentorProfile) {
      bookings = await Booking.find({ mentor: mentorProfile._id }).populate('student');
    }
    const mentorshipRequests = await MentorshipRequest.find({ mentor: userId }).populate('student');
    extraData.mentorProfile = mentorProfile;
    extraData.bookings = bookings;
    extraData.mentorshipRequests = mentorshipRequests;
  } else if (role === 'company') {
    const [jobs, internships] = await Promise.all([
      Job.find({ postedBy: userId }),
      Internship.find({ postedBy: userId }),
    ]);

    const jobIds = jobs.map(j => j._id);
    const internshipIds = internships.map(i => i._id);

    const [jobApps, internshipApps] = await Promise.all([
      JobApplication.find({ job: { $in: jobIds } }).populate('applicant').populate('job'),
      InternshipApplication.find({ internship: { $in: internshipIds } }).populate('applicant').populate('internship'),
    ]);

    extraData.postedOpportunities = {
      jobs,
      internships,
    };
    extraData.receivedApplications = {
      jobs: jobApps,
      internships: internshipApps,
    };
  }

  return sendResponse(res, 200, true, 'User details fetched successfully', {
    user,
    profile,
    skills,
    education,
    resume,
    ...extraData,
  });
});

const XLSX = require('xlsx');
const crypto = require('crypto');
const fs = require('fs');

/**
 * @desc    Download Excel template for user creation
 * @route   GET /api/users/admin/excel/template/:role
 * @access  Private/Admin
 */
const getExcelTemplate = asyncHandler(async (req, res, next) => {
  const role = req.params.role.toUpperCase();
  let headers = [];

  switch (role) {
    case 'STUDENT':
      headers = ['Full Name', 'Email', 'Phone', 'Register Number', 'Department', 'Course', 'Year', 'Graduation Year', 'Gender', 'Date of Birth'];
      break;
    case 'ALUMNI':
      headers = ['Full Name', 'Email', 'Phone', 'Register Number', 'Department', 'Course', 'Graduation Year', 'Current Company', 'Current Job Title', 'Location'];
      break;
    case 'MENTOR':
      headers = ['Full Name', 'Email', 'Phone', 'Expertise', 'Company', 'Job Title', 'Experience', 'LinkedIn'];
      break;
    case 'COMPANY':
      headers = ['Company Name', 'Email', 'Phone', 'Website', 'Industry', 'Location', 'Contact Person', 'Contact Person Designation'];
      break;
    case 'ADMIN':
      headers = ['Full Name', 'Email', 'Phone', 'Admin Role'];
      break;
    default:
      return next(new ErrorResponse('Invalid role specified', 400));
  }

  const ws = XLSX.utils.aoa_to_sheet([headers]);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, 'Template');

  const buffer = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });

  res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  res.setHeader('Content-Disposition', `attachment; filename="${role.toLowerCase()}_template.xlsx"`);
  return res.send(buffer);
});

/**
 * @desc    Validate Excel import preview
 * @route   POST /api/users/admin/excel/validate
 * @access  Private/Admin
 */
const validateExcelImport = asyncHandler(async (req, res, next) => {
  if (!req.file) {
    return next(new ErrorResponse('Please upload an Excel file', 400));
  }

  const role = (req.body.userType || req.body.role || '').toUpperCase();
  const validRoles = ['STUDENT', 'ALUMNI', 'MENTOR', 'COMPANY', 'ADMIN'];
  if (!validRoles.includes(role)) {
    return next(new ErrorResponse('Invalid or missing userType/role', 400));
  }

  const workbook = XLSX.readFile(req.file.path);
  const sheetName = workbook.SheetNames[0];
  const sheet = workbook.Sheets[sheetName];
  const rows = XLSX.utils.sheet_to_json(sheet, { defval: '' });

  // Clean up uploaded file
  try {
    fs.unlinkSync(req.file.path);
  } catch (err) {
    console.error('Failed to delete temp excel file:', err);
  }

  if (rows.length === 0) {
    return next(new ErrorResponse('Excel file is empty', 400));
  }

  // Pre-fetch all emails to optimize duplicate checks
  const fileEmails = rows.map(r => String(r.Email || r.email || '').trim().toLowerCase()).filter(Boolean);
  const existingUsers = await User.find({ email: { $in: fileEmails } }).select('email');
  const dbEmails = new Set(existingUsers.map(u => u.email.toLowerCase()));

  const previewRecords = [];
  const seenEmailsInFile = new Set();
  
  let validCount = 0;
  let invalidCount = 0;
  let duplicateCount = 0;

  for (const row of rows) {
    const cleanRow = {};
    Object.keys(row).forEach(key => {
      cleanRow[key.trim()] = String(row[key]).trim();
    });

    const email = cleanRow.Email || cleanRow.email || '';
    const emailLower = email.toLowerCase();
    
    let name = '';
    let departmentVal = '';
    
    if (role === 'COMPANY') {
      name = cleanRow['Company Name'] || cleanRow['company name'] || cleanRow.Name || cleanRow.name || '';
      departmentVal = cleanRow.Industry || cleanRow.industry || '';
    } else {
      name = cleanRow['Full Name'] || cleanRow['full name'] || cleanRow.Name || cleanRow.name || '';
      if (role === 'STUDENT' || role === 'ALUMNI') {
        departmentVal = cleanRow.Department || cleanRow.department || '';
      } else if (role === 'MENTOR') {
        departmentVal = cleanRow.Expertise || cleanRow.expertise || '';
      } else if (role === 'ADMIN') {
        departmentVal = cleanRow['Admin Role'] || cleanRow['admin role'] || '';
      }
    }

    const errors = [];
    let valStatus = 'valid';

    if (!email) {
      errors.push('Email is required');
      valStatus = 'invalid';
    } else {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email)) {
        errors.push('Invalid email format');
        valStatus = 'invalid';
      }
    }

    if (!name) {
      errors.push(role === 'COMPANY' ? 'Company Name is required' : 'Full Name is required');
      valStatus = 'invalid';
    }

    if (emailLower) {
      if (seenEmailsInFile.has(emailLower)) {
        errors.push('Duplicate email address in file');
        valStatus = 'duplicate';
      } else {
        seenEmailsInFile.add(emailLower);
        if (dbEmails.has(emailLower)) {
          errors.push('Email already exists in database');
          valStatus = 'duplicate';
        }
      }
    }

    if (valStatus === 'valid') validCount++;
    else if (valStatus === 'invalid') invalidCount++;
    else if (valStatus === 'duplicate') duplicateCount++;

    previewRecords.push({
      name,
      email,
      department: departmentVal,
      userType: role,
      validation: valStatus,
      statusText: errors.join(', ') || 'Valid',
      rawData: cleanRow,
    });
  }

  return sendResponse(res, 200, true, 'Excel file validated successfully', {
    summary: {
      total: rows.length,
      valid: validCount,
      invalid: invalidCount,
      duplicate: duplicateCount,
    },
    records: previewRecords,
  });
});

/**
 * @desc    Confirm and Import validated Excel records
 * @route   POST /api/users/admin/excel/import
 * @access  Private/Admin
 */
const confirmExcelImport = asyncHandler(async (req, res, next) => {
  const { records, userType } = req.body;
  if (!records || !Array.isArray(records) || records.length === 0) {
    return next(new ErrorResponse('No records provided for import', 400));
  }

  const role = (userType || '').toUpperCase();
  const validRoles = ['STUDENT', 'ALUMNI', 'MENTOR', 'COMPANY', 'ADMIN'];
  if (!validRoles.includes(role)) {
    return next(new ErrorResponse('Invalid or missing userType/role', 400));
  }

  const { sendEmail } = require('../services/emailService');
  let importedCount = 0;

  for (const record of records) {
    const raw = record.rawData || {};
    const email = (record.email || raw.Email || raw.email || '').toLowerCase().trim();
    if (!email) continue;

    // Double check DB duplicate
    const exists = await User.findOne({ email });
    if (exists) continue;

    let name = record.name || '';
    if (!name) {
      name = role === 'COMPANY' 
        ? (raw['Company Name'] || raw.Name || '')
        : (raw['Full Name'] || raw.Name || '');
    }

    // Generate random password
    const tempPassword = 'Temp_' + crypto.randomBytes(4).toString('hex') + '!';

    // Create user in DB as PENDING
    const user = await User.create({
      name,
      fullName: name,
      email,
      phone: raw.Phone || raw.phone || '',
      password: tempPassword,
      role,
      status: 'PENDING',
    });

    // Create profile depending on role
    if (role === 'STUDENT' || role === 'ALUMNI') {
      await Profile.create({
        user: user._id,
        phone: raw.Phone || raw.phone || '',
        department: raw.Department || raw.department || '',
        graduationYear: Number(raw['Graduation Year'] || raw.graduationYear || raw.Year || raw.year) || undefined,
        currentPosition: role === 'ALUMNI' ? (raw['Current Job Title'] || raw['Job Title'] || '') : undefined,
        company: role === 'ALUMNI' ? (raw['Current Company'] || raw.Company || '') : undefined,
        address: raw.Location || raw.location || '',
      });
    } else if (role === 'MENTOR') {
      const expertiseList = (raw.Expertise || raw.expertise || '').split(',').map(s => s.trim()).filter(Boolean);
      await Mentor.create({
        user: user._id,
        expertise: expertiseList.length > 0 ? expertiseList : ['General'],
        experienceYears: Number(raw.Experience || raw.experience) || 0,
        currentCompany: raw.Company || raw.company || '',
        currentPosition: raw['Job Title'] || raw['job title'] || '',
        bio: `Expertise: ${raw.Expertise || ''}`,
      });
      await Profile.create({
        user: user._id,
        phone: raw.Phone || raw.phone || '',
        linkedin: raw.LinkedIn || raw.linkedin || '',
        currentPosition: raw['Job Title'] || '',
        company: raw.Company || '',
      });
    } else if (role === 'COMPANY') {
      await Profile.create({
        user: user._id,
        phone: raw.Phone || raw.phone || '',
        address: raw.Location || raw.location || '',
        company: name,
        bio: `Industry: ${raw.Industry || ''}. Contact Person: ${raw['Contact Person'] || ''} (${raw['Contact Person Designation'] || ''})`,
      });
    } else if (role === 'ADMIN') {
      await Profile.create({
        user: user._id,
        phone: raw.Phone || raw.phone || '',
        currentPosition: raw['Admin Role'] || 'Administrator',
      });
    }

    // Try sending email invitation
    try {
      await sendEmail({
        to: email,
        subject: 'Welcome to Career Matrix - Complete Your Registration',
        text: `Hello ${name},\n\nAn account has been created for you on Career Matrix as an ${role.toLowerCase()}.\n\nYour account is currently pending administrator approval. Once approved, you can log in using your email and this temporary password: ${tempPassword}\n\nPlease reset your password after your first login.\n\nBest regards,\nCareer Matrix Team`,
        html: `<p>Hello <strong>${name}</strong>,</p>
               <p>An account has been created for you on Career Matrix as a <strong>${role.toLowerCase()}</strong>.</p>
               <p>Your account is currently pending administrator approval. Once approved, you can log in using your email and this temporary password: <code>${tempPassword}</code></p>
               <p>Please reset your password after your first login.</p>
               <p>Best regards,<br>Career Matrix Team</p>`,
      });
    } catch (err) {
      console.error('Failed to send email invite for imported user:', err);
    }

    importedCount++;
  }

  return sendResponse(res, 201, true, `${importedCount} users imported successfully`, {
    importedCount,
  });
});

/**
 * @desc    Bulk update status or delete multiple users
 * @route   PUT /api/users/admin/bulk-status
 * @access  Private/Admin
 */
const bulkUpdateStatus = asyncHandler(async (req, res, next) => {
  const { userIds, action, rejectionReason } = req.body;

  if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
    return next(new ErrorResponse('Please select at least one user', 400));
  }

  if (!action) {
    return next(new ErrorResponse('Please specify a bulk action (approve, reject, activate, deactivate, delete)', 400));
  }

  // Prevent admin from actioning their own account
  const selfIndex = userIds.indexOf(String(req.user._id));
  if (selfIndex !== -1) {
    userIds.splice(selfIndex, 1);
  }

  if (userIds.length === 0) {
    return next(new ErrorResponse('Cannot perform bulk action on your own admin account', 400));
  }

  const { sendEmail } = require('../services/emailService');

  if (action === 'delete') {
    // Perform bulk delete
    const result = await User.deleteMany({ _id: { $in: userIds } });
    // Also delete profiles, mentors, etc. in background
    await Promise.all([
      Profile.deleteMany({ user: { $in: userIds } }),
      Mentor.deleteMany({ user: { $in: userIds } }),
    ]);

    return sendResponse(res, 200, true, `${result.deletedCount} users deleted successfully`);
  }

  // Map action to status updates
  const updates = {};
  const actionUpper = action.toLowerCase();
  
  if (actionUpper === 'approve') {
    updates.status = 'APPROVED';
    updates.isApproved = true;
    updates.isActive = true;
    updates.approvedAt = Date.now();
    updates.approvedBy = req.user.name;
  } else if (actionUpper === 'reject') {
    updates.status = 'REJECTED';
    updates.isApproved = false;
    updates.isActive = false;
    updates.rejectedAt = Date.now();
    updates.rejectedBy = req.user.name;
    if (rejectionReason) updates.rejectionReason = rejectionReason;
  } else if (actionUpper === 'deactivate') {
    updates.status = 'DEACTIVATED';
    updates.isActive = false;
  } else if (actionUpper === 'activate') {
    updates.status = 'ACTIVE';
    updates.isActive = true;
    updates.isApproved = true;
  } else {
    return next(new ErrorResponse('Invalid bulk action specified', 400));
  }

  // Fetch users before update to send notifications
  const usersToUpdate = await User.find({ _id: { $in: userIds } });

  // Bulk update
  await User.updateMany({ _id: { $in: userIds } }, { $set: updates });

  // Send emails asynchronously
  usersToUpdate.forEach((user) => {
    try {
      if (actionUpper === 'approve') {
        sendEmail({
          to: user.email,
          subject: 'Your Career Matrix account has been approved!',
          text: `Hello ${user.name},\n\nYour Career Matrix account has been approved. You can now log in.\n\nBest regards,\nCareer Matrix Team`,
          html: `<p>Hello <strong>${user.name}</strong>,</p><p>Your Career Matrix account has been approved. You can now log in.</p><p>Best regards,<br>Career Matrix Team</p>`,
        });
      } else if (actionUpper === 'reject') {
        const reason = rejectionReason || 'No reason provided';
        sendEmail({
          to: user.email,
          subject: 'Career Matrix Registration Update',
          text: `Hello ${user.name},\n\nWe regret to inform you that your Career Matrix registration has been rejected.\n\nReason: ${reason}\n\nBest regards,\nCareer Matrix Team`,
          html: `<p>Hello <strong>${user.name}</strong>,</p><p>We regret to inform you that your Career Matrix registration has been rejected.</p><p><strong>Reason:</strong> ${reason}</p><p>Best regards,<br>Career Matrix Team</p>`,
        });
      }
    } catch (err) {
      console.error('Failed to send bulk update email:', err);
    }
  });

  return sendResponse(res, 200, true, `Bulk ${actionUpper} completed successfully for ${usersToUpdate.length} users`);
});

module.exports = {
  getAllUsers,
  getUserById,
  createUser,
  updateUser,
  deleteUser,
  getCandidates,
  getDashboardStats,
  getAdminUserDetails,
  getExcelTemplate,
  validateExcelImport,
  confirmExcelImport,
  bulkUpdateStatus,
};
