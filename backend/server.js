const path = require('path');
const dotenv = require('dotenv');

// Load environment variables before anything else
dotenv.config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const cookieParser = require('cookie-parser');
const mongoSanitize = require('express-mongo-sanitize');

const connectDB = require('./config/db');
const { notFound, errorHandler } = require('./middleware/errorMiddleware');

// Routes
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const profileRoutes = require('./routes/profileRoutes');
const skillRoutes = require('./routes/skillRoutes');
const educationRoutes = require('./routes/educationRoutes');
const certificateRoutes = require('./routes/certificateRoutes');
const resumeRoutes = require('./routes/resumeRoutes');
const jobRoutes = require('./routes/jobRoutes');
const internshipRoutes = require('./routes/internshipRoutes');
const interviewRoutes = require('./routes/interviewRoutes');
const mentorRoutes = require('./routes/mentorRoutes');
const communityRoutes = require('./routes/communityRoutes');
const mentorshipRoutes = require('./routes/mentorshipRoutes');
const placementRoutes = require('./routes/placementRoutes');
const careerRecommendationRoutes = require('./routes/careerRecommendationRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const chatRoutes = require('./routes/chatRoutes');

const app = express();

// ---------- Global Middleware ----------
app.use(helmet());
app.use(
  cors({
    // Mobile/desktop Flutter builds send no Origin header at all, so they are
    // unaffected by this setting either way. For Flutter *web* (and any
    // browser-based client), reflecting the request origin lets requests
    // succeed from any dev port while still supporting credentials: true
    // (origin: '*' is invalid together with credentials and gets rejected
    // by browsers).
    origin: (origin, callback) => callback(null, origin || true),
    credentials: true,
  })
);
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(mongoSanitize());

if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// Serve uploaded files (profile images, resumes) statically
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ---------- Health Check ----------
app.get('/api/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Career Matrix API is running',
    timestamp: new Date().toISOString(),
  });
});

// ---------- API Routes (Modules 1-5) ----------
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/skills', skillRoutes);
app.use('/api/education', educationRoutes);
app.use('/api/certificates', certificateRoutes);
app.use('/api/resume', resumeRoutes);
app.use('/api/jobs', jobRoutes);
app.use('/api/internships', internshipRoutes);
app.use('/api/interviews', interviewRoutes);
app.use('/api/mentors', mentorRoutes);
app.use('/api/community', communityRoutes);
app.use('/api/mentorship', mentorshipRoutes);
app.use('/api/placements', placementRoutes);
app.use('/api/career', careerRecommendationRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/chat', chatRoutes);

// ---------- Error Handling ----------
app.use(notFound);
app.use(errorHandler);

const PORT = process.env.PORT || 5000;

// Connect to MongoDB, then start accepting HTTP requests only once the
// connection is established. If MongoDB is unavailable, connectDB() logs
// the error and exits the process (see config/db.js) instead of silently
// starting a server that can't actually read/write any data.
let server;
connectDB().then(() => {
  server = app.listen(PORT, () => {
    console.log(
      `Career Matrix backend running in ${process.env.NODE_ENV || 'development'} mode on port ${PORT}`
    );
  });
});

// Handle unhandled promise rejections gracefully
process.on('unhandledRejection', (err) => {
  console.error(`Unhandled Rejection: ${err.message}`);
  if (server) server.close(() => process.exit(1));
  else process.exit(1);
});

module.exports = app;
