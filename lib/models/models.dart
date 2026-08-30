/// Core mock models for Career Matrix frontend.

enum UserRole { student, alumni, mentor, company, admin }

extension UserRoleX on UserRole {
  String get key => toString().split('.').last;

  static UserRole fromKey(String value) {
    return UserRole.values.firstWhere(
      (r) => r.key.toLowerCase() == value.toLowerCase(),
      orElse: () => UserRole.student,
    );
  }

  String get label {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.alumni:
        return 'Alumni';
      case UserRole.mentor:
        return 'Mentor';
      case UserRole.company:
        return 'Company';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get tagline {
    switch (this) {
      case UserRole.student:
        return 'Discover your ideal career path';
      case UserRole.alumni:
        return 'Give back, mentor & network';
      case UserRole.mentor:
        return 'Guide the next generation';
      case UserRole.company:
        return 'Hire top emerging talent';
      case UserRole.admin:
        return 'Manage the ecosystem';
    }
  }
}

class AppUser {
  final String name;
  final String title;
  final UserRole role;
  final String avatarInitials;
  final int careerHealthScore;
  final int placementReadiness;

  const AppUser({
    required this.name,
    required this.title,
    required this.role,
    required this.avatarInitials,
    this.careerHealthScore = 78,
    this.placementReadiness = 64,
  });

  /// Builds an [AppUser] from the backend's `/api/auth/me` + `/api/profile/me`
  /// responses. [careerHealthScore]/[placementReadiness] have no backend
  /// equivalent (no such fields exist in the Mongo schema yet) so they stay
  /// as reasonable placeholders until that feature is added server-side.
  factory AppUser.fromJson(Map<String, dynamic> user, {Map<String, dynamic>? profile}) {
    final name = (user['name'] as String?)?.trim() ?? 'Guest User';
    final role = UserRoleX.fromKey(user['role'] as String? ?? 'student');
    final title = profile != null
        ? [profile['currentPosition'], profile['company']]
            .where((e) => e != null && (e as String).isNotEmpty)
            .join(' · ')
        : '';
    return AppUser(
      name: name,
      title: title.isNotEmpty ? title : role.label,
      role: role,
      avatarInitials: _initialsOf(name),
    );
  }
}

String _initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}

