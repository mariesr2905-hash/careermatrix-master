import '../models/models.dart';

/// DEPRECATED / UNUSED BY THE PRODUCTION APP.
///
/// This class is no longer referenced anywhere in lib/screens — every
/// screen now fetches real data from the backend via
/// `BackendRepository` (see lib/services/backend_repository.dart).
/// It is kept only as a reference/example of the original demo shapes;
/// it is intentionally not imported by any production code path.
class MockData {
  MockData._();

  static const AppUser currentStudent = AppUser(
    name: 'Aarav Sharma',
    title: 'B.Tech CSE, Final Year',
    role: UserRole.student,
    avatarInitials: 'AS',
    careerHealthScore: 78,
    placementReadiness: 64,
  );

  static const List<CareerPath> careerPaths = [
    CareerPath(
      title: 'Data Analyst',
      description: 'Turn raw data into actionable business insights using SQL, Python & visualization tools.',
      matchPercent: 92,
      keySkills: ['SQL', 'Python', 'Power BI', 'Statistics'],
      icon: 'insights',
    ),
    CareerPath(
      title: 'Frontend Developer',
      description: 'Build delightful, responsive user interfaces with modern web frameworks.',
      matchPercent: 87,
      keySkills: ['React', 'JavaScript', 'UI Design', 'CSS'],
      icon: 'code',
    ),
    CareerPath(
      title: 'Product Analyst',
      description: 'Bridge data and product strategy to guide feature decisions.',
      matchPercent: 81,
      keySkills: ['Analytics', 'A/B Testing', 'SQL', 'Communication'],
      icon: 'trending_up',
    ),
    CareerPath(
      title: 'Cloud Engineer',
      description: 'Design and manage scalable cloud infrastructure on AWS/Azure.',
      matchPercent: 74,
      keySkills: ['AWS', 'Linux', 'Docker', 'Networking'],
      icon: 'cloud',
    ),
  ];

  static const List<SkillItem> skillMatrix = [
    SkillItem(name: 'Python Programming', progress: 0.86, level: 'Advanced'),
    SkillItem(name: 'SQL & Databases', progress: 0.72, level: 'Intermediate'),
    SkillItem(name: 'Data Visualization', progress: 0.58, level: 'Intermediate'),
    SkillItem(name: 'Machine Learning', progress: 0.34, level: 'Beginner', isGap: true),
    SkillItem(name: 'Communication', progress: 0.65, level: 'Intermediate'),
    SkillItem(name: 'System Design', progress: 0.21, level: 'Beginner', isGap: true),
    SkillItem(name: 'Git & Version Control', progress: 0.79, level: 'Advanced'),
  ];

  static const List<CourseRecommendation> recommendedCourses = [
    CourseRecommendation(title: 'Machine Learning Foundations', provider: 'Coursera', duration: '6 weeks', rating: 4.8),
    CourseRecommendation(title: 'System Design Primer', provider: 'Career Matrix Academy', duration: '4 weeks', rating: 4.6),
    CourseRecommendation(title: 'Advanced SQL for Analysts', provider: 'Udemy', duration: '3 weeks', rating: 4.7),
  ];

  static const List<MentorProfile> mentors = [
    MentorProfile(name: 'Priya Nair', role: 'Senior Data Scientist', company: 'Google', domain: 'Data Science', experienceYears: 7, matchPercent: 95, rating: 4.9, initials: 'PN'),
    MentorProfile(name: 'Rohan Mehta', role: 'Product Manager', company: 'Microsoft', domain: 'Product', experienceYears: 6, matchPercent: 88, rating: 4.8, initials: 'RM'),
    MentorProfile(name: 'Sanya Kapoor', role: 'Frontend Lead', company: 'Flipkart', domain: 'Web Development', experienceYears: 5, matchPercent: 84, rating: 4.7, initials: 'SK'),
    MentorProfile(name: 'Arjun Verma', role: 'Cloud Architect', company: 'Amazon', domain: 'Cloud Computing', experienceYears: 9, matchPercent: 79, rating: 4.9, initials: 'AV'),
    MentorProfile(name: 'Meera Iyer', role: 'HR Business Partner', company: 'TCS', domain: 'Career Coaching', experienceYears: 10, matchPercent: 76, rating: 4.6, initials: 'MI'),
  ];

