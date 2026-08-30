import 'package:flutter/material.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

class AdminOpportunitiesScreen extends StatefulWidget {
  const AdminOpportunitiesScreen({super.key});

  @override
  State<AdminOpportunitiesScreen> createState() => _AdminOpportunitiesScreenState();
}

class _AdminOpportunitiesScreenState extends State<AdminOpportunitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _internships = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  String? _statusFilter; // null = All

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
        BackendRepository.instance.getAllJobsAdmin(),
        BackendRepository.instance.getAllInternshipsAdmin(),
      ]);
      if (!mounted) return;
      setState(() {
        _jobs = results[0];
        _internships = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> items) {
    return items.where((item) {
      final q = _query.toLowerCase();
      final title = (item['title'] ?? '').toString().toLowerCase();
      final company = (item['company'] ?? '').toString().toLowerCase();
      final matchesQ = q.isEmpty || title.contains(q) || company.contains(q);
      final matchesStatus = _statusFilter == null || item['status'] == _statusFilter;
      return matchesQ && matchesStatus;
    }).toList();
  }

  Future<void> _toggleStatus(Map<String, dynamic> item, bool isJob) async {
    final currentStatus = item['status'] ?? 'Open';
    final newStatus = currentStatus == 'Open' ? 'Closed' : 'Open';
    final id = item['_id'] as String;
    try {
      if (isJob) {
        await BackendRepository.instance.updateJobAdmin(id, {'status': newStatus});
      } else {
        await BackendRepository.instance.updateInternshipAdmin(id, {'status': newStatus});
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status changed to $newStatus'), backgroundColor: AppColors.success),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _delete(Map<String, dynamic> item, bool isJob) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Posting?'),
        content: Text('Are you sure you want to permanently delete "${item['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final id = item['_id'] as String;
      if (isJob) {
        await BackendRepository.instance.deleteJob(id);
      } else {
        await BackendRepository.instance.deleteInternship(id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Posting deleted'), backgroundColor: AppColors.success),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    }
  }

  void _showEditDialog(Map<String, dynamic> item, bool isJob) {
    final titleCtrl = TextEditingController(text: item['title']?.toString() ?? '');
    final locationCtrl = TextEditingController(text: item['location']?.toString() ?? '');
    final descCtrl = TextEditingController(text: item['description']?.toString() ?? '');
    String status = item['status']?.toString() ?? 'Open';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit ${isJob ? 'Job' : 'Internship'}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ['Open', 'Closed']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setS(() => status = v ?? status),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final id = item['_id'] as String;
                final fields = {
                  'title': titleCtrl.text.trim(),
                  'location': locationCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'status': status,
                };
                try {
                  if (isJob) {
                    await BackendRepository.instance.updateJobAdmin(id, fields);
                  } else {
                    await BackendRepository.instance.updateInternshipAdmin(id, fields);
                  }
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Updated successfully'), backgroundColor: AppColors.success),
                  );
                  _load();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Jobs & Internships',
      actions: [
        IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load, tooltip: 'Refresh'),
      ],
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by title or company…',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: ['All', 'Open', 'Closed'].map((s) {
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
              Tab(text: 'Jobs (${_filter(_jobs).length})'),
              Tab(text: 'Internships (${_filter(_internships).length})'),
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
                          _OpportunityList(
                            items: _filter(_jobs),
                            isJob: true,
                            onToggleStatus: (item) => _toggleStatus(item, true),
                            onDelete: (item) => _delete(item, true),
                            onEdit: (item) => _showEditDialog(item, true),
                          ),
                          _OpportunityList(
                            items: _filter(_internships),
                            isJob: false,
                            onToggleStatus: (item) => _toggleStatus(item, false),
                            onDelete: (item) => _delete(item, false),
                            onEdit: (item) => _showEditDialog(item, false),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _OpportunityList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool isJob;
  final void Function(Map<String, dynamic>) onToggleStatus;
  final void Function(Map<String, dynamic>) onDelete;
  final void Function(Map<String, dynamic>) onEdit;

  const _OpportunityList({
    required this.items,
    required this.isJob,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_off_outlined, size: 56, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('No postings found', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final item = items[i];
          final status = item['status']?.toString() ?? 'Open';
          final isOpen = status == 'Open';
          final postedBy = item['postedBy'];
          String postedByName = 'Unknown';
          if (postedBy is Map) postedByName = postedBy['name']?.toString() ?? 'Unknown';

          return AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['title']?.toString() ?? 'Untitled',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? AppColors.success.withOpacity(0.15)
                            : AppColors.danger.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isOpen ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['company'] ?? 'N/A'} • ${item['location'] ?? 'Remote'}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                Text(
                  'Posted by: $postedByName',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: Icon(isOpen ? Icons.lock_outline : Icons.lock_open_outlined, size: 16),
                      label: Text(isOpen ? 'Close' : 'Reopen'),
                      onPressed: () => onToggleStatus(item),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      onPressed: () => onEdit(item),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                      label: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                      onPressed: () => onDelete(item),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
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
