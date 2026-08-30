# Career Matrix – Backend (Modules 1–15)

Backend for **Career Matrix – An AI-Based Alumni Mentorship and Placement Support Platform**, built with Node.js, Express.js, and MongoDB (Mongoose), following the MVC architecture.

This delivery contains **Modules 1–15**:

1. Authentication Module
2. User Management Module
3. Profile Module
4. Skills Module
5. Resume Module
6. Jobs Module
7. Internship Module
8. Interview Module
9. Mentor Module
10. Community Module
11. Mentorship Module
12. Placement Module
13. AI Career Recommendation Module
14. Notification Module
15. Chat / Messaging Module

---

## 1. Project Structure

```
career-matrix-backend/
├── config/
│   └── db.js                  # MongoDB connection
├── controllers/
│   ├── authController.js
│   ├── userController.js
│   ├── profileController.js
│   ├── skillController.js
│   ├── resumeController.js
│   ├── jobController.js
│   ├── internshipController.js
│   ├── interviewController.js
│   ├── mentorController.js
│   ├── communityController.js
│   ├── mentorshipController.js
│   ├── placementController.js
│   ├── careerRecommendationController.js
│   ├── notificationController.js
│   └── chatController.js
├── middleware/
│   ├── authMiddleware.js       # JWT verification (protect)
│   ├── roleMiddleware.js       # Role-based authorization
│   ├── errorMiddleware.js      # Global error handler + 404
│   ├── validateMiddleware.js   # express-validator result handler
│   └── uploadMiddleware.js     # Multer configs (image + resume)
├── models/
│   ├── User.js
│   ├── Profile.js
│   ├── Skill.js
│   ├── Resume.js
│   ├── Job.js
│   ├── JobApplication.js
│   ├── Internship.js
│   ├── InternshipApplication.js
│   ├── InterviewQuestion.js
│   ├── MockInterview.js
│   ├── Mentor.js
│   ├── Booking.js
│   ├── Post.js
│   ├── Comment.js
│   ├── MentorshipRequest.js
│   ├── Placement.js
│   ├── CareerPreference.js
│   ├── CareerRecommendation.js
│   ├── Notification.js
│   ├── Conversation.js
│   └── Message.js
├── routes/
│   ├── authRoutes.js
│   ├── userRoutes.js
│   ├── profileRoutes.js
│   ├── skillRoutes.js
│   ├── resumeRoutes.js
│   ├── jobRoutes.js
│   ├── internshipRoutes.js
│   ├── interviewRoutes.js
│   ├── mentorRoutes.js
│   ├── communityRoutes.js
│   ├── mentorshipRoutes.js
│   ├── placementRoutes.js
│   ├── careerRecommendationRoutes.js
│   ├── notificationRoutes.js
│   └── chatRoutes.js
├── services/
│   ├── emailService.js         # Nodemailer wrapper
│   ├── tokenService.js         # Reset-token hashing
│   ├── notificationService.js  # Reusable notification creation (used across modules)
│   └── aiRecommendationService.js  # Modular career-recommendation engine (swappable)
├── utils/
│   ├── asyncHandler.js
│   ├── errorResponse.js
│   ├── apiResponse.js
│   └── generateToken.js
├── validators/                  # express-validator rule sets (Modules 6-15)
│   ├── jobValidator.js
│   ├── internshipValidator.js
│   ├── interviewValidator.js
│   ├── mentorValidator.js
│   ├── communityValidator.js
│   ├── mentorshipValidator.js
│   ├── placementValidator.js
│   ├── careerValidator.js
│   ├── notificationValidator.js
│   └── chatValidator.js
├── uploads/
│   ├── profiles/                # uploaded profile images
│   └── resumes/                 # uploaded resume PDFs
├── server.js
├── package.json
├── .env                         # your local environment values
└── .env.example                 # template for environment variables
```

---

## 2. Setup Instructions

### Prerequisites
- Node.js >= 18
- MongoDB running locally or a MongoDB Atlas connection string

### Install & Run

```bash
cd career-matrix-backend
npm install

# copy the example env file and fill in your own values
cp .env.example .env

# start MongoDB locally if not already running
# mongod

# development (auto-restart with nodemon)
npm run dev

# production
npm start
```

The API will start on `http://localhost:5000` (or whatever `PORT` you set).

Health check: `GET /api/health`

### Required Environment Variables (`.env`)

