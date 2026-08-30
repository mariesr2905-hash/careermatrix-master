import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../community/community_screen.dart';

class MentorDashboard extends StatelessWidget {
  const MentorDashboard({super.key});

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
                  child: InitialsAvatar(initials: 'PN', size: 48, gradient: AppColors.roleGradient('mentor')),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back 👋', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      Text('Priya Nair', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Notifications',
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
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
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _Stat(value: '18', label: 'Active Mentees', icon: Icons.groups_rounded, color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: _Stat(value: '4.9', label: 'Rating', icon: Icons.star_rounded, color: AppColors.warning)),
                const SizedBox(width: 12),
                Expanded(child: _Stat(value: '92%', label: 'Match Score', icon: Icons.bolt_rounded, color: AppColors.success)),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Today's Sessions", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                children: [
                  _SessionRow(name: 'Aarav Sharma', topic: 'Career roadmap for Data Science', time: '5:00 PM'),
                  const Divider(height: 24),
                  _SessionRow(name: 'Neha Reddy', topic: 'Mock interview feedback', time: '6:30 PM'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Mentee Requests', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 14),
            AppCard(
              child: Row(
                children: [
                  const InitialsAvatar(initials: 'FA', size: 44),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Farhan Ali', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                        Text('Wants guidance on Cloud Computing', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14), textStyle: const TextStyle(fontSize: 12.5)),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityScreen())),
              child: const Row(
                children: [
                  Icon(Icons.forum_rounded, color: AppColors.accentIndigo),
                  SizedBox(width: 12),
                  Expanded(child: Text('Share an interview experience with the community', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5))),
                  Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _Stat({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final String name;
  final String topic;
  final String time;
  const _SessionRow({required this.name, required this.topic, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InitialsAvatar(initials: name.split(' ').map((e) => e[0]).take(2).join(), size: 42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Text(topic, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
        AppTag(label: time, bg: AppColors.primarySoft),
      ],
    );
  }
}
