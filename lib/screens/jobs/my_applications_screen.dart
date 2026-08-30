import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  late Future<List<ApplicationRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAll();
  }

  Future<List<ApplicationRecord>> _loadAll() async {
    final results = await Future.wait([
      BackendRepository.instance.getMyJobApplications(),
      BackendRepository.instance.getMyInternshipApplications(),
    ]);
    final combined = [...results[0], ...results[1]];
    combined.sort((a, b) {
      if (a.appliedAt == null || b.appliedAt == null) return 0;
      return b.appliedAt!.compareTo(a.appliedAt!);
    });
    return combined;
  }

  void _reload() {
    setState(() {
      _future = _loadAll();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Selected':
        return AppColors.success;
      case 'Shortlisted':
        return AppColors.primary;
      case 'Rejected':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'My Applications',
      body: FutureBuilder<List<ApplicationRecord>>(
        future: _future,
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
                    const Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _reload, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }
          final apps = snapshot.data ?? const [];
          if (apps.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
              children: const [
                Center(
                  child: Text(
                    "You haven't applied to any jobs or internships yet.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ],
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              itemCount: apps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final a = apps[i];
                return AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                        child: Icon(
                          a.type == 'Job' ? Icons.business_center_rounded : Icons.school_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                            const SizedBox(height: 2),
                            Text('${a.company} · ${a.location}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusColor(a.status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          a.status,
                          style: TextStyle(color: _statusColor(a.status), fontWeight: FontWeight.w800, fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