| Variable | Description |
|---|---|
| `NODE_ENV` | `development` or `production` |
| `PORT` | Server port (default `5000`) |
| `CLIENT_URL` | Frontend URL (used in CORS + password reset links) |
| `MONGO_URI` | MongoDB connection string |
| `JWT_SECRET` | Secret used to sign JWTs — use a long random string |
| `JWT_EXPIRE` | JWT expiry, e.g. `7d` |
| `RESET_PASSWORD_EXPIRE` | Minutes a reset token stays valid (default `10`) |
| `EMAIL_HOST` / `EMAIL_PORT` / `EMAIL_USER` / `EMAIL_PASS` / `EMAIL_FROM` | SMTP config for password reset emails. If left blank, emails are logged to the console instead of sent — useful for local testing. |
| `MAX_PROFILE_IMAGE_SIZE` | Max profile image size in bytes (default 2MB) |
| `MAX_RESUME_SIZE` | Max resume size in bytes (default 5MB) |
| `PROFILE_IMAGE_UPLOAD_PATH` | Folder for profile images |
| `RESUME_UPLOAD_PATH` | Folder for resumes |

---

## 3. MongoDB Schemas (Summary)

### User
| Field | Type | Notes |
|---|---|---|
| name | String | required |
| email | String | required, unique |
| password | String | required, hashed with bcrypt, `select:false` |
| role | String | `student` \| `alumni` \| `admin`, default `student` |
| isActive | Boolean | default `true` |
| lastLogin | Date | set on login |
| resetPasswordToken | String | hashed, `select:false` |
| resetPasswordExpire | Date | `select:false` |

### Profile
| Field | Type | Notes |
|---|---|---|
| user | ObjectId → User | required, unique |
| bio, phone, address, department, currentPosition, company | String | optional |
| graduationYear | Number | optional |
| linkedin, github | String (URL) | optional |
| profileImage | String | path to uploaded image |

### Skill
| Field | Type | Notes |
|---|---|---|
| user | ObjectId → User | required |
| skillName | String | required |
| category | String | `Technical` \| `Soft Skill` \| `Language` \| `Tool` \| `Other` |
| proficiencyLevel | String | `Beginner` \| `Intermediate` \| `Advanced` \| `Expert` |

### Resume
| Field | Type | Notes |
|---|---|---|
| user | ObjectId → User | required, unique (one active resume per user) |
| fileName / originalName | String | stored + original file name |
| filePath | String | disk path |
| fileSize | Number | bytes |
| mimeType | String | `application/pdf` |

### Job
| Field | Type | Notes |
|---|---|---|
| title, description, company, location | String | required |
| jobType | String | `Full-time` \| `Part-time` \| `Contract` \| `Remote` |
| skillsRequired | [String] | used for filtering |
| experienceRequired | String | free text, e.g. "0-2 years" |
| salaryRange | { min, max } | optional |
| applicationDeadline | Date | optional |
| postedBy | ObjectId → User | required |
| status | String | `Open` \| `Closed`, default `Open` |

### JobApplication
| Field | Type | Notes |
|---|---|---|
| job | ObjectId → Job | required |
| applicant | ObjectId → User | required |
| coverLetter | String | optional |
| resumePath | String | snapshot of applicant's resume at time of applying |
| status | String | `Applied` \| `Shortlisted` \| `Rejected` \| `Selected` |

*Unique index on `(job, applicant)` — a user can't apply twice to the same job.*

### Internship
Same shape as Job, but with `duration` (String, required) and `stipend` (Number) instead of `jobType`/`salaryRange`.

### InternshipApplication
Same shape as JobApplication, referencing `internship` instead of `job`.

### InterviewQuestion
| Field | Type | Notes |
|---|---|---|
| question | String | required |
| category | String | `Technical` \| `HR` \| `Behavioral` \| `Aptitude` \| `Other` |
| difficulty | String | `Easy` \| `Medium` \| `Hard` |
| role | String | target job role, e.g. "Backend Developer" |
| suggestedAnswer | String | optional |
| createdBy | ObjectId → User | admin who authored it |

### MockInterview
| Field | Type | Notes |
|---|---|---|
| user | ObjectId → User | required |
| type | String | `Technical` \| `HR` \| `Behavioral` \| `Mixed` |
| questionsAttempted | [{ question, questionText, userAnswer, score (0-10) }] | required, at least 1 |
| overallScore | Number | auto-calculated average of question scores |
| feedback | String | optional |
| dateTaken | Date | default now |

