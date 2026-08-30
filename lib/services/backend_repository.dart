// lib/services/backend_repository.dart
//
// Single place every screen goes through to read/write real data from the
// Node/Express + MongoDB backend. Each method calls the matching REST
// endpoint and maps the JSON response onto the existing UI model classes
// (see lib/models/models.dart) so screens keep their original widgets and
// just swap MockData.xxx for BackendRepository.instance.xxx().

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import '../utils/file_downloader.dart';
import 'api_client.dart';
import 'auth_service.dart';

class BackendRepository {
  BackendRepository._();
  static final BackendRepository instance = BackendRepository._();
  final ApiClient _api = ApiClient.instance;

  List<Map<String, dynamic>> _list(dynamic res) {
    final data = res['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return const [];
  }

  // ---------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------

  /// Returns the merged {user, profile} for the logged-in account, or
  /// throws if not reachable. `profile` is null if the user hasn't filled
  /// one in yet (backend returns 404 for GET /api/profile/me in that case).
  Future<AppUser> getMyAppUser() async {
    final meRes = await _api.get('/auth/me');
    final user = meRes['data']['user'] as Map<String, dynamic>;
    Map<String, dynamic>? profile;
    try {
      final profileRes = await _api.get('/profile/me');
      profile = profileRes['data'] as Map<String, dynamic>?;
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
    }
    return AppUser.fromJson(user, profile: profile);
  }

  Future<Map<String, dynamic>?> getMyProfileRaw() async {
    try {
      final res = await _api.get('/profile/me');
      return res['data'] as Map<String, dynamic>?;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Creates the profile if none exists yet, otherwise updates it.
  Future<void> saveProfile(Map<String, dynamic> fields) async {
    final existing = await getMyProfileRaw();
    if (existing == null) {
      await _api.post('/profile', body: fields);
    } else {
      await _api.put('/profile', body: fields);
    }
  }

  // ---------------------------------------------------------------------
  // Skills
  // ---------------------------------------------------------------------

  Future<List<SkillItem>> getMySkills() async {
    final res = await _api.get('/skills/me');
    return _list(res).map(SkillItem.fromJson).toList();
  }

  Future<void> addSkill({
    required String skillName,
    String category = 'Technical',
    String proficiencyLevel = 'Beginner',
  }) async {
    await _api.post('/skills', body: {
      'skillName': skillName,
      'category': category,
      'proficiencyLevel': proficiencyLevel,
    });
  }

  Future<void> deleteSkill(String id) async {
    await _api.delete('/skills/$id');
  }

  // ---------------------------------------------------------------------
  // Education
  // ---------------------------------------------------------------------

  Future<List<EducationRecord>> getMyEducation() async {
    final res = await _api.get('/education/me');
    return _list(res).map(EducationRecord.fromJson).toList();
  }

  Future<void> addEducation({
    required String institution,
    required String degree,
    String? department,
    String? course,
    required int startYear,
    int? endYear,
    String? grade,
  }) async {
    await _api.post('/education', body: {
      'institution': institution,
      'degree': degree,
      if (department != null && department.isNotEmpty) 'department': department,
      if (course != null && course.isNotEmpty) 'course': course,
      'startYear': startYear,
      if (endYear != null) 'endYear': endYear,
      if (grade != null && grade.isNotEmpty) 'grade': grade,
    });
  }

  Future<void> updateEducation(
    String id, {
    String? institution,
    String? degree,
    String? department,
    String? course,
    int? startYear,
    int? endYear,
    String? grade,
  }) async {
    await _api.put('/education/$id', body: {
      if (institution != null) 'institution': institution,
      if (degree != null) 'degree': degree,
      if (department != null) 'department': department,
      if (course != null) 'course': course,
      if (startYear != null) 'startYear': startYear,
      if (endYear != null) 'endYear': endYear,
      if (grade != null) 'grade': grade,
    });
  }

  Future<void> deleteEducation(String id) async {
    await _api.delete('/education/$id');
  }

  // ---------------------------------------------------------------------
  // Certificates
  // ---------------------------------------------------------------------

  Future<List<CertificateItem>> getMyCertificates() async {
    final res = await _api.get('/certificates/me');
    return _list(res).map(CertificateItem.fromJson).toList();
  }

  /// Returns the current JWT token (for building authenticated preview URLs).
  Future<String?> getToken() => _api.token;

  Future<void> addCertificate({
    required List<int> bytes,
    required String filename,
    required String title,
    String? issuer,
    DateTime? issueDate,
  }) async {
    await _api.uploadFile(
      '/certificates',
      fieldName: 'certificate',
      bytes: bytes,
      filename: filename,
      fields: {
        'title': title,
        if (issuer != null && issuer.isNotEmpty) 'issuer': issuer,
        if (issueDate != null) 'issueDate': issueDate.toIso8601String(),
      },
    );
  }

  Future<void> deleteCertificate(String id) async {
    await _api.delete('/certificates/$id');
  }

  /// Downloads a certificate and saves it to the app's documents directory.
  /// Returns the local file path on success.
  Future<String> downloadCertificate(String id, String suggestedFileName) async {
    final token = await _api.token;
    final uri = Uri.parse('${AppConfig.baseUrl}/certificates/$id/download');
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      if (token != null) request.headers.set('Authorization', 'Bearer $token');
      final response = await request.close();
      if (response.statusCode != 200) {
        final body = await response.transform(const Utf8Decoder()).join();
        String message = 'Could not download certificate (${response.statusCode})';
        try {
          final decoded = jsonDecode(body) as Map<String, dynamic>;
          message = decoded['message'] as String? ?? message;
        } catch (_) {}
        throw ApiException(message, response.statusCode);
      }
      final bytes = await response.fold<List<int>>(<int>[], (acc, chunk) => acc..addAll(chunk));
      final dir = await getApplicationDocumentsDirectory();
      String filename = suggestedFileName;
      final disposition = response.headers.value('content-disposition');
      if (disposition != null) {
        final match = RegExp('filename="?([^"]+)"?').firstMatch(disposition);
        if (match != null) filename = match.group(1)!;
      }
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      return file.path;
    } finally {
      client.close();
    }
  }

  // ---------------------------------------------------------------------
  // Career recommendations
  // ---------------------------------------------------------------------

  /// Fetches the latest saved recommendations; if none exist yet it tries
  /// to generate them (requires the user to have added skills first).
  /// Returns an empty list (never throws) if generation isn't possible yet
  /// so the screen can show a friendly "add skills first" state.
  Future<List<CareerPath>> getCareerPaths() async {
    try {
      final res = await _api.get('/career/recommendations/latest');
      final list = (res['data']['recommendations'] as List?) ?? const [];
      return list.cast<Map<String, dynamic>>().map(CareerPath.fromJson).toList();
    } on ApiException catch (e) {
      if (e.statusCode != 404) rethrow;
    }
    try {
      final res = await _api.post('/career/recommendations/generate');
      final list = (res['data']['recommendations'] as List?) ?? const [];
      return list.cast<Map<String, dynamic>>().map(CareerPath.fromJson).toList();
    } on ApiException catch (e) {
      if (e.statusCode == 400) return const []; // no skills added yet
      rethrow;
    }
  }

  // ---------------------------------------------------------------------
  // Candidates (company/alumni/admin browsing students)
  // ---------------------------------------------------------------------

  Future<List<CandidateProfile>> getCandidates({String? skill}) async {
    final res = await _api.get('/users/candidates', query: {
      'limit': 50,
      if (skill != null && skill.isNotEmpty) 'skill': skill,
    });
    return _list(res).map(CandidateProfile.fromJson).toList();
  }

  /// Real, backend-computed stats for a company's own postings.
  Future<({int activePostings, int totalApplications})> getMyPostingStats() async {
    final res = await _api.get('/jobs/stats/mine');
    final data = res['data'] as Map<String, dynamic>;
    return (
      activePostings: (data['activePostings'] as num?)?.toInt() ?? 0,
      totalApplications: (data['totalApplications'] as num?)?.toInt() ?? 0,
    );
  }

  // ---------------------------------------------------------------------
  // Recommended courses (deterministic, skill-gap based)
  // ---------------------------------------------------------------------

  Future<List<CourseRecommendation>> getRecommendedCourses() async {
    final res = await _api.get('/career/courses');
    return _list(res).map(CourseRecommendation.fromJson).toList();
  }

  // ---------------------------------------------------------------------
  // Admin — user management
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getAllUsersAdmin({
    String? search,
    String? role,
    String? status,
    String? department,
  }) async {
    final res = await _api.get('/users', query: {
      'limit': 100,
      if (search != null && search.isNotEmpty) 'search': search,
      if (role != null && role.isNotEmpty) 'role': role,
      if (status != null && status.isNotEmpty) 'status': status,
      if (department != null && department.isNotEmpty) 'department': department,
    });
    return _list(res);
  }

  /// Admin-only: create a new account (Student, Alumni, Mentor, Company or
  /// Admin). Stored in MongoDB via the existing User model + bcrypt hashing
  /// (POST /api/users, admin-only route).
  Future<void> createUserAdmin({
    required String name,
    required String email,
    required String password,
    String role = 'student',
    String? status,
    bool approveImmediately = false,
  }) async {
    await _api.post('/users', body: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      if (status != null) 'status': status,
      'approveImmediately': approveImmediately,
    });
  }

  Future<void> updateUserAdmin(
    String userId, {
    String? role,
    bool? isActive,
    bool? isApproved,
    String? status,
    String? rejectionReason,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? mentorProfile,
  }) async {
    await _api.put('/users/$userId', body: {
      if (role != null) 'role': role,
      if (isActive != null) 'isActive': isActive,
      if (isApproved != null) 'isApproved': isApproved,
      if (status != null) 'status': status,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (profile != null) 'profile': profile,
      if (mentorProfile != null) 'mentorProfile': mentorProfile,
    });
  }

  Future<void> deleteUserAdmin(String userId) async {
    await _api.delete('/users/$userId');
  }

  Future<String> downloadExcelTemplate(String role) async {
    final token = await _api.token;
    final url = '${AppConfig.baseUrl}/users/admin/excel/template/$role';
    return downloadResumeFile(url, token, '${role.toLowerCase()}_template.xlsx');
  }

  Future<Map<String, dynamic>> validateExcelImport({
    required String userType,
    required List<int> bytes,
    required String filename,
  }) async {
    final res = await _api.uploadFile(
      '/users/admin/excel/validate',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      fields: {'userType': userType},
    );
    return res['data'] as Map<String, dynamic>;
  }

  Future<void> confirmExcelImport({
    required String userType,
    required List<Map<String, dynamic>> records,
  }) async {
    await _api.post('/users/admin/excel/import', body: {
      'userType': userType,
      'records': records,
    });
  }

  Future<void> bulkUpdateStatus({
    required List<String> userIds,
    required String action,
    String? rejectionReason,
  }) async {
    await _api.put('/users/admin/bulk-status', body: {
      'userIds': userIds,
      'action': action,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    });
  }

  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    final res = await _api.get('/users/admin/dashboard-stats');
    return res['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminUserDetails(String userId) async {
    final res = await _api.get('/users/$userId/admin-details');
    return res['data'] as Map<String, dynamic>;
  }

  Future<String> downloadUserResumeAdmin(String userId) async {
    final token = await _api.token;
    final url = '${AppConfig.baseUrl}/resume/download/$userId';
    return downloadResumeFile(url, token, 'resume_$userId.pdf');
  }

  // ---------------------------------------------------------------------
  // Mentorship (request/accept/reject) — distinct from session Booking
  // ---------------------------------------------------------------------

  Future<void> sendMentorshipRequest(String mentorId, {String? message}) async {
    await _api.post('/mentorship/$mentorId/request', body: {
      if (message != null && message.isNotEmpty) 'message': message,
    });
  }

  Future<List<MentorshipRequestItem>> getSentMentorshipRequests() async {
    final res = await _api.get('/mentorship', query: {'role': 'sent'});
    return _list(res).map(MentorshipRequestItem.fromJson).toList();
  }

  Future<List<MentorshipRequestItem>> getReceivedMentorshipRequests() async {
    final res = await _api.get('/mentorship', query: {'role': 'received'});
    return _list(res).map(MentorshipRequestItem.fromJson).toList();
  }

  Future<void> acceptMentorshipRequest(String id) async {
    await _api.put('/mentorship/$id/accept');
  }

  Future<void> rejectMentorshipRequest(String id) async {
    await _api.put('/mentorship/$id/reject');
  }

  Future<void> cancelMentorshipRequest(String id) async {
    await _api.put('/mentorship/$id/cancel');
  }

  // ---------------------------------------------------------------------
  // Profile image
  // ---------------------------------------------------------------------

  Future<void> uploadProfileImage(List<int> bytes, String filename) async {
    await _api.uploadFile('/profile/upload-image', fieldName: 'image', bytes: bytes, filename: filename, method: 'PUT');
  }

  // ---------------------------------------------------------------------
  // Jobs
  // ---------------------------------------------------------------------

  Future<List<JobListing>> getJobs() async {
    final res = await _api.get('/jobs', query: {'limit': 50});
    return _list(res).map(JobListing.fromJson).toList();
  }

  Future<void> applyForJob(String jobId) async {
    await _api.post('/jobs/$jobId/apply', body: {});
  }

  /// Job applications submitted by the logged-in student, most recent first.
  Future<List<ApplicationRecord>> getMyJobApplications() async {
    final res = await _api.get('/jobs/applications/me');
    return _list(res).map((j) => ApplicationRecord.fromJobJson(j)).toList();
  }

  /// Posts a new job listing (company/alumni/admin only, enforced server-side).
  /// jobType must be one of Full-time/Part-time/Contract/Remote.
  Future<void> createJob({
    required String title,
    required String description,
    required String company,
    required String location,
    String jobType = 'Full-time',
    List<String> skillsRequired = const [],
    int? salaryMin,
    int? salaryMax,
  }) async {
    await _api.post('/jobs', body: {
      'title': title,
      'description': description,
      'company': company,
      'location': location,
      'jobType': jobType,
      'skillsRequired': skillsRequired,
      if (salaryMin != null || salaryMax != null)
        'salaryRange': {
          if (salaryMin != null) 'min': salaryMin,
          if (salaryMax != null) 'max': salaryMax,
        },
    });
  }

  /// Posts a new internship listing (company/alumni/admin only).
  Future<void> createInternship({
    required String title,
    required String description,
    required String company,
    required String location,
    required String duration,
    num? stipend,
    List<String> skillsRequired = const [],
  }) async {
    await _api.post('/internships', body: {
      'title': title,
      'description': description,
      'company': company,
      'location': location,
      'duration': duration,
      if (stipend != null) 'stipend': stipend,
      'skillsRequired': skillsRequired,
    });
  }

  // ---------------------------------------------------------------------
  // Internships
  // ---------------------------------------------------------------------

  Future<List<JobListing>> getInternships() async {
    final res = await _api.get('/internships', query: {'limit': 50});
    return _list(res).map(JobListing.fromInternshipJson).toList();
  }

  Future<void> applyForInternship(String internshipId) async {
    await _api.post('/internships/$internshipId/apply', body: {});
  }

  /// Internship applications submitted by the logged-in student, most recent first.
  Future<List<ApplicationRecord>> getMyInternshipApplications() async {
    final res = await _api.get('/internships/applications/me');
    return _list(res).map((j) => ApplicationRecord.fromInternshipJson(j)).toList();
  }

  // ---------------------------------------------------------------------
  // Mentors
  // ---------------------------------------------------------------------

  Future<List<MentorProfile>> getMentors() async {
    final res = await _api.get('/mentors', query: {'limit': 50});
    return _list(res).map(MentorProfile.fromJson).toList();
  }

  Future<void> bookMentorSession({
    required String mentorId,
    required DateTime sessionDate,
    required String sessionTime,
    String? topic,
  }) async {
    await _api.post('/mentors/$mentorId/book', body: {
      'sessionDate': sessionDate.toIso8601String(),
      'sessionTime': sessionTime,
      if (topic != null && topic.isNotEmpty) 'topic': topic,
    });
  }

  // ---------------------------------------------------------------------
  // Community
  // ---------------------------------------------------------------------

  Future<List<ForumPost>> getForumPosts() async {
    final myId = await AuthService.instance.currentUserId;
    final res = await _api.get('/community/posts', query: {'limit': 50});
    return _list(res).map((j) => ForumPost.fromJson(j, myUserId: myId)).toList();
  }

  Future<void> createPost(String content) async {
    await _api.post('/community/posts', body: {'content': content});
  }

  Future<void> updatePost(String postId, String content) async {
    await _api.put('/community/posts/$postId', body: {'content': content});
  }

  Future<void> deletePost(String postId) async {
    await _api.delete('/community/posts/$postId');
  }

  Future<void> toggleLikePost(String postId) async {
    await _api.put('/community/posts/$postId/like');
  }

  Future<List<PostComment>> getPostComments(String postId) async {
    final res = await _api.get('/community/posts/$postId/comments', query: {'limit': 50});
    return _list(res).map(PostComment.fromJson).toList();
  }

  Future<void> addComment(String postId, String text) async {
    await _api.post('/community/posts/$postId/comments', body: {'text': text});
  }

  Future<void> deleteComment(String commentId) async {
    await _api.delete('/community/comments/$commentId');
  }

  // ---------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------

  Future<List<NotificationItem>> getNotifications() async {
    final res = await _api.get('/notifications/me', query: {'limit': 50});
    return _list(res).map(NotificationItem.fromJson).toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _api.put('/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _api.put('/notifications/read-all');
  }

  Future<void> deleteNotification(String id) async {
    await _api.delete('/notifications/$id');
  }

  // ---------------------------------------------------------------------
  // Mock interviews
  // ---------------------------------------------------------------------

  Future<List<InterviewSession>> getInterviewHistory() async {
    final res = await _api.get('/interviews/history/me');
    return _list(res).map(InterviewSession.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> getInterviewQuestions({String? category}) async {
    final res = await _api.get('/interviews/questions', query: {
      'limit': 20,
      if (category != null) 'category': category,
    });
    return _list(res);
  }

  Future<void> saveInterviewResult({
    required String type,
    required List<Map<String, dynamic>> questionsAttempted,
    String? feedback,
  }) async {
    await _api.post('/interviews/results', body: {
      'type': type,
      'questionsAttempted': questionsAttempted,
      if (feedback != null) 'feedback': feedback,
    });
  }

  // ---------------------------------------------------------------------
  // Placement history
  // ---------------------------------------------------------------------

  Future<List<PlacementRecord>> getMyPlacementHistory() async {
    final res = await _api.get('/placements/me');
    return _list(res).map(PlacementRecord.fromJson).toList();
  }

  // ---------------------------------------------------------------------
  // Resume
  // ---------------------------------------------------------------------

  Future<void> uploadResume(List<int> bytes, String filename) async {
    await _api.uploadFile('/resume/upload', fieldName: 'resume', bytes: bytes, filename: filename);
  }

  Future<void> updateResume(List<int> bytes, String filename) async {
    await _api.uploadFile('/resume/update', fieldName: 'resume', bytes: bytes, filename: filename, method: 'PUT');
  }

  Future<void> deleteResume() async {
    await _api.delete('/resume');
  }

  /// Lightweight existence/metadata check — does NOT download file bytes.
  Future<Map<String, dynamic>?> getMyResumeMeta() async {
    try {
      final res = await _api.get('/resume/me');
      return res['data'] as Map<String, dynamic>?;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<ResumeAnalysis> getResumeAnalysis() async {
    final res = await _api.get('/resume/analysis');
    return ResumeAnalysis.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// Downloads the logged-in user's resume and saves it to the app's
  /// documents directory. Returns the local file path on success.
  Future<String> downloadResume() async {
    final token = await _api.token;
    final url = '${AppConfig.baseUrl}/resume/download';
    return downloadResumeFile(url, token, 'resume.pdf');
  }
  // ---------------------------------------------------------------------
  // Admin – Job & Internship Applications
  // ---------------------------------------------------------------------

  /// All job applications across the platform (admin only).
  Future<List<Map<String, dynamic>>> getAllJobApplicationsAdmin() async {
    final res = await _api.get('/jobs/applications/admin/all');
    return _list(res);
  }

  /// All internship applications across the platform (admin only).
  Future<List<Map<String, dynamic>>> getAllInternshipApplicationsAdmin() async {
    final res = await _api.get('/internships/applications/admin/all');
    return _list(res);
  }

  /// Update a job application's status (admin or job owner).
  Future<void> updateJobApplicationStatus(String id, String status) async {
    await _api.put('/jobs/applications/$id/status', body: {'status': status});
  }

  /// Update an internship application's status (admin or internship owner).
  Future<void> updateInternshipApplicationStatus(String id, String status) async {
    await _api.put('/internships/applications/$id/status', body: {'status': status});
  }

  // ---------------------------------------------------------------------
  // Admin – Opportunities (Jobs & Internships)
  // ---------------------------------------------------------------------

  /// Fetch all jobs (admin uses this to see every posting).
  Future<List<Map<String, dynamic>>> getAllJobsAdmin({String? status}) async {
    final query = status != null ? '?status=$status&limit=200' : '?limit=200';
    final res = await _api.get('/jobs$query');
    return _list(res);
  }

  /// Fetch all internships (admin).
  Future<List<Map<String, dynamic>>> getAllInternshipsAdmin({String? status}) async {
    final query = status != null ? '?status=$status&limit=200' : '?limit=200';
    final res = await _api.get('/internships$query');
    return _list(res);
  }

  /// Update job fields (admin / owner).
  Future<void> updateJobAdmin(String id, Map<String, dynamic> fields) async {
    await _api.put('/jobs/$id', body: fields);
  }

  /// Update internship fields (admin / owner).
  Future<void> updateInternshipAdmin(String id, Map<String, dynamic> fields) async {
    await _api.put('/internships/$id', body: fields);
  }

  /// Delete a job posting (admin / owner).
  Future<void> deleteJob(String id) async {
    await _api.delete('/jobs/$id');
  }

  /// Delete an internship posting (admin / owner).
  Future<void> deleteInternship(String id) async {
    await _api.delete('/internships/$id');
  }

  // ---------------------------------------------------------------------
  // Admin – Mentorship & Bookings
  // ---------------------------------------------------------------------

  /// All mentorship requests across the platform (admin only).
  Future<List<Map<String, dynamic>>> getAllMentorshipRequestsAdmin({String? status}) async {
    final query = status != null ? '?status=$status&limit=200' : '?limit=200';
    final res = await _api.get('/mentorship/admin/all$query');
    return _list(res);
  }

  /// All session bookings across the platform (admin only).
  Future<List<Map<String, dynamic>>> getAllBookingsAdmin() async {
    final res = await _api.get('/mentors/bookings/admin/all');
    return _list(res);
  }

  // ---------------------------------------------------------------------
  // Auth — change password
  // ---------------------------------------------------------------------

  /// Changes the logged-in user's password.
  /// Calls PUT /api/auth/change-password with {currentPassword, newPassword}.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.put('/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}
