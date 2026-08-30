import 'package:flutter/material.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

class AdminMentorshipScreen extends StatefulWidget {
  const AdminMentorshipScreen({super.key});

  @override
  State<AdminMentorshipScreen> createState() => _AdminMentorshipScreenState();
}

class _AdminMentorshipScreenState extends State<AdminMentorshipScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  String? _statusFilter;

  static const _requestStatuses = ['Pending', 'Accepted', 'Rejected', 'Cancelled'];

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
        BackendRepository.instance.getAllMentorshipRequestsAdmin(),
        BackendRepository.instance.getAllBookingsAdmin(),
      ]);
      if (!mounted) return;
      setState(() {
        _requests = results[0];
        _bookings = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<Map<String, dynamic>> _filterRequests(List<Map<String, dynamic>> items) {
    return items.where((req) {
      final q = _query.toLowerCase();
      final requester = req['requester'];
      final mentor = req['mentor'];
      final mentorUser = mentor is Map ? mentor['user'] : null;
      final reqName = (requester is Map ? requester['name'] ?? '' : '').toString().toLowerCase();
      final mentorName = (mentorUser is Map ? mentorUser['name'] ?? '' : '').toString().toLowerCase();
      final matchesQ = q.isEmpty || reqName.contains(q) || mentorName.contains(q);
      final matchesStatus = _statusFilter == null || req['status'] == _statusFilter;
      return matchesQ && matchesStatus;
    }).toList();
  }

  List<Map<String, dynamic>> _filterBookings(List<Map<String, dynamic>> items) {
    return items.where((b) {
      final q = _query.toLowerCase();
      final student = b['student'];
      final mentor = b['mentor'];
      final mentorUser = mentor is Map ? mentor['user'] : null;
      final studentName = (student is Map ? student['name'] ?? '' : '').toString().toLowerCase();
      final mentorName = (mentorUser is Map ? mentorUser['name'] ?? '' : '').toString().toLowerCase();
      final matchesQ = q.isEmpty || studentName.contains(q) || mentorName.contains(q);
      return matchesQ;
    }).toList();
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'Accepted': return AppColors.success;
      case 'Pending': return Colors.orange;
      case 'Rejected': return AppColors.danger;
      case 'Cancelled': return AppColors.textMuted;
      default: return AppColors.textMuted;
    }
  }

  void _showRequestDetail(Map<String, dynamic> req) {
    final requester = req['requester'];
    final mentor = req['mentor'];
    final mentorUser = mentor is Map ? mentor['user'] : null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Request Detail'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Requester', value: requester is Map ? requester['name'] ?? 'N/A' : 'N/A'),
            _DetailRow(label: 'Requester Email', value: requester is Map ? requester['email'] ?? 'N/A' : 'N/A'),
            _DetailRow(label: 'Mentor', value: mentorUser is Map ? mentorUser['name'] ?? 'N/A' : 'N/A'),
            _DetailRow(label: 'Mentor Email', value: mentorUser is Map ? mentorUser['email'] ?? 'N/A' : 'N/A'),
            _DetailRow(label: 'Status', value: req['status']?.toString() ?? 'N/A'),
            _DetailRow(label: 'Message', value: req['message']?.toString() ?? 'No message'),
            _DetailRow(label: 'Sent', value: req['createdAt']?.toString().split('T').first ?? ''),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showBookingDetail(Map<String, dynamic> booking) {
    final student = booking['student'];
    final mentor = booking['mentor'];
    final mentorUser = mentor is Map ? mentor['user'] : null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Session Detail'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Student', value: student is Map ? student['name'] ?? 'N/A' : 'N/A'),
            _DetailRow(label: 'Student Email', value: student is Map ? student['email'] ?? 'N/A' : 'N/A'),
            _DetailRow(label: 'Mentor', value: mentorUser is Map ? mentorUser['name'] ?? 'N/A' : 'N/A'),
            _DetailRow(label: 'Mentor Email', value: mentorUser is Map ? mentorUser['email'] ?? 'N/A' : 'N/A'),
            _DetailRow(label: 'Status', value: booking['status']?.toString() ?? 'N/A'),
            _DetailRow(label: 'Slot', value: booking['slot']?.toString() ?? 'N/A'),
            _DetailRow(label: 'Booked On', value: booking['createdAt']?.toString().split('T').first ?? ''),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Mentorship Management',
      actions: [
        IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load, tooltip: 'Refresh'),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by student or mentor name…',
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
          // Status filters (for requests tab)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: ['All', ..._requestStatuses].map((s) {
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
              Tab(text: 'Requests (${_filterRequests(_requests).length})'),
              Tab(text: 'Sessions (${_filterBookings(_bookings).length})'),
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
                          // Mentorship Requests Tab
                          _filterRequests(_requests).isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.people_outline, size: 56, color: AppColors.textMuted),
                                      SizedBox(height: 12),
                                      Text('No mentorship requests found',
                                          style: TextStyle(color: AppColors.textSecondary)),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filterRequests(_requests).length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (_, i) {
                                    final req = _filterRequests(_requests)[i];
                                    final requester = req['requester'];
                                    final mentor = req['mentor'];
                                    final mentorUser = mentor is Map ? mentor['user'] : null;
                                    final status = req['status']?.toString() ?? '';
                                    return AppCard(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      requester is Map ? requester['name'] ?? 'N/A' : 'N/A',
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight.w700, fontSize: 15),
                                                    ),
                                                    Text(
                                                      '→ Mentor: ${mentorUser is Map ? mentorUser['name'] ?? 'N/A' : 'N/A'}',
                                                      style: const TextStyle(
                                                          color: AppColors.textSecondary, fontSize: 13),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 10, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: _statusColor(status).withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  status,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: _statusColor(status),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (req['message'] != null && req['message'].toString().isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                '"${req['message']}"',
                                                style: const TextStyle(
                                                    color: AppColors.textMuted,
                                                    fontSize: 12,
                                                    fontStyle: FontStyle.italic),
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            req['createdAt']?.toString().split('T').first ?? '',
                                            style: const TextStyle(
                                                color: AppColors.textMuted, fontSize: 11),
                                          ),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              icon: const Icon(Icons.info_outline, size: 16),
                                              label: const Text('Details'),
                                              onPressed: () => _showRequestDetail(req),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                          // Sessions / Bookings Tab
                          _filterBookings(_bookings).isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.event_outlined, size: 56, color: AppColors.textMuted),
                                      SizedBox(height: 12),
                                      Text('No sessions found',
                                          style: TextStyle(color: AppColors.textSecondary)),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filterBookings(_bookings).length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (_, i) {
                                    final booking = _filterBookings(_bookings)[i];
                                    final student = booking['student'];
                                    final mentor = booking['mentor'];
                                    final mentorUser = mentor is Map ? mentor['user'] : null;
                                    final status = booking['status']?.toString() ?? '';
                                    final slot = booking['slot']?.toString() ?? '';
                                    return AppCard(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      student is Map ? student['name'] ?? 'N/A' : 'N/A',
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight.w700, fontSize: 15),
                                                    ),
                                                    Text(
                                                      '→ ${mentorUser is Map ? mentorUser['name'] ?? 'N/A' : 'N/A'}',
                                                      style: const TextStyle(
                                                          color: AppColors.textSecondary, fontSize: 13),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 10, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: _statusColor(status).withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  status.isEmpty ? 'Booked' : status,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: _statusColor(status),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (slot.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.schedule, size: 14,
                                                      color: AppColors.textMuted),
                                                  const SizedBox(width: 4),
                                                  Text(slot,
                                                      style: const TextStyle(
                                                          color: AppColors.textMuted, fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              icon: const Icon(Icons.info_outline, size: 16),
                                              label: const Text('Details'),
                                              onPressed: () => _showBookingDetail(booking),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
        ],
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
        ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ],
    );
  }
}