### Mentor
| Field | Type | Notes |
|---|---|---|
| user | ObjectId → User | required, unique |
| expertise | [String] | required, at least 1 |
| experienceYears | Number | required |
| bio, currentCompany, currentPosition | String | optional |
| availableSlots | [String] | e.g. "Monday 5:00 PM - 6:00 PM" |
| isActive | Boolean | default `true` |
| rating | Number | 0–5, default 0 |

### Booking
| Field | Type | Notes |
|---|---|---|
| mentor | ObjectId → Mentor | required |
| student | ObjectId → User | required |
| sessionDate | Date | required |
| sessionTime | String | required, e.g. "5:00 PM - 6:00 PM" |
| topic | String | optional |
| status | String | `Pending` \| `Confirmed` \| `Cancelled` \| `Completed` |
| cancellationReason | String | set when cancelled |

### Post
| Field | Type | Notes |
|---|---|---|
| user | ObjectId → User | required |
| content | String | required, max 2000 chars |
| likes | [ObjectId → User] | toggled via like endpoint |
| commentsCount | Number | maintained automatically |

### Comment
| Field | Type | Notes |
|---|---|---|
| post | ObjectId → Post | required |
| user | ObjectId → User | required |
| content | String | required, max 500 chars |

### MentorshipRequest
| Field | Type | Notes |
|---|---|---|
| requester | ObjectId → User | required (student/alumni sending the request) |
| mentor | ObjectId → Mentor | required |
| message | String | optional, max 1000 chars |
| status | String | `Pending` \| `Accepted` \| `Rejected` \| `Cancelled` |
| respondedAt | Date | set when mentor/requester acts on it |
| responseNote | String | optional note from the mentor |

*Note: this is distinct from Module 9's `Booking` — a `Booking` is a single scheduled session, while a `MentorshipRequest` is a request to establish an ongoing mentorship relationship.*

### Placement
| Field | Type | Notes |
|---|---|---|
| student | ObjectId → User | required |
| company, jobTitle | String | required |
| package | Number | annual CTC, optional |
| placementType | String | `Full-time` \| `Internship` \| `Internship + PPO` |
| location | String | optional |
| placementDate | Date | required |
| status | String | `Applied` \| `Shortlisted` \| `Offered` \| `Placed` \| `Rejected` \| `Withdrawn` |
| remarks | String | optional, max 500 chars |
| addedBy | ObjectId → User | admin who recorded it |

### CareerPreference
| Field | Type | Notes |
|---|---|---|
| user | ObjectId → User | required, unique |
| interestedRoles, preferredIndustries, preferredLocations | [String] | optional |
| workPreference | String | `Remote` \| `On-site` \| `Hybrid` \| `No preference` |
| careerGoals | String | optional, max 1000 chars |

### CareerRecommendation
| Field | Type | Notes |
|---|---|---|
| user | ObjectId → User | required |
| recommendations | [{ role, matchScore (0-100), reason, matchedSkills, missingSkills }] | generated result set |
| basedOn | { skills, interestedRoles, department } | snapshot of inputs used |
| generatedBy | String | engine identifier, e.g. `rule-based-v1` |
| generatedAt | Date | default now |

### Notification
| Field | Type | Notes |
|---|---|---|
| user | ObjectId → User | required (recipient) |
| title, message | String | required |
| type | String | `Info` \| `JobAlert` \| `InternshipAlert` \| `MentorshipRequest` \| `Booking` \| `Placement` \| `System` \| `Community` \| `Other` |
| relatedModel / relatedId | String / ObjectId | optional polymorphic reference to the triggering document |
| isRead | Boolean | default `false` |
| createdBy | ObjectId → User | admin who triggered it (undefined for system-generated) |

### Conversation
| Field | Type | Notes |
|---|---|---|
| participants | [ObjectId → User] | required, exactly 2 (1:1 chat) |
| lastMessage | ObjectId → Message | denormalized for fast conversation list rendering |
| lastMessageAt | Date | used to sort conversation list |

### Message
| Field | Type | Notes |
|---|---|---|
| conversation | ObjectId → Conversation | required |
| sender | ObjectId → User | required |
| content | String | required, max 2000 chars |
| readBy | [ObjectId → User] | users who have read this message |

---

## 4. REST API Endpoints

