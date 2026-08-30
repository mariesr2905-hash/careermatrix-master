import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import '../mentor/mentor_connect_screen.dart';
import '../jobs/job_portal_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../community/community_screen.dart';

class AlumniDashboard extends StatelessWidget {
  const AlumniDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  child: InitialsAvatar(initials: 'KR', size: 48, gradient: AppColors.roleGradient('alumni')),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back 👋', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      Text('Karthik Raja', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    ],
                  ),
                ),
                _Bell(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.roleGradient('alumni'),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.28), blurRadius: 24, offset: const Offset(0, 12))],
              ),
              child: const Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 34),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Give back to your alma mater', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15.5)),
                        SizedBox(height: 6),
                        Text('You have mentored 12 students and shared 3 interview experiences.',
                            style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Quick Actions'),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 10,
              childAspectRatio: 0.82,
              children: [
                _Action(icon: Icons.diversity_3_rounded, label: 'Mentees', color: AppColors.primary,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MentorConnectScreen()))),
                _Action(icon: Icons.forum_rounded, label: 'Community', color: AppColors.accentIndigo,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityScreen()))),
                _Action(icon: Icons.work_rounded, label: 'Refer Jobs', color: AppColors.success,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JobPortalScreen()))),
                _Action(icon: Icons.person_rounded, label: 'Profile', color: AppColors.textSecondary,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _StatCard(icon: Icons.groups_rounded, value: '12', label: 'Students Mentored')),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(icon: Icons.star_rounded, value: '4.9', label: 'Mentor Rating')),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Upcoming Sessions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 14),
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.videocam_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mock Interview with Aarav Sharma', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        Text('Today, 5:00 PM · 30 mins', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  AppTag(label: 'Join', bg: AppColors.successSoft, fg: AppColors.success),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bell extends StatelessWidget {
  final VoidCallback onTap;
  const _Bell({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Notifications',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
