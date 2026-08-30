import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

class MentorshipRequestsScreen extends StatefulWidget {
  const MentorshipRequestsScreen({super.key});

  @override
  State<MentorshipRequestsScreen> createState() => _MentorshipRequestsScreenState();
}

class _MentorshipRequestsScreenState extends State<MentorshipRequestsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  late Future<List<MentorshipRequestItem>> _received;
  late Future<List<MentorshipRequestItem>> _sent;

  @override
  void initState() {
    super.initState();
    _received = BackendRepository.instance.getReceivedMentorshipRequests();
    _sent = BackendRepository.instance.getSentMentorshipRequests();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _received = BackendRepository.instance.getReceivedMentorshipRequests();
      _sent = BackendRepository.instance.getSentMentorshipRequests();
    });
  }

  Future<void> _respond(String id, bool accept) async {
    try {
      if (accept) {
        await BackendRepository.instance.acceptMentorshipRequest(id);
      } else {
        await BackendRepository.instance.rejectMentorshipRequest(id);
      }
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _cancel(String id) async {
    try {
      await BackendRepository.instance.cancelMentorshipRequest(id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Accepted':
        return AppColors.success;
      case 'Rejected':
      case 'Cancelled':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Mentorship Requests',
      body: Column(
        children: [
          TabBar(
            controller: _tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            tabs: const [Tab(text: 'Received'), Tab(text: 'Sent')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _RequestList(
                  future: _received,
                  emptyText: 'No mentorship requests received yet.',
                  builder: (r) => _RequestCard(
                    title: r.menteeName,
                    subtitle: r.message ?? 'Requested mentorship',
                    status: r.status,
                    statusColor: _statusColor(r.status),
                    timeAgo: r.timeAgo,
                    actions: r.status == 'Pending' && r.id != null
                        ? [
                            TextButton(onPressed: () => _respond(r.id!, false), child: const Text('Reject')),
                            ElevatedButton(onPressed: () => _respond(r.id!, true), child: const Text('Accept')),
                          ]
                        : null,
                  ),
                  onRetry: _reload,
                ),
                _RequestList(
                  future: _sent,
                  emptyText: 'You haven\'t sent any mentorship requests yet.',
                  builder: (r) => _RequestCard(
                    title: r.mentorName,
                    subtitle: r.message ?? 'Mentorship request',
                    status: r.status,
                    statusColor: _statusColor(r.status),
                    timeAgo: r.timeAgo,
                    actions: r.status == 'Pending' && r.id != null
                        ? [TextButton(onPressed: () => _cancel(r.id!), child: const Text('Cancel'))]
                        : null,
                  ),
                  onRetry: _reload,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  final Future<List<MentorshipRequestItem>> future;
  final String emptyText;
  final Widget Function(MentorshipRequestItem) builder;
  final VoidCallback onRetry;

  const _RequestList({required this.future, required this.emptyText, required this.builder, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MentorshipRequestItem>>(
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
        final requests = snapshot.data ?? const [];
        if (requests.isEmpty) {
          return Center(child: Text(emptyText, style: const TextStyle(color: AppColors.textMuted)));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => builder(requests[i]),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final String timeAgo;
  final List<Widget>? actions;

  const _RequestCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.timeAgo,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
              AppTag(label: status, bg: statusColor.withOpacity(0.12), fg: statusColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          const SizedBox(height: 4),
          Text(timeAgo, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          if (actions != null) ...[
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!),
          ],
        ],
      ),
    );
  }
}