  static const List<JobListing> jobs = [
    JobListing(title: 'Data Analyst', company: 'Flipkart', location: 'Bengaluru', type: 'Full-time', salary: '₹8–12 LPA', matchPercent: 91, tags: ['SQL', 'Python', 'Tableau'], postedAgo: '2d ago'),
    JobListing(title: 'Software Engineer', company: 'Infosys', location: 'Pune', type: 'Full-time', salary: '₹6–9 LPA', matchPercent: 85, tags: ['Java', 'Spring Boot'], postedAgo: '4d ago'),
    JobListing(title: 'Frontend Developer', company: 'Zomato', location: 'Gurugram', type: 'Full-time', salary: '₹10–14 LPA', matchPercent: 82, tags: ['React', 'TypeScript'], postedAgo: '1w ago'),
    JobListing(title: 'Business Analyst', company: 'Deloitte', location: 'Mumbai', type: 'Full-time', salary: '₹7–10 LPA', matchPercent: 77, tags: ['Excel', 'Power BI'], postedAgo: '3d ago'),
  ];

  static const List<JobListing> internships = [
    JobListing(title: 'Data Science Intern', company: 'Google', location: 'Remote', type: 'Internship', salary: '₹50k/mo', matchPercent: 94, tags: ['Python', 'ML'], postedAgo: '1d ago'),
    JobListing(title: 'Product Intern', company: 'Swiggy', location: 'Bengaluru', type: 'Internship', salary: '₹35k/mo', matchPercent: 80, tags: ['Analytics', 'Strategy'], postedAgo: '2d ago'),
    JobListing(title: 'UI/UX Design Intern', company: 'Razorpay', location: 'Remote', type: 'Internship', salary: '₹25k/mo', matchPercent: 73, tags: ['Figma', 'UI Design'], postedAgo: '5d ago'),
  ];

  static const List<ForumPost> forumPosts = [
    ForumPost(author: 'Karthik Raja', role: 'Alumni · Amazon', title: 'My SDE-1 interview experience at Amazon', preview: 'Shared the full loop — 4 rounds, DSA + LLD + behavioral. Here is what worked...', likes: 128, comments: 34, timeAgo: '3h ago'),
    ForumPost(author: 'Divya Menon', role: 'Mentor · Google', title: 'How to crack case-study rounds in product interviews', preview: 'A structured framework I use with all my mentees before interviews...', likes: 96, comments: 21, timeAgo: '1d ago'),
    ForumPost(author: 'Student Council', role: 'Community', title: 'Career Matrix Hackathon — Registrations open!', preview: 'Build an AI project in 48 hours and get a chance to intern with top partners.', likes: 210, comments: 58, timeAgo: '2d ago'),
  ];

  static const List<NotificationItem> notifications = [
    NotificationItem(title: 'New job match found', subtitle: 'Data Analyst @ Flipkart matches 91% of your profile', timeAgo: '10m ago', type: 'job', unread: true),
    NotificationItem(title: 'Mentor session confirmed', subtitle: 'Priya Nair accepted your session request for Fri, 5 PM', timeAgo: '1h ago', type: 'mentor', unread: true),
    NotificationItem(title: 'Skill roadmap updated', subtitle: 'New milestone added to your Machine Learning track', timeAgo: '3h ago', type: 'system', unread: false),
    NotificationItem(title: 'New comment on your post', subtitle: 'Rohan Mehta replied to your interview experience thread', timeAgo: '1d ago', type: 'community', unread: false),
  ];

  static const List<InterviewSession> interviewSessions = [
    InterviewSession(title: 'Data Structures & Algorithms', type: 'Technical', difficulty: 'Medium', durationMins: 45, lastScore: 78),
    InterviewSession(title: 'System Design Basics', type: 'Technical', difficulty: 'Hard', durationMins: 60, lastScore: 62),
    InterviewSession(title: 'HR & Behavioral Round', type: 'HR', difficulty: 'Easy', durationMins: 30, lastScore: 85),
    InterviewSession(title: 'SQL & Databases', type: 'Technical', difficulty: 'Medium', durationMins: 40, lastScore: 0),
  ];

  static const List<CandidateProfile> candidates = [
    CandidateProfile(name: 'Ishaan Gupta', course: 'B.Tech CSE', college: 'NIT Trichy', matchPercent: 93, skills: ['Python', 'SQL', 'ML'], initials: 'IG'),
    CandidateProfile(name: 'Neha Reddy', course: 'B.Tech IT', college: 'VIT Vellore', matchPercent: 89, skills: ['React', 'Node.js'], initials: 'NR'),
    CandidateProfile(name: 'Farhan Ali', course: 'MCA', college: 'Anna University', matchPercent: 84, skills: ['Java', 'Spring'], initials: 'FA'),
    CandidateProfile(name: 'Ritika Joshi', course: 'B.Tech ECE', college: 'BITS Pilani', matchPercent: 80, skills: ['Embedded', 'C++'], initials: 'RJ'),
  ];
}
