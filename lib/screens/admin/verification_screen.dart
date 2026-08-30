// lib/screens/admin/verification_screen.dart
//
// Dedicated page for verifying Alumni & Mentor accounts.
// Uses BackendRepository.getAllUsersAdmin() filtered by role, then
// calls updateUserAdmin() to approve or reject each account.
// All state is managed locally so the UI updates immediately.

import 'package:flutter/material.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  List<Map<String, dynamic>> _alumni = [];
  List<Map<String, dynamic>> _mentors = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  // Local status overrides so UI updates instantly without a full reload
  final Map<String, String> _statusOverrides = {}; // userId → 'verified'|'rejected'

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        BackendRepository.instance.getAllUsersAdmin(role: 'alumni'),
        BackendRepository.instance.getAllUsersAdmin(role: 'mentor'),
      ]);
      if (!mounted) return;
      setState(() {
        _alumni = results[0];
        _mentors = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _approve(Map<String, dynamic> user) async {
    final id = user['_id'].toString();
    // Optimistic UI
    setState(() => _statusOverrides[id] = 'verified');
    try {
      await BackendRepository.instance.updateUserAdmin(id, isApproved: true, isActive: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user['name']} approved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // Rollback
      if (mounted) {
        setState(() => _statusOverrides.remove(id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _reject(Map<String, dynamic> user) async {
    final id = user['_id'].toString();
    setState(() => _statusOverrides[id] = 'rejected');
    try {
      await BackendRepository.instance.updateUserAdmin(id, isApproved: false, isActive: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user['name']} rejected.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusOverrides.remove(id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> list, {bool pendingOnly = false}) {
    var result = list.where((u) {
      final q = _query.toLowerCase();
      if (q.isEmpty) return true;
      return (u['name']?.toString().toLowerCase().contains(q) ?? false) ||
          (u['email']?.toString().toLowerCase().contains(q) ?? false);
    }).toList();
    if (pendingOnly) {
      result = result.where((u) {
        final id = u['_id'].toString();
        final override = _statusOverrides[id];
        if (override != null) return false; // already actioned
        return u['isApproved'] == false || u['isApproved'] == null;
      }).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final allPending = [
      ..._alumni.where((u) {
        final id = u['_id'].toString();
        return _statusOverrides[id] == null &&
            (u['isApproved'] == false || u['isApproved'] == null);
      }),
      ..._mentors.where((u) {
        final id = u['_id'].toString();
        return _statusOverrides[id] == null &&
            (u['isApproved'] == false || u['isApproved'] == null);
      }),
    ];

    return SimpleScreenScaffold(
      title: 'Verify Alumni & Mentors',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
          onPressed: _load,
        ),
      ],
      body: Column(
        children: [
          // Summary banner
          if (!_loading && _error == null)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: allPending.isNotEmpty ? AppColors.warningSoft : AppColors.successSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: allPending.isNotEmpty
                      ? AppColors.warning.withOpacity(0.3)
                      : AppColors.success.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    allPending.isNotEmpty
                        ? Icons.pending_actions_rounded
                        : Icons.check_circle_rounded,
                    color: allPending.isNotEmpty ? AppColors.warning : AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    allPending.isNotEmpty
                        ? '${allPending.length} pending verification request${allPending.length == 1 ? '' : 's'}'
                        : 'All requests have been reviewed',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color:
                          allPending.isNotEmpty ? AppColors.warning : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          // Tabs
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Pending (${allPending.length})'),
              Tab(text: 'Alumni (${_alumni.length})'),
              Tab(text: 'Mentors (${_mentors.length})'),
            ],
          ),
          const SizedBox(height: 12),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppSearchField(
              hint: 'Search by name or email...',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 14),
          // Body
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(error: _error!, onRetry: _load)
                    : TabBarView(
                        controller: _tabs,
                        children: [
                          _UserList(
                            users: _filtered(allPending),
                            statusOverrides: _statusOverrides,
                            onApprove: _approve,
                            onReject: _reject,
                            emptyTitle: 'No Pending Requests',
                            emptySubtitle:
                                'All alumni and mentor accounts have been reviewed.',
                          ),
                          _UserList(
                            users: _filtered(_alumni),
                            statusOverrides: _statusOverrides,
                            onApprove: _approve,
                            onReject: _reject,
                            emptyTitle: 'No Alumni Found',
                            emptySubtitle:
                                'No alumni accounts are registered yet.',
                          ),
                          _UserList(
                            users: _filtered(_mentors),
                            statusOverrides: _statusOverrides,
                            onApprove: _approve,
                            onReject: _reject,
                            emptyTitle: 'No Mentors Found',
                            emptySubtitle:
                                'No mentor accounts are registered yet.',
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _UserList extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final Map<String, String> statusOverrides;
  final Future<void> Function(Map<String, dynamic>) onApprove;
  final Future<void> Function(Map<String, dynamic>) onReject;
  final String emptyTitle;
  final String emptySubtitle;

  const _UserList({
    required this.users,
    required this.statusOverrides,
    required this.onApprove,
    required this.onReject,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.verified_user_rounded,
          title: emptyTitle,
          subtitle: emptySubtitle,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final u = users[i];
        final id = u['_id'].toString();
        final override = statusOverrides[id];
        final isApproved = override == 'verified' ||
            (override == null && u['isApproved'] == true);
        final isRejected = override == 'rejected';
        final isPending = !isApproved && !isRejected;

        return _VerificationCard(
          user: u,
          isApproved: isApproved,
          isRejected: isRejected,
          isPending: isPending,
          onApprove: () => onApprove(u),
          onReject: () => onReject(u),
        );
      },
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isApproved;
  final bool isRejected;
  final bool isPending;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _VerificationCard({
    required this.user,
    required this.isApproved,
    required this.isRejected,
    required this.isPending,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final role = user['role']?.toString() ?? 'alumni';
    final name = user['name']?.toString() ?? '—';
    final email = user['email']?.toString() ?? '';
    final createdAt = user['createdAt']?.toString();

    String? dateStr;
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt);
        dateStr =
            '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return AppCard(
      color: isRejected
          ? AppColors.dangerSoft
          : isApproved
              ? AppColors.successSoft
              : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.roleGradient(role),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    Text(
                      email,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                    if (dateStr != null)
                      Text(
                        'Joined $dateStr',
                        style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
              // Status badge
              if (isApproved)
                _StatusBadge(
                    label: 'Verified',
                    color: AppColors.success,
                    icon: Icons.verified_rounded)
              else if (isRejected)
                _StatusBadge(
                    label: 'Rejected',
                    color: AppColors.danger,
                    icon: Icons.cancel_rounded)
              else
                _StatusBadge(
                    label: 'Pending',
                    color: AppColors.warning,
                    icon: Icons.pending_rounded),
            ],
          ),
          if (isPending) ...[
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusBadge(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
