import 'package:flutter/material.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminUserDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  late Future<Map<String, dynamic>> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _detailsFuture = BackendRepository.instance.getAdminUserDetails(widget.userId);
    });
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    final active = user['isActive'] != false;
    try {
      await BackendRepository.instance.updateUserAdmin(widget.userId, isActive: !active);
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account ${!active ? 'activated' : 'deactivated'} successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _toggleApproved(Map<String, dynamic> user) async {
    final approved = user['isApproved'] != false;
    try {
      await BackendRepository.instance.updateUserAdmin(widget.userId, isApproved: !approved);
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account ${!approved ? 'approved' : 'unapproved/rejected'} successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _editProfile(Map<String, dynamic>? profile, Map<String, dynamic>? mentorProfile, String role) async {
    final bioCtrl = TextEditingController(text: profile?['bio']?.toString() ?? mentorProfile?['bio']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: profile?['phone']?.toString() ?? '');
    final companyCtrl = TextEditingController(text: profile?['company']?.toString() ?? mentorProfile?['currentCompany']?.toString() ?? '');
    final posCtrl = TextEditingController(text: profile?['currentPosition']?.toString() ?? mentorProfile?['currentPosition']?.toString() ?? '');
    final gradYearCtrl = TextEditingController(text: profile?['graduationYear']?.toString() ?? '');

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Edit Account Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: bioCtrl, decoration: const InputDecoration(labelText: 'Bio'), maxLines: 2),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 10),
              TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company')),
              const SizedBox(height: 10),
              TextField(controller: posCtrl, decoration: const InputDecoration(labelText: 'Current Position')),
              if (role == 'student' || role == 'alumni') ...[
                const SizedBox(height: 10),
                TextField(controller: gradYearCtrl, decoration: const InputDecoration(labelText: 'Graduation Year'), keyboardType: TextInputType.number),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );

    if (updated == true) {
      try {
        final profileBody = {
          'bio': bioCtrl.text.trim(),
          'phone': phoneCtrl.text.trim(),
          'company': companyCtrl.text.trim(),
          'currentPosition': posCtrl.text.trim(),
          if (gradYearCtrl.text.isNotEmpty) 'graduationYear': int.tryParse(gradYearCtrl.text),
        };
        Map<String, dynamic>? mentorBody;
        if (role == 'mentor') {
          mentorBody = {
            'bio': bioCtrl.text.trim(),
            'currentCompany': companyCtrl.text.trim(),
            'currentPosition': posCtrl.text.trim(),
          };
        }

        await BackendRepository.instance.updateUserAdmin(
          widget.userId,
          profile: profileBody,
          mentorProfile: mentorBody,
        );
        _reload();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details saved successfully.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
        }
      }
    }
  }

  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete ${widget.userName}?'),
        content: const Text('This will permanently delete the user account and associated data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await BackendRepository.instance.deleteUserAdmin(widget.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted.')));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
        }
      }
    }
  }

  Future<void> _downloadResume() async {
    try {
      final path = await BackendRepository.instance.downloadUserResumeAdmin(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resume saved to: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: widget.userName,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _reload, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data ?? {};
          final user = (data['user'] as Map<String, dynamic>?) ?? {};
          final profile = data['profile'] as Map<String, dynamic>?;
          final skills = (data['skills'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final education = (data['education'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final resume = data['resume'] as Map<String, dynamic>?;
          final role = user['role']?.toString() ?? 'student';
          final active = user['isActive'] != false;
          final approved = user['isApproved'] != false;

          final appsObj = data['applications'] as Map<String, dynamic>?;
          final jobApps = (appsObj?['jobs'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final intApps = (appsObj?['internships'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          final mentorProfile = data['mentorProfile'] as Map<String, dynamic>?;
          final bookings = (data['bookings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final mentorshipReqs = (data['mentorshipRequests'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          final postedObj = data['postedOpportunities'] as Map<String, dynamic>?;
          final postedJobs = (postedObj?['jobs'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final postedInternships = (postedObj?['internships'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              // User Overview Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppColors.roleGradient(role),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['name']?.toString() ?? '—', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                              const SizedBox(height: 2),
                              Text(user['email']?.toString() ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  AppTag(label: role),
                                  AppTag(
                                    label: active ? 'Active' : 'Inactive',
                                  ),
                                  AppTag(
                                    label: approved ? 'Approved' : 'Pending Verification',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Action Buttons Bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _toggleActive(user),
                            icon: Icon(active ? Icons.block_rounded : Icons.check_circle_outline_rounded, size: 16),
                            label: Text(active ? 'Deactivate' : 'Activate'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _toggleApproved(user),
                            icon: Icon(approved ? Icons.highlight_off_rounded : Icons.verified_user_rounded, size: 16),
                            label: Text(approved ? 'Revoke Approval' : 'Approve Account'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _editProfile(profile, mentorProfile, role),
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Edit Details'),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _deleteUser,
                            icon: const Icon(Icons.delete_forever_rounded, color: AppColors.danger),
                            tooltip: 'Delete User',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Profile Section
              const Text('Profile Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailItem(label: 'Bio', value: profile?['bio'] ?? mentorProfile?['bio'] ?? 'No bio available'),
                    _DetailItem(label: 'Phone', value: profile?['phone'] ?? '—'),
                    _DetailItem(label: 'Company', value: profile?['company'] ?? mentorProfile?['currentCompany'] ?? '—'),
                    _DetailItem(label: 'Position', value: profile?['currentPosition'] ?? mentorProfile?['currentPosition'] ?? '—'),
                    if (profile?['graduationYear'] != null)
                      _DetailItem(label: 'Graduation Year', value: profile!['graduationYear'].toString()),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Skills Section
              const Text('Skills', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              AppCard(
                child: skills.isEmpty
                    ? const Text('No skills listed.', style: TextStyle(color: AppColors.textMuted))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skills.map((s) {
                          final name = s['skillName'] ?? '';
                          final level = s['proficiencyLevel'] ?? 'Beginner';
                          return Chip(
                            backgroundColor: AppColors.surfaceMuted,
                            label: Text('$name ($level)', style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 20),

              // Education Section
              const Text('Education', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              education.isEmpty
                  ? const AppCard(child: Text('No education details found.', style: TextStyle(color: AppColors.textMuted)))
                  : Column(
                      children: education.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e['institution'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('${e['degree'] ?? ''} ${e['course'] != null ? '• ${e['course']}' : ''}', style: const TextStyle(fontSize: 12.5)),
                              const SizedBox(height: 4),
                              Text('Years: ${e['startYear'] ?? '—'} - ${e['endYear'] ?? 'Present'}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
              const SizedBox(height: 20),

              // Resume Section
              const Text('Resume', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              AppCard(
                child: resume == null
                    ? const Text('No resume uploaded.', style: TextStyle(color: AppColors.textMuted))
                    : Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, color: AppColors.danger, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(resume['originalName'] ?? 'Resume.pdf', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                Text('Size: ${((resume['fileSize'] ?? 0) / 1024).round()} KB', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _downloadResume,
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('Download'),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),

              // Role Specific Data
              if (role == 'student' || role == 'alumni') ...[
                const Text('Job & Internship Applications', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                (jobApps.isEmpty && intApps.isEmpty)
                    ? const AppCard(child: Text('No applications submitted yet.', style: TextStyle(color: AppColors.textMuted)))
                    : Column(
                        children: [
                          ...jobApps.map((a) {
                            final job = a['job'] as Map<String, dynamic>?;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: AppCard(
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(job?['title'] ?? 'Job Application', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  subtitle: Text('${job?['company'] ?? ''} • Status: ${a['status']}'),
                                  trailing: AppTag(label: 'Job'),
                                ),
                              ),
                            );
                          }),
                          ...intApps.map((a) {
                            final i = a['internship'] as Map<String, dynamic>?;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: AppCard(
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(i?['title'] ?? 'Internship Application', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  subtitle: Text('${i?['company'] ?? ''} • Status: ${a['status']}'),
                                  trailing: AppTag(label: 'Internship'),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
              ] else if (role == 'mentor') ...[
                const Text('Mentorship Activity', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Experience: ${mentorProfile?['experienceYears'] ?? 0} years'),
                      const SizedBox(height: 6),
                      Text('Bookings: ${bookings.length} session(s)'),
                      const SizedBox(height: 6),
                      Text('Mentorship Requests: ${mentorshipReqs.length} request(s)'),
                    ],
                  ),
                ),
              ] else if (role == 'company') ...[
                const Text('Posted Opportunities', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Posted Jobs: ${postedJobs.length}'),
                      const SizedBox(height: 6),
                      Text('Posted Internships: ${postedInternships.length}'),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}
