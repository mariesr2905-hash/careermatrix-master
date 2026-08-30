import 'package:flutter/material.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import 'admin_user_detail_screen.dart';
import 'approval_requests_screen.dart';
import 'import_excel_modal.dart';

class UserManagementScreen extends StatefulWidget {
  final int initialTab;
  const UserManagementScreen({super.key, this.initialTab = 0});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _future;
  String _query = '';
  String? _selectedStatus;
  String _departmentQuery = '';
  Map<String, dynamic>? _stats;

  // Bulk Actions State
  final Set<String> _selectedUserIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 4),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedUserIds.clear();
          _isSelectionMode = false;
        });
        _reload();
      }
    });
    _reload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? get _currentRoleFilter {
    switch (_tabController.index) {
      case 1:
        return 'student';
      case 2:
        return 'alumni';
      case 3:
        return 'mentor';
      case 4:
        return 'company';
      default:
        return null;
    }
  }

  void _reload() {
    setState(() {
      _future = BackendRepository.instance.getAllUsersAdmin(
        search: _query,
        role: _currentRoleFilter,
        status: _selectedStatus,
        department: _departmentQuery.isNotEmpty ? _departmentQuery : null,
      );
    });
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await BackendRepository.instance.getAdminDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    } catch (_) {}
  }

  Future<void> _changeRole(Map<String, dynamic> user) async {
    const roles = ['student', 'alumni', 'mentor', 'company', 'admin'];
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Change role for ${user['name']}'),
        children: roles
            .map((r) => SimpleDialogOption(onPressed: () => Navigator.pop(ctx, r), child: Text(r.toUpperCase())))
            .toList(),
      ),
    );
    if (selected == null) return;
    try {
      await BackendRepository.instance.updateUserAdmin(user['_id'].toString(), role: selected);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    final currentlyActive = user['isActive'] != false;
    final status = currentlyActive ? 'DEACTIVATED' : 'ACTIVE';
    try {
      await BackendRepository.instance.updateUserAdmin(user['_id'].toString(), isActive: !currentlyActive, status: status);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _approveUserSingle(Map<String, dynamic> user) async {
    try {
      await BackendRepository.instance.updateUserAdmin(user['_id'].toString(), status: 'APPROVED');
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${user['name']} approved successfully.'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _rejectUserSingle(Map<String, dynamic> user) async {
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject ${user['name']}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Provide rejection reason:'),
              const SizedBox(height: 8),
              TextFormField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Reason'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Reason required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _createAccount() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String role = _currentRoleFilter ?? 'student';
    const roles = ['student', 'alumni', 'mentor', 'company', 'admin'];
    bool approveImmediately = false;
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Create User Account'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name / Company Name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email Address'),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Temporary Password'),
                    validator: (v) => (v == null || v.length < 8) ? 'Min 8 characters' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                    onChanged: (v) => setDialogState(() => role = v ?? 'student'),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Approve immediately', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Bypass pending approval queue', style: TextStyle(fontSize: 11)),
                    value: approveImmediately,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setDialogState(() => approveImmediately = v ?? false),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                try {
                  await BackendRepository.instance.createUserAdmin(
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    password: passwordCtrl.text,
                    role: role,
                    status: approveImmediately ? 'APPROVED' : 'PENDING',
                    approveImmediately: approveImmediately,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                    );
                  }
                }
              },
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );

    if (created == true) {
      _reload();
    }
  }

  Future<void> _delete(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete ${user['name']}?'),
        content: const Text('This will permanently delete the user account and profiles from the system.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await BackendRepository.instance.deleteUserAdmin(user['_id'].toString());
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  // Bulk actions triggers
  Future<void> _performBulkAction(String action) async {
    if (_selectedUserIds.isEmpty) return;

    String? rejectionReason;
    if (action == 'reject') {
      final reasonCtrl = TextEditingController();
      final formKey = GlobalKey<FormState>();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Bulk Reject Accounts'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Provide a rejection reason:'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Reason required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Confirm Reject'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      rejectionReason = reasonCtrl.text.trim();
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('${action[0].toUpperCase()}${action.substring(1)} Selected Accounts?'),
          content: Text('Are you sure you want to $action ${_selectedUserIds.length} accounts?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: action == 'delete' ? AppColors.danger : AppColors.primary,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action.toUpperCase()),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isSelectionMode = false);

    try {
      await BackendRepository.instance.bulkUpdateStatus(
        userIds: _selectedUserIds.toList(),
        action: action,
        rejectionReason: rejectionReason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk $action completed successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _selectedUserIds.clear();
        });
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

  void _openExcelImportWizard() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ImportExcelModal(),
    ).then((completed) {
      if (completed == true) {
        _reload();
      }
    });
  }

  Future<void> _downloadExcelTemplateSelected() async {
    try {
      await BackendRepository.instance.downloadExcelTemplate(_currentRoleFilter?.toUpperCase() ?? 'STUDENT');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel template for ${_currentRoleFilter?.toUpperCase() ?? 'STUDENT'} downloaded.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Widget _buildStatBlock({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine counts from stats
    final totalUsersVal = _stats != null 
        ? ((_stats!['students'] ?? 0) + (_stats!['alumni'] ?? 0) + (_stats!['mentors'] ?? 0) + (_stats!['companies'] ?? 0)).toString() 
        : '...';
    final studentsVal = _stats != null ? _stats!['students']?.toString() ?? '0' : '0';
    final alumniVal = _stats != null ? _stats!['alumni']?.toString() ?? '0' : '0';
    final mentorsVal = _stats != null ? _stats!['mentors']?.toString() ?? '0' : '0';
    final companiesVal = _stats != null ? _stats!['companies']?.toString() ?? '0' : '0';
    final pendingVal = _stats != null ? _stats!['pendingApprovals']?.toString() ?? '0' : '0';

    return SimpleScreenScaffold(
      title: 'User Management',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAccount,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Account'),
      ),
      body: Column(
        children: [
          // Statistics Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 120,
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                childAspectRatio: 2.2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  _buildStatBlock(value: totalUsersVal, label: 'Total Users', icon: Icons.people_alt_rounded, color: AppColors.primary),
                  _buildStatBlock(value: studentsVal, label: 'Students', icon: Icons.school_rounded, color: AppColors.accentIndigo),
                  _buildStatBlock(value: alumniVal, label: 'Alumni', icon: Icons.workspace_premium_rounded, color: AppColors.accentCyan),
                  _buildStatBlock(value: mentorsVal, label: 'Mentors', icon: Icons.diversity_3_rounded, color: AppColors.accentIndigo),
                  _buildStatBlock(value: companiesVal, label: 'Companies', icon: Icons.apartment_rounded, color: AppColors.success),
                  _buildStatBlock(
                    value: pendingVal,
                    label: 'Pending Approvals',
                    icon: Icons.pending_actions_rounded,
                    color: AppColors.warning,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ApprovalRequestsScreen()),
                      ).then((_) => _reload());
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'All Users'),
              Tab(text: 'Students'),
              Tab(text: 'Alumni'),
              Tab(text: 'Mentors'),
              Tab(text: 'Companies'),
            ],
          ),
          const SizedBox(height: 10),

          // Filters and Search Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: AppSearchField(
                    hint: 'Search by name or email...',
                    onChanged: (v) {
                      _query = v;
                      _reload();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                
                // Status Filter
                DropdownButton<String?>(
                  value: _selectedStatus,
                  hint: const Text('Status'),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Statuses')),
                    DropdownMenuItem(value: 'PENDING', child: Text('PENDING')),
                    DropdownMenuItem(value: 'APPROVED', child: Text('APPROVED')),
                    DropdownMenuItem(value: 'REJECTED', child: Text('REJECTED')),
                    DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                    DropdownMenuItem(value: 'DEACTIVATED', child: Text('DEACTIVATED')),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedStatus = val);
                    _reload();
                  },
                ),
                const SizedBox(width: 8),

                // Department filter (Student / Alumni only)
                if (_tabController.index == 1 || _tabController.index == 2) ...[
                  SizedBox(
                    width: 140,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Dept...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onChanged: (v) {
                        _departmentQuery = v;
                        _reload();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Action Buttons
                IconButton(
                  tooltip: 'Import Excel',
                  icon: const Icon(Icons.file_upload_rounded, color: AppColors.primary),
                  onPressed: _openExcelImportWizard,
                ),
                IconButton(
                  tooltip: 'Download Template',
                  icon: const Icon(Icons.download_for_offline_rounded, color: AppColors.textMuted),
                  onPressed: _downloadExcelTemplateSelected,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Selection control helper
          if (_isSelectionMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_selectedUserIds.length} users selected', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedUserIds.clear();
                        _isSelectionMode = false;
                      });
                    },
                    child: const Text('Clear Selection'),
                  ),
                ],
              ),
            ),

          // Main User List
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

                var users = snapshot.data ?? const [];

                if (users.isEmpty) {
                  return const Center(
                    child: Text('No accounts found.', style: TextStyle(color: AppColors.textMuted)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final u = users[i];
                    final uId = u['_id'].toString();
                    final active = u['isActive'] != false;
                    final status = (u['status'] ?? 'APPROVED').toString().toUpperCase();
                    final isChecked = _selectedUserIds.contains(uId);

                    return InkWell(
                      onLongPress: () {
                        setState(() {
                          _isSelectionMode = true;
                          _selectedUserIds.add(uId);
                        });
                      },
                      onTap: () {
                        if (_isSelectionMode) {
                          setState(() {
                            if (isChecked) {
                              _selectedUserIds.remove(uId);
                              if (_selectedUserIds.isEmpty) _isSelectionMode = false;
                            } else {
                              _selectedUserIds.add(uId);
                            }
                          });
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AdminUserDetailScreen(
                                userId: uId,
                                userName: u['name']?.toString() ?? 'User',
                              ),
                            ),
                          ).then((_) => _reload());
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AppCard(
                        child: Row(
                          children: [
                            if (_isSelectionMode) ...[
                              Checkbox(
                                value: isChecked,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selectedUserIds.add(uId);
                                    } else {
                                      _selectedUserIds.remove(uId);
                                      if (_selectedUserIds.isEmpty) _isSelectionMode = false;
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: AppColors.roleGradient(u['role']?.toString() ?? 'student'),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              u['name']?.toString() ?? '—',
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                            ),
                                            Text(
                                              u['email']?.toString() ?? '',
                                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AppTag(label: u['role']?.toString() ?? 'student'),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      if (status == 'PENDING')
                                        const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Chip(
                                            visualDensity: VisualDensity.compact,
                                            backgroundColor: AppColors.warningSoft,
                                            label: Text('PENDING APPROVAL', style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      if (status == 'REJECTED')
                                        const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Chip(
                                            visualDensity: VisualDensity.compact,
                                            backgroundColor: AppColors.dangerSoft,
                                            label: Text('REJECTED', style: TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      if (status == 'DEACTIVATED' || !active)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Chip(
                                            visualDensity: VisualDensity.compact,
                                            backgroundColor: AppColors.surfaceMuted,
                                            label: Text('DEACTIVATED', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                          ),
                                        ),
                                      if (status == 'APPROVED' || status == 'ACTIVE')
                                        const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Chip(
                                            visualDensity: VisualDensity.compact,
                                            backgroundColor: AppColors.successSoft,
                                            label: Text('ACTIVE', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (!_isSelectionMode) ...[
                                    const Divider(height: 18),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          TextButton.icon(
                                            onPressed: () => _changeRole(u),
                                            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                                            label: const Text('Change Role'),
                                          ),
                                          TextButton.icon(
                                            onPressed: () => _toggleActive(u),
                                            icon: Icon(active ? Icons.block_rounded : Icons.check_circle_outline_rounded, size: 16),
                                            label: Text(active ? 'Deactivate' : 'Activate'),
                                          ),
                                          if (status == 'PENDING') ...[
                                            TextButton.icon(
                                              onPressed: () => _approveUserSingle(u),
                                              icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 16),
                                              label: const Text('Approve', style: TextStyle(color: Colors.green)),
                                            ),
                                            TextButton.icon(
                                              onPressed: () => _rejectUserSingle(u),
                                              icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 16),
                                              label: const Text('Reject', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                          IconButton(
                                            onPressed: () => _delete(u),
                                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                            tooltip: 'Delete User',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomSheet: _isSelectionMode
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Approve'),
                    onPressed: () => _performBulkAction('approve'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                    icon: const Icon(Icons.cancel_rounded),
                    label: const Text('Reject'),
                    onPressed: () => _performBulkAction('reject'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.textMuted),
                    icon: const Icon(Icons.lock_rounded),
                    label: const Text('Deactivate'),
                    onPressed: () => _performBulkAction('deactivate'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    icon: const Icon(Icons.lock_open_rounded),
                    label: const Text('Activate'),
                    onPressed: () => _performBulkAction('activate'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete'),
                    onPressed: () => _performBulkAction('delete'),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
