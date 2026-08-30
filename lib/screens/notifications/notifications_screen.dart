import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<NotificationItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = BackendRepository.instance.getNotifications();
  }

  void _reload() {
    setState(() {
      _future = BackendRepository.instance.getNotifications();
    });
  }

  Future<void> _markAllRead() async {
    try {
      await BackendRepository.instance.markAllNotificationsRead();
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Notifications',
      actions: [
        TextButton(onPressed: _markAllRead, child: const Text('Mark all read')),
        const SizedBox(width: 8),
      ],
      body: FutureBuilder<List<NotificationItem>>(
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
          final notifications = snapshot.data ?? const [];
          if (notifications.isEmpty) {
            return const EmptyState(icon: Icons.notifications_none_rounded, title: 'No notifications yet', subtitle: 'You will see updates here');
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final n = notifications[i];
              final card = AppCard(
                onTap: () async {
                  if (n.unread && n.id != null) {
                    try {
                      await BackendRepository.instance.markNotificationRead(n.id!);
                      _reload();
                    } catch (_) {}
                  }
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: _colorFor(n.type).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(_iconFor(n.type), color: _colorFor(n.type), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5))),
                              if (n.unread)
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(n.subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4)),
                          const SizedBox(height: 6),
                          Text(n.timeAgo, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              if (n.id == null) return card;

              return Dismissible(
                key: ValueKey(n.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                ),
                onDismissed: (_) async {
                  try {
                    await BackendRepository.instance.deleteNotification(n.id!);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
                    }
                  }
                },
                child: card,
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'job':
        return Icons.work_rounded;
      case 'mentor':
        return Icons.diversity_3_rounded;
      case 'community':
        return Icons.forum_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'job':
        return AppColors.success;
      case 'mentor':
        return AppColors.primary;
      case 'community':
        return AppColors.accentIndigo;
      default:
        return AppColors.warning;
    }
  }
}