String _timeAgo(String? isoDate) {
  if (isoDate == null) return '';
  final date = DateTime.tryParse(isoDate);
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

class CareerPath {
  final String title;
  final String description;
  final int matchPercent;
  final List<String> keySkills;
  final String icon; // material icon codepoint name key

  const CareerPath({
    required this.title,
    required this.description,
    required this.matchPercent,
    required this.keySkills,
    required this.icon,
  });

  /// Maps one entry of the backend's CareerRecommendation.recommendations[]
  /// (GET /api/career/recommendations/latest) to a [CareerPath].
  factory CareerPath.fromJson(Map<String, dynamic> json) {
    return CareerPath(
      title: json['role'] as String? ?? 'Career Path',
      description: (json['reason'] as String?)?.isNotEmpty == true
          ? json['reason'] as String
          : 'Recommended based on your current skill profile.',
      matchPercent: (json['matchScore'] as num?)?.round() ?? 0,
      keySkills: (json['matchedSkills'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      icon: 'insights',
    );
  }
}

class SkillItem {
  final String? id;
  final String name;
  final double progress; // 0..1
  final String level; // Beginner / Intermediate / Advanced
  final bool isGap;

  const SkillItem({
    this.id,
    required this.name,
    required this.progress,
    required this.level,
    this.isGap = false,
  });

  /// Maps a backend Skill document (GET /api/skills/me) to a [SkillItem].
  /// The backend stores a discrete `proficiencyLevel` (no 0..1 progress
  /// value), so progress is derived from it for the progress-bar UI.
  factory SkillItem.fromJson(Map<String, dynamic> json) {
    final level = json['proficiencyLevel'] as String? ?? 'Beginner';
    const progressByLevel = {
      'Beginner': 0.25,
      'Intermediate': 0.55,
      'Advanced': 0.8,
      'Expert': 0.97,
    };
    return SkillItem(
      id: (json['_id'] ?? json['id'])?.toString(),
      name: json['skillName'] as String? ?? 'Skill',
      progress: progressByLevel[level] ?? 0.25,
      level: level,
      isGap: level == 'Beginner',
    );
  }
}

class EducationRecord {
  final String? id;
  final String institution;
  final String degree;
  final String? department;
  final String? course;
  final int startYear;
  final int? endYear;
  final String? grade;

  const EducationRecord({
    this.id,
    required this.institution,
    required this.degree,
    this.department,
    this.course,
    required this.startYear,
    this.endYear,
    this.grade,
  });

  factory EducationRecord.fromJson(Map<String, dynamic> json) {
    return EducationRecord(
      id: (json['_id'] ?? json['id'])?.toString(),
      institution: json['institution'] as String? ?? '',
      degree: json['degree'] as String? ?? '',
      department: json['department'] as String?,
      course: json['course'] as String?,
      startYear: (json['startYear'] as num?)?.toInt() ?? DateTime.now().year,
      endYear: (json['endYear'] as num?)?.toInt(),
      grade: json['grade'] as String?,
    );
  }
}

class CertificateItem {
  final String id;
  final String title;
  final String? issuer;
  final DateTime? issueDate;
  final String originalName;
  final int? fileSizeBytes;
  final DateTime? createdAt;

  const CertificateItem({
    required this.id,
    required this.title,
    this.issuer,
    this.issueDate,
    required this.originalName,
    this.fileSizeBytes,
    this.createdAt,
  });

  factory CertificateItem.fromJson(Map<String, dynamic> json) {
    return CertificateItem(
      id: (json['_id'] ?? json['id']).toString(),
      title: json['title'] as String? ?? 'Certificate',
      issuer: json['issuer'] as String?,
      issueDate: json['issueDate'] != null ? DateTime.tryParse(json['issueDate'] as String) : null,
      originalName: json['originalName'] as String? ?? 'certificate',
      fileSizeBytes: (json['fileSize'] as num?)?.toInt(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}

class ApplicationRecord {
  final String id;
  final String type; // 'Job' or 'Internship'
  final String title;
  final String company;
  final String location;
  final String status; // Applied / Shortlisted / Rejected / Selected
  final DateTime? appliedAt;

  const ApplicationRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.company,
    required this.location,
    required this.status,
    this.appliedAt,
  });

  factory ApplicationRecord.fromJobJson(Map<String, dynamic> json) {
    final job = json['job'] as Map<String, dynamic>?;
    return ApplicationRecord(
      id: (json['_id'] ?? json['id']).toString(),
      type: 'Job',
      title: job?['title'] as String? ?? 'Job listing removed',
      company: job?['company'] as String? ?? '—',
      location: job?['location'] as String? ?? '—',
      status: json['status'] as String? ?? 'Applied',
      appliedAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }

  factory ApplicationRecord.fromInternshipJson(Map<String, dynamic> json) {
    final internship = json['internship'] as Map<String, dynamic>?;
    return ApplicationRecord(
      id: (json['_id'] ?? json['id']).toString(),
      type: 'Internship',
      title: internship?['title'] as String? ?? 'Internship listing removed',
      company: internship?['company'] as String? ?? '—',
      location: internship?['location'] as String? ?? '—',
      status: json['status'] as String? ?? 'Applied',
      appliedAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}

class CourseRecommendation {
  final String title;
  final String provider;
  final String duration;
  final double rating;

  const CourseRecommendation({
    required this.title,
    required this.provider,
    required this.duration,
    required this.rating,
  });

  /// Maps a backend course-catalog entry (GET /api/career/courses,
  /// deterministically derived from the user's weak skills) to a
  /// [CourseRecommendation].
  factory CourseRecommendation.fromJson(Map<String, dynamic> json) {
    return CourseRecommendation(
      title: json['title'] as String? ?? 'Course',
      provider: json['provider'] as String? ?? '—',
      duration: json['duration'] as String? ?? '—',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
    );
  }
}

class MentorProfile {
  final String name;
  final String role;
  final String company;
  final String domain;
  final int experienceYears;
  final int matchPercent;
  final double rating;
  final String initials;

  final String? id;

  const MentorProfile({
    this.id,
    required this.name,
    required this.role,
    required this.company,
    required this.domain,
    required this.experienceYears,
    required this.matchPercent,
    required this.rating,
    required this.initials,
  });

  /// Maps a backend Mentor document (GET /api/mentors, `user` populated
  /// with name/email/role) to a [MentorProfile]. There's no real
  /// "match %" concept server-side yet, so it's derived from rating as a
  /// reasonable stand-in until a real matching algorithm exists.
  factory MentorProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final name = user?['name'] as String? ?? 'Mentor';
    final expertise = (json['expertise'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    final rating = (json['rating'] as num?)?.toDouble() ?? 0;
    return MentorProfile(
      id: (json['_id'] ?? json['id'])?.toString(),
      name: name,
      role: json['currentPosition'] as String? ?? 'Mentor',
      company: json['currentCompany'] as String? ?? '—',
      domain: expertise.isNotEmpty ? expertise.first : 'General',
      experienceYears: (json['experienceYears'] as num?)?.round() ?? 0,
      matchPercent: (60 + rating * 8).clamp(0, 99).round(),
      rating: rating,
      initials: _initialsOf(name),
    );
  }
}

class JobListing {
  final String title;
  final String company;
  final String location;
  final String type; // Full-time, Internship
  final String salary;
  final int matchPercent;
  final List<String> tags;
  final String postedAgo;

  final String? id;

  const JobListing({
    this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.type,
    required this.salary,
    required this.matchPercent,
    required this.tags,
    required this.postedAgo,
  });

  /// Maps a backend Job document (GET /api/jobs) to a [JobListing].
  /// `matchScore` is now computed server-side (real skill-overlap logic)
  /// when the request is authenticated; falls back to a light heuristic
  /// only if the backend didn't include one (e.g. older cached response).
  factory JobListing.fromJson(Map<String, dynamic> json) {
    final tags = (json['skillsRequired'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    final salaryRange = json['salaryRange'] as Map<String, dynamic>?;
    String salary = 'Not disclosed';
    if (salaryRange != null && (salaryRange['min'] != null || salaryRange['max'] != null)) {
      final min = salaryRange['min'];
      final max = salaryRange['max'];
      salary = min != null && max != null ? '₹$min - ₹$max' : '₹${min ?? max}';
    }
    return JobListing(
      id: (json['_id'] ?? json['id'])?.toString(),
      title: json['title'] as String? ?? 'Job',
      company: json['company'] as String? ?? '—',
      location: json['location'] as String? ?? '—',
      type: json['jobType'] as String? ?? 'Full-time',
      salary: salary,
      matchPercent: (json['matchScore'] as num?)?.round() ?? (55 + tags.length * 6).clamp(0, 96).round(),
      tags: tags,
      postedAgo: _timeAgo(json['createdAt'] as String?),
    );
  }

  /// Maps a backend Internship document (GET /api/internships) to a
  /// [JobListing] (the UI reuses the same card model for both).
  factory JobListing.fromInternshipJson(Map<String, dynamic> json) {
    final tags = (json['skillsRequired'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    final stipend = json['stipend'];
    return JobListing(
      id: (json['_id'] ?? json['id'])?.toString(),
      title: json['title'] as String? ?? 'Internship',
      company: json['company'] as String? ?? '—',
      location: json['location'] as String? ?? '—',
      type: 'Internship',
      salary: stipend != null && stipend != 0 ? '₹$stipend/mo' : 'Unpaid',
      matchPercent: (json['matchScore'] as num?)?.round() ?? (55 + tags.length * 6).clamp(0, 96).round(),
      tags: tags,
      postedAgo: _timeAgo(json['createdAt'] as String?),
    );
  }
}

class ForumPost {
  final String? id;
  final String author;
  final String role;
  final String title;
  final String preview;
  final int likes;
  final int comments;
  final String timeAgo;
  final bool likedByMe;

  const ForumPost({
    this.id,
    required this.author,
    required this.role,
    required this.title,
    required this.preview,
    required this.likes,
    required this.comments,
    required this.timeAgo,
    this.likedByMe = false,
  });

  /// Maps a backend Post document (GET /api/community/posts, `user`
  /// populated with name/role) to a [ForumPost]. The backend has a single
  /// `content` field (no separate title), so the first line/sentence is
  /// used as a title and the full content as the preview.
  factory ForumPost.fromJson(Map<String, dynamic> json, {String? myUserId}) {
    final user = json['user'] as Map<String, dynamic>?;
    final content = json['content'] as String? ?? '';
    final firstLine = content.split(RegExp(r'[\n.]')).first.trim();
    final likesList = (json['likes'] as List?) ?? const [];
    return ForumPost(
      id: (json['_id'] ?? json['id'])?.toString(),
      author: user?['name'] as String? ?? 'Community Member',
      role: user?['role'] as String? ?? 'Member',
      title: firstLine.isNotEmpty ? firstLine : 'Community post',
      preview: content,
      likes: (json['likesCount'] as num?)?.toInt() ?? likesList.length,
      comments: (json['commentsCount'] as num?)?.toInt() ?? 0,
      timeAgo: _timeAgo(json['createdAt'] as String?),
      likedByMe: myUserId != null && likesList.any((l) => l.toString() == myUserId),
    );
  }
}

class NotificationItem {
  final String? id;
  final String title;
  final String subtitle;
  final String timeAgo;
  final String type; // job, mentor, community, system
  final bool unread;

  const NotificationItem({
    this.id,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.type,
    this.unread = false,
  });

  /// Maps a backend Notification document (GET /api/notifications/me) to a
  /// [NotificationItem].
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final backendType = json['type'] as String? ?? 'Info';
    const typeMap = {
      'JobAlert': 'job',
      'InternshipAlert': 'job',
      'MentorshipRequest': 'mentor',
      'Booking': 'mentor',
      'Community': 'community',
      'Placement': 'system',
      'System': 'system',
      'Info': 'system',
      'Other': 'system',
    };
    return NotificationItem(
      id: (json['_id'] ?? json['id'])?.toString(),
      title: json['title'] as String? ?? 'Notification',
      subtitle: json['message'] as String? ?? '',
      timeAgo: _timeAgo(json['createdAt'] as String?),
      type: typeMap[backendType] ?? 'system',
      unread: json['isRead'] != true,
    );
  }
}

class PlacementRecord {
  final String? id;
  final String company;
  final String jobTitle;
  final num? package;
  final String placementType;
  final String? location;
  final String placementDate;
  final String status;
  final String? remarks;

  const PlacementRecord({
    this.id,
    required this.company,
    required this.jobTitle,
    this.package,
    required this.placementType,
    this.location,
    required this.placementDate,
    required this.status,
    this.remarks,
  });

  /// Maps a backend Placement document (GET /api/placements/me) to a
  /// [PlacementRecord].
  factory PlacementRecord.fromJson(Map<String, dynamic> json) {
    return PlacementRecord(
      id: (json['_id'] ?? json['id'])?.toString(),
      company: json['company'] as String? ?? '—',
      jobTitle: json['jobTitle'] as String? ?? '—',
      package: json['package'] as num?,
      placementType: json['placementType'] as String? ?? 'Full-time',
      location: json['location'] as String?,
      placementDate: json['placementDate'] as String? ?? '',
      status: json['status'] as String? ?? 'Applied',
      remarks: json['remarks'] as String?,
    );
  }
}

class InterviewSession {
  final String? id;
  final String title;
  final String type; // Technical / HR
  final String difficulty;
  final int durationMins;
  final int lastScore;

  const InterviewSession({
    this.id,
    required this.title,
    required this.type,
    required this.difficulty,
    required this.durationMins,
    this.lastScore = 0,
  });

  /// Maps a backend MockInterview record (GET /api/interviews/history/me)
  /// to an [InterviewSession] for the "past attempts" list. Backend scores
  /// are 0..10, the UI shows 0..100.
  factory InterviewSession.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'Technical';
    final questions = (json['questionsAttempted'] as List?) ?? const [];
    return InterviewSession(
      id: (json['_id'] ?? json['id'])?.toString(),
      title: '$type Mock Interview',
      type: type,
      difficulty: 'Mixed',
      durationMins: (questions.length * 8).clamp(15, 90),
      lastScore: (((json['overallScore'] as num?)?.toDouble() ?? 0) * 10).round(),
    );
  }
}

class ResumeAnalysis {
  final int score;
  final List<String> strengths;
  final List<String> improvements;

  const ResumeAnalysis({required this.score, required this.strengths, required this.improvements});

  /// Maps the backend's deterministic resume-analysis response
  /// (GET /api/resume/analysis) to a [ResumeAnalysis].
  factory ResumeAnalysis.fromJson(Map<String, dynamic> json) {
    return ResumeAnalysis(
      score: (json['score'] as num?)?.round() ?? 0,
      strengths: (json['strengths'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      improvements: (json['improvements'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

class PostComment {
  final String? id;
  final String author;
  final String text;
  final String timeAgo;

  const PostComment({this.id, required this.author, required this.text, required this.timeAgo});

  /// Maps a backend Comment document (GET /api/community/posts/:id/comments)
  /// to a [PostComment].
  factory PostComment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return PostComment(
      id: (json['_id'] ?? json['id'])?.toString(),
      author: user?['name'] as String? ?? 'Community Member',
      text: json['text'] as String? ?? '',
      timeAgo: _timeAgo(json['createdAt'] as String?),
    );
  }
}

class MentorshipRequestItem {
  final String? id;
  final String mentorName;
  final String menteeName;
  final String status; // Pending, Accepted, Rejected, Cancelled
  final String? message;
  final String timeAgo;

  const MentorshipRequestItem({
    this.id,
    required this.mentorName,
    required this.menteeName,
    required this.status,
    this.message,
    required this.timeAgo,
  });

  /// Maps a backend MentorshipRequest document (GET /api/mentorship,
  /// /api/mentorship/history) to a [MentorshipRequestItem]. `mentor.user`
  /// and `requester` are populated with user info server-side.
  factory MentorshipRequestItem.fromJson(Map<String, dynamic> json) {
    final mentor = json['mentor'] as Map<String, dynamic>?;
    final mentorUser = mentor?['user'] as Map<String, dynamic>?;
    final requester = json['requester'] as Map<String, dynamic>?;
    return MentorshipRequestItem(
      id: (json['_id'] ?? json['id'])?.toString(),
      mentorName: mentorUser?['name'] as String? ?? (mentor?['name'] as String?) ?? 'Mentor',
      menteeName: requester?['name'] as String? ?? 'Student',
      status: json['status'] as String? ?? 'Pending',
      message: json['message'] as String?,
      timeAgo: _timeAgo(json['createdAt'] as String?),
    );
  }
}

class CandidateProfile {
  final String? id;
  final String name;
  final String course;
  final String college;
  final int matchPercent;
  final List<String> skills;
  final String initials;

  const CandidateProfile({
    this.id,
    required this.name,
    required this.course,
    required this.college,
    required this.matchPercent,
    required this.skills,
    required this.initials,
  });

  /// Maps a backend candidate document (GET /api/users/candidates) to a
  /// [CandidateProfile]. matchPercent is derived from how many skills the
  /// candidate has logged (a real, backend-visible signal) since there is
  /// no separate per-company matching concept server-side.
  factory CandidateProfile.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'Candidate';
    final skillsList = (json['skills'] as List?) ?? const [];
    final skillNames = skillsList.map((s) => (s as Map)['skillName']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    final profile = json['profile'] as Map<String, dynamic>?;
    return CandidateProfile(
      id: (json['_id'] ?? json['id'])?.toString(),
      name: name,
      course: profile?['currentPosition'] as String? ?? 'Student',
      college: profile?['company'] as String? ?? '—',
      matchPercent: (40 + skillNames.length * 10).clamp(0, 98).round(),
      skills: skillNames.cast<String>(),
      initials: _initialsOf(name),
    );
  }
}
