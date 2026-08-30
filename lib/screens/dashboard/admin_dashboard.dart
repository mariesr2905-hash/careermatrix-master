import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/user_management_screen.dart';
import '../admin/approval_requests_screen.dart';
import '../admin/content_moderation_screen.dart';
import '../admin/analytics_reports_screen.dart';
import '../admin/admin_system_settings_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = BackendRepository.instance.getAdminDashboardStats();
  }

  void _refresh() {
    setState(() {
      _statsFuture = BackendRepository.instance.getAdminDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Role protection
    final currentRole = AppState.instance.currentRole.value;
    if (currentRole != UserRole.admin) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gpp_bad_rounded, size: 64, color: AppColors.danger),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('You do not have permission to access the Admin console.'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _statsFuture,
            builder: (context, snapshot) {
              final loading = snapshot.connectionState == ConnectionState.waiting;
              final hasError = snapshot.hasError;
              final stats = snapshot.data;

              // Fallbacks
              final studentsVal = stats != null ? stats['students']?.toString() ?? '0' : (loading ? '...' : '0');
              final alumniVal = stats != null ? stats['alumni']?.toString() ?? '0' : (loading ? '...' : '0');
              final mentorsVal = stats != null ? stats['mentors']?.toString() ?? '0' : (loading ? '...' : '0');
              final companiesVal = stats != null ? stats['companies']?.toString() ?? '0' : (loading ? '...' : '0');
              final jobsVal = stats != null ? stats['jobs']?.toString() ?? '0' : (loading ? '...' : '0');
              final internshipsVal = stats != null ? stats['internships']?.toString() ?? '0' : (loading ? '...' : '0');
              final applicationsVal = stats != null 
                  ? ((stats['jobApplications'] ?? 0) + (stats['internshipApplications'] ?? 0)).toString() 
                  : (loading ? '...' : '0');

              final placementRate = stats != null ? (stats['placementRate'] as num?)?.toDouble() ?? 0.0 : 0.0;
              final sessionCompletion = stats != null ? (stats['sessionCompletion'] as num?)?.toDouble() ?? 0.0 : 0.0;
              final avgCareerScore = stats != null ? (stats['avgCareerHealth'] as num?)?.toDouble() ?? 0.0 : 0.0;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        ),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.roleGradient('admin'),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ecosystem Overview',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                            Row(
                              children: [
                                const Text('Admin Console', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                                if (loading)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Tooltip(
                        message: 'Notifications',
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          ),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.notifications_none_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hasError) ...[
                    const SizedBox(height: 20),
                    AppCard(
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 36),
                          const SizedBox(height: 8),
                          Text('Failed to load stats: ${snapshot.error}', textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text('Platform Statistics', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    children: [
                      _StatBlock(
                        value: studentsVal,
                        label: 'Students',
                        icon: Icons.school_rounded,
                        color: AppColors.primary,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const UserManagementScreen(initialTab: 1)),
                        ).then((_) => _refresh()),
                      ),
                      _StatBlock(
                        value: alumniVal,
                        label: 'Alumni',
                        icon: Icons.workspace_premium_rounded,
                        color: AppColors.accentIndigo,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const UserManagementScreen(initialTab: 2)),
                        ).then((_) => _refresh()),
                      ),
                      _StatBlock(
                        value: mentorsVal,
                        label: 'Mentors',
                        icon: Icons.diversity_3_rounded,
                        color: AppColors.accentCyan,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const UserManagementScreen(initialTab: 3)),
                        ).then((_) => _refresh()),
                      ),
                      _StatBlock(
                        value: companiesVal,
                        label: 'Companies',
                        icon: Icons.apartment_rounded,
                        color: AppColors.success,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const UserManagementScreen(initialTab: 4)),
                        ).then((_) => _refresh()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Additional Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: AppCard(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${int.tryParse(jobsVal) ?? 0} Jobs / ${int.tryParse(internshipsVal) ?? 0} Internships', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              const Text('Active Listings', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppCard(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(applicationsVal, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              const Text('Total Applications', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text('Platform Health', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  const SizedBox(height: 14),
                  AppCard(
                    child: Column(
                      children: [
                        _MetricRow(label: 'Placement Success Rate', value: placementRate, color: AppColors.success),
                        const SizedBox(height: 14),
                        _MetricRow(label: 'Mentor Session Completion', value: sessionCompletion, color: AppColors.primary),
                        const SizedBox(height: 14),
                        _MetricRow(label: 'Avg. Career Health Score', value: avgCareerScore, color: AppColors.accentIndigo),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('Management', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  const SizedBox(height: 14),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _ManageRow(
                          icon: Icons.people_alt_rounded,
                          label: 'Manage Users & Roles',
                          subtitle: 'View, edit roles & manage accounts',
                          color: AppColors.primary,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const UserManagementScreen(initialTab: 0)),
                          ).then((_) => _refresh()),
                        ),
                        const Divider(height: 1, indent: 56),
                        _ManageRow(
                          icon: Icons.verified_user_rounded,
                          label: 'Approval Requests',
                          subtitle: 'Approve or reject registration requests',
                          color: AppColors.accentIndigo,
                          badgeCount: stats != null ? (stats['pendingApprovals'] as num?)?.toInt() ?? 0 : 0,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ApprovalRequestsScreen()),
                          ).then((_) => _refresh()),
                        ),
                        const Divider(height: 1, indent: 56),
                        _ManageRow(
                          icon: Icons.fact_check_rounded,
                          label: 'Content Moderation',
                          subtitle: 'Review and moderate community posts',
                          color: AppColors.warning,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ContentModerationScreen()),
                          ),
                        ),
                        const Divider(height: 1, indent: 56),
                        _ManageRow(
                          icon: Icons.bar_chart_rounded,
                          label: 'Analytics & Reports',
                          subtitle: 'Platform statistics and performance data',
                          color: AppColors.accentCyan,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AnalyticsReportsScreen()),
                          ),
                        ),
                        const Divider(height: 1, indent: 56),
                        _ManageRow(
                          icon: Icons.settings_rounded,
                          label: 'System Settings',
                          subtitle: 'Configure platform preferences & security',
                          color: AppColors.textSecondary,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminSystemSettingsScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatBlock({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MetricRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text('${(value * 100).round()}%', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: AppColors.surfaceMuted,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _ManageRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? color;
  final int badgeCount;
  final VoidCallback onTap;

  const _ManageRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.color,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