All protected routes require the header:
```
Authorization: Bearer <token>
```

### Module 1 — Authentication (`/api/auth`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| POST | `/api/auth/register` | Public | Register a new user (student/alumni/admin) |
| POST | `/api/auth/login` | Public | Login and receive JWT |
| GET | `/api/auth/me` | Private | Get currently logged-in user |
| POST | `/api/auth/forgot-password` | Public | Request password reset email |
| PUT | `/api/auth/reset-password/:resettoken` | Public | Reset password using emailed token |

### Module 2 — User Management (`/api/users`) — Admin only
| Method | Endpoint | Access | Description |
|---|---|---|---|
| GET | `/api/users?page=1&limit=10&role=student&search=john` | Admin | List all users (paginated, filterable) |
| GET | `/api/users/:id` | Admin | Get single user |
| PUT | `/api/users/:id` | Admin | Update user (name/email/role/isActive) |
| DELETE | `/api/users/:id` | Admin | Delete user |

### Module 3 — Profile (`/api/profile`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| POST | `/api/profile` | Private | Create profile for logged-in user |
| GET | `/api/profile/me` | Private | Get own profile |
| GET | `/api/profile/:userId` | Private | Get profile by user id |
| PUT | `/api/profile` | Private | Update own profile |
| PUT | `/api/profile/upload-image` | Private | Upload/replace profile image (`multipart/form-data`, field `image`) |

### Module 4 — Skills (`/api/skills`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| POST | `/api/skills` | Private | Add a skill |
| GET | `/api/skills/me` | Private | Get own skills |
| GET | `/api/skills/user/:userId` | Private | Get another user's skills |
| PUT | `/api/skills/:id` | Private (owner/admin) | Update a skill |
| DELETE | `/api/skills/:id` | Private (owner/admin) | Delete a skill |

### Module 5 — Resume (`/api/resume`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| POST | `/api/resume/upload` | Private | Upload resume PDF (`multipart/form-data`, field `resume`) |
| PUT | `/api/resume/update` | Private | Replace existing resume |
| DELETE | `/api/resume` | Private | Delete own resume |
| GET | `/api/resume/download` | Private | Download own resume |
| GET | `/api/resume/download/:userId` | Private | Download another user's resume |

### Module 6 — Jobs (`/api/jobs`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| POST | `/api/jobs` | Alumni, Admin | Create a job posting |
| GET | `/api/jobs?page=&limit=&search=&company=&location=&skills=&jobType=&status=` | Private | List/search/filter jobs |
| GET | `/api/jobs/:id` | Private | Get a single job |
| PUT | `/api/jobs/:id` | Owner/Admin | Update a job |
| DELETE | `/api/jobs/:id` | Owner/Admin | Delete a job (and its applications) |
| POST | `/api/jobs/:id/apply` | Student, Alumni | Apply for a job |
| GET | `/api/jobs/applications/me` | Private | Get your own job applications |
| GET | `/api/jobs/:id/applicants` | Owner/Admin | List applicants for a job |

### Module 7 — Internships (`/api/internships`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| POST | `/api/internships` | Alumni, Admin | Create an internship posting |
| GET | `/api/internships?page=&limit=&search=&company=&location=&skills=` | Private | List/search/filter internships |
| GET | `/api/internships/:id` | Private | Get a single internship |
| PUT | `/api/internships/:id` | Owner/Admin | Update an internship |
| DELETE | `/api/internships/:id` | Owner/Admin | Delete an internship (and its applications) |
| POST | `/api/internships/:id/apply` | Student, Alumni | Apply for an internship |
| GET | `/api/internships/applications/me` | Private | Get your own internship applications |
| GET | `/api/internships/:id/applicants` | Owner/Admin | List applicants for an internship |

### Module 8 — Interviews (`/api/interviews`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| POST | `/api/interviews/questions` | Admin | Add an interview question |
| GET | `/api/interviews/questions?category=&difficulty=&role=` | Private | List interview questions |
| PUT | `/api/interviews/questions/:id` | Admin | Update a question |
| DELETE | `/api/interviews/questions/:id` | Admin | Delete a question |
| POST | `/api/interviews/results` | Private | Save a mock interview result |
| GET | `/api/interviews/history/me` | Private | Get your own interview history |
| GET | `/api/interviews/history/:userId` | Admin | Get a specific user's interview history |
| GET | `/api/interviews/results?page=&limit=` | Admin | Get all mock interview records |
| DELETE | `/api/interviews/results/:id` | Admin | Delete a mock interview record |

