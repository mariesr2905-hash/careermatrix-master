import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../company/company_portal_screen.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({super.key});

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  late Future<List<CandidateProfile>> _candidatesFuture;
  late Future<({int activePostings, int totalApplications})> _statsFuture;
  late Future<AppUser> _userFuture;

  @override
  void initState() {
    super.initState();
    _candidatesFuture = BackendRepository.instance.getCandidates();
    _statsFuture = BackendRepository.instance.getMyPostingStats();
    _userFuture = BackendRepository.instance.getMyAppUser();
  }

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
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(gradient: AppColors.roleGradient('company'), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.apartment_rounded, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<AppUser>(
                    future: _userFuture,
                    builder: (context, snapshot) {
                      final name = snapshot.data?.name ?? 'Company';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Welcome back 👋', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ],
                      );
                    },
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
            FutureBuilder<({int activePostings, int totalApplications})>(
              future: _statsFuture,
              builder: (context, snapshot) {
                final stats = snapshot.data;
                return Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        value: stats != null ? '${stats.activePostings}' : '—',
                        label: 'Active Postings',
                        icon: Icons.work_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Metric(
                        value: stats != null ? '${stats.totalApplications}' : '—',
                        label: 'Applications',
                        icon: Icons.description_rounded,
                        color: AppColors.accentIndigo,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: _Metric(value: '—', label: 'Match Quality', icon: Icons.verified_rounded, color: AppColors.success),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.person_search_rounded,
                    title: 'Find Candidates',
                    color: AppColors.primary,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CompanyPortalScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.post_add_rounded,
                    title: 'Post a Job',
                    color: AppColors.success,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CompanyPortalScreen(initialTab: 1))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text('Top Matching Candidates', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 14),
            FutureBuilder<List<CandidateProfile>>(
              future: _candidatesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(snapshot.error.toString(), style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                  );
                }
                final candidates = snapshot.data ?? const [];
                if (candidates.isEmpty) {
                  return const Text('No candidates found yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5));
                }
                return Column(
                  children: candidates.take(2).map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CompanyPortalScreen())),
                          child: Row(
                            children: [
                              InitialsAvatar(initials: c.initials, size: 46),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                                    Text('${c.course} · ${c.college}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                  ],
                                ),
                              ),
                              AppTag(label: '${c.matchPercent}%', bg: AppColors.successSoft, fg: AppColors.success),
                            ],
                          ),
                        ),
                      )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _Metric({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.title, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }
}
