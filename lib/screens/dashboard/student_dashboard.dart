import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/score_gauge.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/listing_cards.dart';
import '../career/career_recommendation_screen.dart';
import '../skills/skill_gap_screen.dart';
import '../resume/resume_hub_screen.dart';
import '../jobs/job_portal_screen.dart';
import '../internship/internship_portal_screen.dart';
import '../interview/mock_interview_screen.dart';
import '../mentor/mentor_connect_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

class _DashboardData {
  final AppUser user;
  final List<CareerPath> careerPaths;
  final List<MentorProfile> mentors;
  _DashboardData({required this.user, required this.careerPaths, required this.mentors});
}

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final results = await Future.wait([
      BackendRepository.instance.getMyAppUser(),
      BackendRepository.instance.getCareerPaths().catchError((_) => <CareerPath>[]),
      BackendRepository.instance.getMentors().catchError((_) => <MentorProfile>[]),
    ]);
    return _DashboardData(
      user: results[0] as AppUser,
      careerPaths: results[1] as List<CareerPath>,
      mentors: results[2] as List<MentorProfile>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => setState(() { _future = _load(); }), child: const Text('Retry')),
                  ],
                ),
              ),
            ),
          );
        }
        final data = snapshot.data!;
        return _StudentDashboardBody(data: data);
      },
    );
  }
}

class _StudentDashboardBody extends StatelessWidget {
  final _DashboardData data;
  const _StudentDashboardBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final user = data.user;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    child: InitialsAvatar(initials: user.avatarInitials, size: 48),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Welcome back 👋', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                        Text(user.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      ],
                    ),
                  ),
                  _NotifBell(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Career Health Score hero card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 12))],
                ),
                child: Row(
                  children: [
                    ScoreGauge(
                      score: user.careerHealthScore,
                      size: 92,
                      label: 'SCORE',
                      color: Colors.white,
                      trackColor: Colors.white24,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Career Health Score', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text(
                            'Great progress! Improve Machine Learning skills to boost your score further.',
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12.5, height: 1.4),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CareerRecommendationScreen())),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('View Compass', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12.5)),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick actions grid (2-3 tap access to every feature)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(title: 'Quick Actions'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
  crossAxisCount: 4,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  mainAxisSpacing: 14,
  crossAxisSpacing: 10,
  childAspectRatio: 0.95,
  children: [
                  _QuickAction(icon: Icons.explore_rounded, label: 'Compass', color: AppColors.primary,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CareerRecommendationScreen()))),
                  _QuickAction(icon: Icons.grid_view_rounded, label: 'Skills', color: AppColors.accentIndigo,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SkillGapScreen()))),
                  _QuickAction(icon: Icons.description_rounded, label: 'Resume', color: AppColors.accentCyan,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResumeHubScreen()))),
                  _QuickAction(icon: Icons.work_rounded, label: 'Jobs', color: AppColors.success,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JobPortalScreen()))),
                  _QuickAction(icon: Icons.mic_rounded, label: 'Interview', color: AppColors.warning,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MockInterviewScreen()))),
                  _QuickAction(icon: Icons.diversity_3_rounded, label: 'Mentors', color: AppColors.primaryDark,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MentorConnectScreen()))),
                  _QuickAction(icon: Icons.school_rounded, label: 'Internships', color: AppColors.accentIndigo,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InternshipPortalScreen()))),
                  _QuickAction(icon: Icons.person_rounded, label: 'Profile', color: AppColors.textSecondary,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()))),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Placement readiness + opportunity match row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: AppCard(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SkillGapScreen())),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.rocket_launch_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(child: Text('Placement\nReadiness', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: user.placementReadiness / 100,
                              minHeight: 8,
                              backgroundColor: AppColors.surfaceMuted,
                              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('${user.placementReadiness}% Ready', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JobPortalScreen())),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bolt_rounded, color: AppColors.success, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(child: Text('Opportunity\nMatch Score', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: const LinearProgressIndicator(
                              value: 0.91,
                              minHeight: 8,
                              backgroundColor: AppColors.surfaceMuted,
                              valueColor: AlwaysStoppedAnimation(AppColors.success),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text('91% Top Match', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.success)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Top career match preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(
                title: 'Recommended Careers',
                actionLabel: 'See all',
                onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CareerRecommendationScreen())),
              ),
            ),
            if (data.careerPaths.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(14)),
                  child: const Text(
                    'Add a few skills to get personalized career matches.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                  ),
                ),
              )
            else
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: data.careerPaths.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final c = data.careerPaths[i];
                  return SizedBox(
                    width: 210,
                    child: AppCard(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CareerRecommendationScreen())),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                                child: Icon(_iconFor(c.icon), color: AppColors.primary, size: 18),
                              ),
                              const Spacer(),
                              AppTag(label: '${c.matchPercent}%', bg: AppColors.successSoft, fg: AppColors.success),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(c.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 6),
                          Text(c.description, maxLines: 3, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.35)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Mentor teaser
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(
                title: 'Mentors For You',
                actionLabel: 'See all',
                onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MentorConnectScreen())),
              ),
            ),
            if (data.mentors.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MentorCard(
                  mentor: data.mentors.first,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MentorConnectScreen())),
                  onBook: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MentorConnectScreen())),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(14)),
                  child: const Text('No mentors available yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                ),
              ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(String key) {
  switch (key) {
    case 'insights':
      return Icons.insights_rounded;
    case 'code':
      return Icons.code_rounded;
    case 'trending_up':
      return Icons.trending_up_rounded;
    case 'cloud':
      return Icons.cloud_rounded;
    default:
      return Icons.star_rounded;
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
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

class _NotifBell extends StatelessWidget {
  final VoidCallback onTap;
  const _NotifBell({required this.onTap});

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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