### Module 9 — Mentors (`/api/mentors`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| POST | `/api/mentors/register` | Alumni, Admin | Register as a mentor |
| GET | `/api/mentors?expertise=&page=&limit=` | Private | List active mentors |
| GET | `/api/mentors/:id` | Private | Get a mentor's public profile |
| GET | `/api/mentors/me/profile` | Private (Mentor) | Get your own mentor profile |
| PUT | `/api/mentors/me/profile` | Private (Mentor) | Update your own mentor profile |
| POST | `/api/mentors/:id/book` | Student, Alumni | Book a session with a mentor |
| PUT | `/api/mentors/bookings/:bookingId/cancel` | Student/Mentor/Admin | Cancel a booking |
| GET | `/api/mentors/bookings/history` | Private | Get your booking history (as student and/or mentor) |

### Module 10 — Community (`/api/community`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| POST | `/api/community/posts` | Private | Create a post |
| GET | `/api/community/posts?page=&limit=` | Private | List all posts |
| GET | `/api/community/posts/:id` | Private | Get a single post |
| PUT | `/api/community/posts/:id` | Owner | Update a post |
| DELETE | `/api/community/posts/:id` | Owner/Admin | Delete a post (and its comments) |
| PUT | `/api/community/posts/:id/like` | Private | Like/unlike a post (toggle) |
| POST | `/api/community/posts/:id/comments` | Private | Comment on a post |
| GET | `/api/community/posts/:id/comments` | Private | Get all comments for a post |
| DELETE | `/api/community/comments/:commentId` | Comment owner/Post owner/Admin | Delete a comment |

### Module 11 — Mentorship (`/api/mentorship`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| POST | `/api/mentorship/:mentorId/request` | Student, Alumni | Send a mentorship request to a mentor |
| GET | `/api/mentorship?role=sent\|received&status=&page=&limit=` | Private | List your mentorship requests (sent/received/both) |
| PUT | `/api/mentorship/:id/accept` | Mentor (owner) | Accept a mentorship request |
| PUT | `/api/mentorship/:id/reject` | Mentor (owner) | Reject a mentorship request |
| PUT | `/api/mentorship/:id/cancel` | Requester | Cancel a pending or accepted request |
| GET | `/api/mentorship/history` | Private | Get full mentorship history (as requester and as mentor) |

### Module 12 — Placement (`/api/placements`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| POST | `/api/placements` | Admin | Create a placement record for a student |
| GET | `/api/placements?page=&limit=&status=&company=&search=` | Admin | List/search/filter all placement records |
| GET | `/api/placements/:id` | Admin | Get a single placement record |
| PUT | `/api/placements/:id` | Admin | Update a placement record (incl. status) |
| DELETE | `/api/placements/:id` | Admin | Delete a placement record |
| GET | `/api/placements/me` | Student, Alumni | Get your own placement history |
| GET | `/api/placements/student/:studentId` | Admin | Get a specific student's placement history |

### Module 13 — AI Career Recommendation (`/api/career`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| PUT | `/api/career/preferences` | Private | Create/update your career preferences |
| GET | `/api/career/preferences` | Private | Get your career preferences |
| POST | `/api/career/recommendations/generate` | Private | Analyze skills/profile/preferences and generate recommendations |
| GET | `/api/career/recommendations/latest` | Private | Get your most recently generated recommendations |
| GET | `/api/career/recommendations/history?page=&limit=` | Private | Get your recommendation generation history |

### Module 14 — Notifications (`/api/notifications`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| POST | `/api/notifications` | Admin | Create a notification for a specific user |
| POST | `/api/notifications/broadcast` | Admin | Broadcast a notification to a role (or all users) |
| GET | `/api/notifications/me?page=&limit=&isRead=&type=` | Private | Get your own notifications |
| PUT | `/api/notifications/:id/read` | Owner | Mark a notification as read |
| PUT | `/api/notifications/read-all` | Private | Mark all your notifications as read |
| DELETE | `/api/notifications/:id` | Owner/Admin | Delete a notification |

