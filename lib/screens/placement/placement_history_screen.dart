import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

class PlacementHistoryScreen extends StatefulWidget {
  const PlacementHistoryScreen({super.key});

  @override
  State<PlacementHistoryScreen> createState() => _PlacementHistoryScreenState();
}

class _PlacementHistoryScreenState extends State<PlacementHistoryScreen> {
  late Future<List<PlacementRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = BackendRepository.instance.getMyPlacementHistory();
  }

  void _reload() {
    setState(() {
      _future = BackendRepository.instance.getMyPlacementHistory();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Placed':
      case 'Offered':
        return AppColors.success;
      case 'Rejected':
      case 'Withdrawn':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Placement History',
      body: FutureBuilder<List<PlacementRecord>>(
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
          final records = snapshot.data ?? const [];
          if (records.isEmpty) {
            return const EmptyState(
              icon: Icons.workspace_premium_outlined,
              title: 'No placement records yet',
              subtitle: 'Your placement cell will add records here once available',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            itemCount: records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final r = records[i];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(r.jobTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                        AppTag(label: r.status, bg: _statusColor(r.status).withOpacity(0.12), fg: _statusColor(r.status)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(r.company, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        if (r.location != null && r.location!.isNotEmpty)
                          _InfoBit(icon: Icons.place_outlined, text: r.location!),
                        _InfoBit(icon: Icons.work_outline_rounded, text: r.placementType),
                        if (r.package != null) _InfoBit(icon: Icons.payments_outlined, text: '₹${r.package} LPA'),
                        if (r.placementDate.isNotEmpty)
                          _InfoBit(icon: Icons.event_outlined, text: r.placementDate.split('T').first),
                      ],
                    ),
                    if (r.remarks != null && r.remarks!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(r.remarks!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.4)),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _InfoBit extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoBit({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
