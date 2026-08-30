import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/listing_cards.dart';
import 'my_applications_screen.dart';

class JobPortalScreen extends StatefulWidget {
  final int initialTab;
  const JobPortalScreen({super.key, this.initialTab = 0});

  @override
  State<JobPortalScreen> createState() => _JobPortalScreenState();
}

class _JobPortalScreenState extends State<JobPortalScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  late Future<List<JobListing>> _jobsFuture;
  late Future<List<JobListing>> _internshipsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _jobsFuture = BackendRepository.instance.getJobs();
    _internshipsFuture = BackendRepository.instance.getInternships();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<JobListing> _filter(List<JobListing> jobs) {
    if (_query.trim().isEmpty) return jobs;
    final q = _query.toLowerCase();
    return jobs
        .where((j) =>
            j.title.toLowerCase().contains(q) ||
            j.company.toLowerCase().contains(q) ||
            j.tags.any((t) => t.toLowerCase().contains(q)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Opportunity Center',
      actions: [
        IconButton(
          icon: const Icon(Icons.history_rounded),
          tooltip: 'My Applications',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyApplicationsScreen())),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: AppSearchField(
              hint: 'Search jobs, companies, skills...',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 14),
          TabBar(
            controller: _tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            tabs: const [Tab(text: 'Full-time Jobs'), Tab(text: 'Internships')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _JobListFuture(
                  future: _jobsFuture,
                  filter: _filter,
                  onApply: (job) => BackendRepository.instance.applyForJob(job.id!),
                  onRetry: () => setState(() => _jobsFuture = BackendRepository.instance.getJobs()),
                ),
                _JobListFuture(
                  future: _internshipsFuture,
                  filter: _filter,
                  onApply: (job) => BackendRepository.instance.applyForInternship(job.id!),
                  onRetry: () => setState(() => _internshipsFuture = BackendRepository.instance.getInternships()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobListFuture extends StatelessWidget {
  final Future<List<JobListing>> future;
  final List<JobListing> Function(List<JobListing>) filter;
  final Future<void> Function(JobListing) onApply;
  final VoidCallback onRetry;

  const _JobListFuture({
    required this.future,
    required this.filter,
    required this.onApply,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<JobListing>>(
      future: future,
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
                  ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ),
          );
        }
        final jobs = filter(snapshot.data ?? const []);
        if (jobs.isEmpty) {
          return const Center(
            child: Text('No listings found.', style: TextStyle(color: AppColors.textMuted)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          itemCount: jobs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final job = jobs[i];
            return JobCard(
              job: job,
              onTap: () => _showJobDetail(context, job),
            );
          },
        );
      },
    );
  }

  void _showJobDetail(BuildContext context, JobListing job) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _JobDetailSheet(job: job, onApply: onApply),
    );
  }
}

class _JobDetailSheet extends StatefulWidget {
  final JobListing job;
  final Future<void> Function(JobListing) onApply;
  const _JobDetailSheet({required this.job, required this.onApply});

  @override
  State<_JobDetailSheet> createState() => _JobDetailSheetState();
}

class _JobDetailSheetState extends State<_JobDetailSheet> {
  bool _applying = false;

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      await widget.onApply(widget.job);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Applied to ${widget.job.title} at ${widget.job.company}!'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _applying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
            children: [
              Center(
                child: Container(width: 40, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.business_center_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        Text('${job.company} · ${job.location}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _InfoChip(icon: Icons.payments_outlined, label: job.salary)),
                  const SizedBox(width: 10),
                  Expanded(child: _InfoChip(icon: Icons.work_outline_rounded, label: job.type)),
                  const SizedBox(width: 10),
                  Expanded(child: _InfoChip(icon: Icons.bolt_rounded, label: '${job.matchPercent}% match')),
                ],
              ),
              const SizedBox(height: 22),
              const Text('About the Role', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 8),
              Text(
                'We are looking for a driven ${job.title} to join our team at ${job.company}. '
                'You will collaborate with cross-functional teams to deliver impactful, data-driven outcomes '
                'while growing your career in a fast-paced environment.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.55),
              ),
              const SizedBox(height: 18),
              const Text('Required Skills', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: job.tags.map((t) => AppTag(label: t)).toList(),
              ),
              const SizedBox(height: 26),
              ElevatedButton(
                onPressed: (_applying || job.id == null) ? null : _apply,
                child: _applying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('Apply Now'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