### Module 15 — Chat / Messaging (`/api/chat`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| POST | `/api/chat/conversations` | Private | Create (or fetch existing) 1:1 conversation with another user |
| GET | `/api/chat/conversations?page=&limit=` | Private | List your conversations, most recent first |
| POST | `/api/chat/conversations/:id/messages` | Participant | Send a message in a conversation |
| GET | `/api/chat/conversations/:id/messages?page=&limit=` | Participant | Get messages in a conversation |
| PUT | `/api/chat/conversations/:id/read` | Participant | Mark all unread messages in a conversation as read |
| DELETE | `/api/chat/messages/:messageId` | Sender/Admin | Delete a message |

---

## 5. Postman Testing Examples

### Register
```
POST http://localhost:5000/api/auth/register
Content-Type: application/json

{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "password": "SecurePass123",
  "role": "student"
}
```

### Login
```
POST http://localhost:5000/api/auth/login
Content-Type: application/json

{
  "email": "jane@example.com",
  "password": "SecurePass123",
  "role": "student"
}
```
Response contains `data.token` — copy it and set it in Postman as:
`Authorization: Bearer <token>` (Bearer Token auth type) for all subsequent requests.

### Forgot Password
```
POST http://localhost:5000/api/auth/forgot-password
Content-Type: application/json

{ "email": "jane@example.com" }
```

### Reset Password
```
PUT http://localhost:5000/api/auth/reset-password/<resettoken-from-email>
Content-Type: application/json

{ "password": "NewSecurePass456" }
```

### Get All Users (Admin)
```
GET http://localhost:5000/api/users?page=1&limit=10
Authorization: Bearer <admin-token>
```

### Create Profile
```
POST http://localhost:5000/api/profile
Authorization: Bearer <token>
Content-Type: application/json

{
  "bio": "Final year CS student passionate about backend engineering.",
  "phone": "+91 9876543210",
  "department": "Computer Science",
  "graduationYear": 2026,
  "linkedin": "https://linkedin.com/in/janedoe"
}
```

### Upload Profile Image
```
PUT http://localhost:5000/api/profile/upload-image
Authorization: Bearer <token>
Body: form-data
  Key: image   Type: File   Value: <select a .jpg/.png file>
```

### Add Skill
```
POST http://localhost:5000/api/skills
Authorization: Bearer <token>
Content-Type: application/json

{
  "skillName": "Node.js",
  "category": "Technical",
  "proficiencyLevel": "Advanced"
}
```

### Upload Resume
```
POST http://localhost:5000/api/resume/upload
Authorization: Bearer <token>
Body: form-data
  Key: resume   Type: File   Value: <select a .pdf file>
```

### Download Resume
```
GET http://localhost:5000/api/resume/download
Authorization: Bearer <token>
```
(In Postman, use "Send and Download" to save the returned PDF.)

### Create Job
```
POST http://localhost:5000/api/jobs
Authorization: Bearer <alumni-or-admin-token>
Content-Type: application/json

{
  "title": "Backend Developer",
  "description": "Build and maintain REST APIs using Node.js and MongoDB.",
  "company": "Acme Corp",
  "location": "Bangalore, India",
  "jobType": "Full-time",
  "skillsRequired": ["Node.js", "MongoDB", "Express"],
  "experienceRequired": "0-2 years",
  "salaryRange": { "min": 600000, "max": 900000 },
  "applicationDeadline": "2026-09-30"
}
```

### Search & Filter Jobs
```
GET http://localhost:5000/api/jobs?search=backend&location=Bangalore&skills=Node.js,MongoDB&jobType=Full-time&page=1&limit=10
Authorization: Bearer <token>
```

### Apply for Job
```
POST http://localhost:5000/api/jobs/<jobId>/apply
Authorization: Bearer <student-or-alumni-token>
Content-Type: application/json

{ "coverLetter": "I'm excited to apply for this role because..." }
```

### Create Internship
```
POST http://localhost:5000/api/internships
Authorization: Bearer <alumni-or-admin-token>
Content-Type: application/json

{
  "title": "Frontend Intern",
  "description": "Assist in building React components for the dashboard.",
  "company": "Acme Corp",
  "location": "Remote",
  "duration": "3 months",
  "stipend": 15000,
  "skillsRequired": ["React", "CSS"],
  "applicationDeadline": "2026-09-15"
}
```

### Apply for Internship
```
POST http://localhost:5000/api/internships/<internshipId>/apply
Authorization: Bearer <student-token>
Content-Type: application/json

{ "coverLetter": "I would love to gain hands-on frontend experience..." }
```

