import 'package:flutter/material.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import 'admin_user_detail_screen.dart';

class ApprovalRequestsScreen extends StatefulWidget {
  const ApprovalRequestsScreen({super.key});

  @override
  State<ApprovalRequestsScreen> createState() => _ApprovalRequestsScreenState();
}

class _ApprovalRequestsScreenState extends State<ApprovalRequestsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  String _searchQuery = '';
  String? _selectedRoleFilter;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = BackendRepository.instance.getAllUsersAdmin(
        search: _searchQuery,
        role: _selectedRoleFilter,
        status: 'PENDING',
      );
    });
  }

  Future<void> _approveUser(Map<String, dynamic> user) async {
    final name = user['name']?.toString() ?? 'User';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Approve Account'),
        content: Text('Are you sure you want to approve the account request for $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await BackendRepository.instance.updateUserAdmin(
        user['_id'].toString(),
        status: 'APPROVED',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account for $name approved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        _reload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _rejectUser(Map<String, dynamic> user) async {
    final name = user['name']?.toString() ?? 'User';
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject $name'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please provide a reason for rejecting this registration request:'),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason',
                  hintText: 'e.g. Invalid register number, company website unverified',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Rejection reason is required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await BackendRepository.instance.updateUserAdmin(
        user['_id'].toString(),
        status: 'REJECTED',
        rejectionReason: reasonCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account request for $name rejected.'),
            backgroundColor: AppColors.warning,
          ),
        );
        _reload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  String _getDetailsText(Map<String, dynamic> user) {
    final role = (user['role']?.toString() ?? 'student').toLowerCase();
    final email = user['email']?.toString() ?? '';
    final phone = user['phone']?.toString() ?? 'No phone';

    if (role == 'student' || role == 'alumni') {
      return 'Email: $email\nPhone: $phone';
    } else if (role == 'mentor') {
      return 'Email: $email\nPhone: $phone';
    } else if (role == 'company') {
      return 'Email: $email\nPhone: $phone';
    }
    return 'Email: $email\nPhone: $phone';
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '—';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '—';
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const roles = [
      {'label': 'All Roles', 'value': null},
      {'label': 'Students', 'value': 'student'},
      {'label': 'Alumni', 'value': 'alumni'},
      {'label': 'Mentors', 'value': 'mentor'},
      {'label': 'Companies', 'value': 'company'},
      {'label': 'Admins', 'value': 'admin'},
    ];

    return SimpleScreenScaffold(
      title: 'Approval Requests',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: AppSearchField(
                    hint: 'Search pending requests...',
                    onChanged: (v) {
                      _searchQuery = v;
                      _reload();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String?>(
                  value: _selectedRoleFilter,
                  underline: const SizedBox(),
                  hint: const Text('Filter Role'),
                  items: roles
                      .map((r) => DropdownMenuItem<String?>(
                            value: r['value'] as String?,
                            child: Text(r['label'] as String),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedRoleFilter = val;
                    });
                    _reload();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
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
                          const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.danger),
                          const SizedBox(height: 12),
                          Text(snapshot.error.toString(), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _reload, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  );
                }

                final users = snapshot.data ?? const [];
                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      'No pending approval requests found.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final u = users[i];
                    final regDate = _formatDate(u['createdAt']?.toString());
                    final roleKey = u['role']?.toString() ?? 'student';

                    return AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: AppColors.roleGradient(roleKey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      u['name']?.toString() ?? '—',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      'Requested: $regDate',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              AppTag(label: roleKey),
                            ],
                          ),
                          const Divider(height: 20),
                          Text(
                            _getDetailsText(u),
                            style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminUserDetailScreen(
                                        userId: u['_id'].toString(),
                                        userName: u['name']?.toString() ?? 'User',
                                      ),
                                    ),
                                  ).then((_) => _reload());
                                },
                                child: const Text('View Details'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.danger),
                                  foregroundColor: AppColors.danger,
                                ),
                                onPressed: () => _rejectUser(u),
                                child: const Text('Reject'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _approveUser(u),
                                child: const Text('Approve'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
