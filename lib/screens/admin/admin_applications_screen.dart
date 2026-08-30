import 'package:flutter/material.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  State<AdminApplicationsScreen> createState() => _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _jobApps = [];
  List<Map<String, dynamic>> _internApps = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  String? _statusFilter;

  static const _statuses = ['Applied', 'Shortlisted', 'Rejected', 'Selected'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        BackendRepository.instance.getAllJobApplicationsAdmin(),
        BackendRepository.instance.getAllInternshipApplicationsAdmin(),
      ]);
      if (!mounted) return;
      setState(() {
        _jobApps = results[0];
        _internApps = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> items) {
    return items.where((app) {
      final q = _query.toLowerCase();
      final applicant = app['applicant'];
      final position = app['job'] ?? app['internship'];
      final name = (applicant is Map ? applicant['name'] ?? '' : '').toString().toLowerCase();
      final title = (position is Map ? position['title'] ?? '' : '').toString().toLowerCase();
      final matchesQ = q.isEmpty || name.contains(q) || title.contains(q);
      final matchesStatus = _statusFilter == null || app['status'] == _statusFilter;
      return matchesQ && matchesStatus;
    }).toList();
  }

  Future<void> _updateStatus(Map<String, dynamic> app, String newStatus, bool isJob) async {
    final id = app['_id'] as String;
    try {
      if (isJob) {
        await BackendRepository.instance.updateJobApplicationStatus(id, newStatus);
      } else {
        await BackendRepository.instance.updateInternshipApplicationStatus(id, newStatus);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to $newStatus'),
          backgroundColor: AppColors.success,
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'Selected': return AppColors.success;
      case 'Shortlisted': return AppColors.primary;
      case 'Rejected': return AppColors.danger;
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Applications',
      actions: [
        IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load, tooltip: 'Refresh'),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by applicant or position…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _query = ''))
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: ['All', ..._statuses].map((s) {
                final selected = (s == 'All' && _statusFilter == null) || _statusFilter == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s),
                    selected: selected,
                    onSelected: (_) => setState(() => _statusFilter = s == 'All' ? null : s),
                    selectedColor: AppColors.primary.withOpacity(0.2),
                  ),
                );
              }).toList(),
            ),
          ),
          TabBar(
            controller: _tabs,
            tabs: [
              Tab(text: 'Job Apps (${_filter(_jobApps).length})'),
              Tab(text: 'Intern Apps (${_filter(_internApps).length})'),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: _ErrorRetry(error: _error!, onRetry: _load))
                    : TabBarView(
                        controller: _tabs,
                        children: [
                          _ApplicationList(
                            items: _filter(_jobApps),
                            isJob: true,
                            statuses: _statuses,
                            statusColor: _statusColor,
                            onUpdateStatus: (app, s) => _updateStatus(app, s, true),
                          ),
                          _ApplicationList(
                            items: _filter(_internApps),
                            isJob: false,
                            statuses: _statuses,
                            statusColor: _statusColor,
                            onUpdateStatus: (app, s) => _updateStatus(app, s, false),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool isJob;
  final List<String> statuses;
  final Color Function(String?) statusColor;
  final void Function(Map<String, dynamic>, String) onUpdateStatus;

  const _ApplicationList({
    required this.items,
    required this.isJob,
    required this.statuses,
    required this.statusColor,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('No applications found', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final app = items[i];
        final applicant = app['applicant'];
        final position = isJob ? app['job'] : app['internship'];
        final name = applicant is Map ? applicant['name'] ?? 'Unknown' : 'Unknown';
        final email = applicant is Map ? applicant['email'] ?? '' : '';
        final title = position is Map ? position['title'] ?? 'Unknown' : 'Unknown';
        final company = position is Map ? position['company'] ?? '' : '';
        final currentStatus = app['status']?.toString() ?? 'Applied';
        final appliedAt = app['createdAt']?.toString().split('T').first ?? '';

        return AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor(currentStatus).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      currentStatus,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor(currentStatus),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(email, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.work_outline, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '$title${company.isNotEmpty ? ' • $company' : ''}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
              if (appliedAt.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Applied: $appliedAt',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
              const SizedBox(height: 8),
              // Status dropdown row
              Row(
                children: [
                  const Text(
                    'Update Status:',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: statuses.contains(currentStatus) ? currentStatus : statuses.first,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: statuses
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s, style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (newStatus) {
                        if (newStatus != null && newStatus != currentStatus) {
                          onUpdateStatus(app, newStatus);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 56, color: AppColors.danger),
        const SizedBox(height: 12),
        Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}