### Add Interview Question (Admin)
```
POST http://localhost:5000/api/interviews/questions
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "question": "Explain the event loop in Node.js.",
  "category": "Technical",
  "difficulty": "Medium",
  "role": "Backend Developer",
  "suggestedAnswer": "The event loop allows Node.js to perform non-blocking I/O..."
}
```

### Save Mock Interview Result
```
POST http://localhost:5000/api/interviews/results
Authorization: Bearer <token>
Content-Type: application/json

{
  "type": "Technical",
  "questionsAttempted": [
    { "questionText": "Explain the event loop in Node.js.", "userAnswer": "It handles async callbacks...", "score": 8 },
    { "questionText": "What is a closure?", "userAnswer": "A function with access to its outer scope...", "score": 9 }
  ],
  "feedback": "Strong understanding of core concepts, work on depth of examples."
}
```

### Get My Interview History
```
GET http://localhost:5000/api/interviews/history/me
Authorization: Bearer <token>
```

### Register as Mentor
```
POST http://localhost:5000/api/mentors/register
Authorization: Bearer <alumni-token>
Content-Type: application/json

{
  "expertise": ["System Design", "Career Guidance"],
  "experienceYears": 6,
  "bio": "Senior engineer passionate about mentoring students entering backend engineering.",
  "currentCompany": "Acme Corp",
  "currentPosition": "Senior Software Engineer",
  "availableSlots": ["Saturday 10:00 AM - 11:00 AM", "Sunday 4:00 PM - 5:00 PM"]
}
```

### Book Mentor Session
```
POST http://localhost:5000/api/mentors/<mentorId>/book
Authorization: Bearer <student-token>
Content-Type: application/json

{
  "sessionDate": "2026-08-15",
  "sessionTime": "10:00 AM - 11:00 AM",
  "topic": "Resume review and career guidance"
}
```

### Cancel Booking
```
PUT http://localhost:5000/api/mentors/bookings/<bookingId>/cancel
Authorization: Bearer <token>
Content-Type: application/json

{ "cancellationReason": "Schedule conflict, will rebook next week." }
```

### Get Booking History
```
GET http://localhost:5000/api/mentors/bookings/history
Authorization: Bearer <token>
```

### Create Community Post
```
POST http://localhost:5000/api/community/posts
Authorization: Bearer <token>
Content-Type: application/json

{ "content": "Just cracked my first technical interview! Happy to share tips with anyone prepping." }
```

### Like a Post
```
PUT http://localhost:5000/api/community/posts/<postId>/like
Authorization: Bearer <token>
```

### Comment on a Post
```
POST http://localhost:5000/api/community/posts/<postId>/comments
Authorization: Bearer <token>
Content-Type: application/json

{ "content": "Congrats! Would love to hear your tips." }
```

### Send Mentorship Request
```
POST http://localhost:5000/api/mentorship/<mentorId>/request
Authorization: Bearer <student-or-alumni-token>
Content-Type: application/json

{ "message": "I'd love your guidance on transitioning into backend engineering." }
```

### Get Mentorship Requests (received, pending)
```
GET http://localhost:5000/api/mentorship?role=received&status=Pending
Authorization: Bearer <mentor-token>
```

### Accept Mentorship Request
```
PUT http://localhost:5000/api/mentorship/<requestId>/accept
Authorization: Bearer <mentor-token>
Content-Type: application/json

{ "responseNote": "Happy to help — let's set up our first call." }
```

### Cancel Mentorship Request
```
PUT http://localhost:5000/api/mentorship/<requestId>/cancel
Authorization: Bearer <requester-token>
```

### Get Mentorship History
```
GET http://localhost:5000/api/mentorship/history
Authorization: Bearer <token>
```

### Create Placement Record (Admin)
```
POST http://localhost:5000/api/placements
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "student": "<studentUserId>",
  "company": "Acme Corp",
  "jobTitle": "Backend Developer",
  "package": 800000,
  "placementType": "Full-time",
  "location": "Bangalore, India",
  "placementDate": "2026-06-15",
  "status": "Placed"
}
```

### Search & Filter Placements (Admin)
```
GET http://localhost:5000/api/placements?status=Placed&company=Acme&search=developer&page=1&limit=10
Authorization: Bearer <admin-token>
```

### Get My Placement History
```
GET http://localhost:5000/api/placements/me
Authorization: Bearer <student-token>
```

### Create/Update Career Preferences
```
PUT http://localhost:5000/api/career/preferences
Authorization: Bearer <token>
Content-Type: application/json

{
  "interestedRoles": ["Backend Developer", "Full Stack Developer"],
  "preferredIndustries": ["FinTech", "SaaS"],
  "preferredLocations": ["Bangalore", "Remote"],
  "workPreference": "Hybrid",
  "careerGoals": "Grow into a backend-focused engineering role within 2 years."
}
```

### Generate Career Recommendations
```
POST http://localhost:5000/api/career/recommendations/generate
Authorization: Bearer <token>
```
(Requires at least one skill already added via `POST /api/skills`.)

### Get Latest Recommendations
```
GET http://localhost:5000/api/career/recommendations/latest
Authorization: Bearer <token>
```

### Create Notification (Admin)
```
POST http://localhost:5000/api/notifications
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "userId": "<targetUserId>",
  "title": "New Job Match",
  "message": "A new Backend Developer role matching your skills was just posted.",
  "type": "JobAlert"
}
```

### Broadcast Notification to a Role (Admin)
```
POST http://localhost:5000/api/notifications/broadcast
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "role": "student",
  "title": "Placement Drive Announcement",
  "message": "A new placement drive begins next Monday. Update your resume today!",
  "type": "System"
}
```

### Get My Notifications (unread only)
```
GET http://localhost:5000/api/notifications/me?isRead=false&page=1&limit=10
Authorization: Bearer <token>
```

### Mark All Notifications as Read
```
PUT http://localhost:5000/api/notifications/read-all
Authorization: Bearer <token>
```

### Create/Get Conversation
```
POST http://localhost:5000/api/chat/conversations
Authorization: Bearer <token>
Content-Type: application/json

{ "participantId": "<otherUserId>" }
```

### Send a Message
```
POST http://localhost:5000/api/chat/conversations/<conversationId>/messages
Authorization: Bearer <token>
Content-Type: application/json

{ "content": "Hi! Thanks for accepting my mentorship request." }
```

### Get Conversation Messages
```
GET http://localhost:5000/api/chat/conversations/<conversationId>/messages?page=1&limit=20
Authorization: Bearer <token>
```

### Mark Messages as Read
```
PUT http://localhost:5000/api/chat/conversations/<conversationId>/read
Authorization: Bearer <token>
```

---

## 6. Standard Response Format

Success:
```json
{
  "success": true,
  "message": "Login successful",
  "data": { "user": { "...": "..." }, "token": "..." }
}
```

Error:
```json
{
  "success": false,
  "message": "Invalid email or password"
}
```

Validation error:
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    { "field": "email", "message": "Please provide a valid email" }
  ]
}
```

---

## 7. Security Notes

- Passwords hashed with **bcrypt** (salt rounds: 10), never returned in API responses.
- JWT-based stateless authentication (`Authorization: Bearer <token>`).
- Role-based access control via `authorize('admin')` middleware.
- `helmet` for secure HTTP headers, `express-mongo-sanitize` to prevent NoSQL injection.
- File uploads restricted by MIME type + extension + size (images: jpg/jpeg/png/webp ≤ 2MB; resumes: PDF only ≤ 5MB).
- Password reset tokens are random, hashed (SHA-256) before storage, and time-limited.
- All input validated with `express-validator` before hitting controllers. Modules 6–10 use dedicated files under `validators/` for their validation rule sets.
- Ownership checks (owner-or-admin) are enforced in controllers for jobs, internships, mentor bookings, posts, and comments before allowing update/delete.
- Duplicate-prevention unique indexes: a user can't apply twice to the same job/internship, and can't register as a mentor twice.
- Mentorship requests prevent duplicate pending/accepted requests to the same mentor, and self-requests are blocked.
- Chat conversations are restricted to their two participants — enforced in `chatController.getConversationOrFail` before any read or write.
- Notification creation never throws into the calling request — a failed notification is logged and swallowed by `notificationService`, so it can never break the primary action (accepting a request, updating a placement, etc.) that triggered it.
- The AI recommendation engine (`services/aiRecommendationService.js`) is fully decoupled from the controller layer — swapping the deterministic scoring logic for a real external AI API call requires changing only that one file.

---

## 8. What's Next

This delivery covers **Modules 1–15**, as requested. Any future modules will be added on request, following the same MVC structure and conventions established here.
