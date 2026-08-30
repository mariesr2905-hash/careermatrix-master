// lib/screens/admin/content_moderation_screen.dart
//
// Content Moderation page for the Admin Dashboard.
// Displays community forum posts. Admin can Approve, Remove, or flag
// for Review. Local state tracks per-post moderation decisions
// immediately so the UI updates instantly. A real backend moderation
// endpoint can replace the local state in the future.

import 'package:flutter/material.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

enum _ModerationStatus { none, approved, removed, underReview }

class ContentModerationScreen extends StatefulWidget {
  const ContentModerationScreen({super.key});

  @override
  State<ContentModerationScreen> createState() => _ContentModerationScreenState();
}

class _ContentModerationScreenState extends State<ContentModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  // Per-post local moderation status (postId → status)
  final Map<String, _ModerationStatus> _moderationStatus = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
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
      final posts = await BackendRepository.instance.getForumPosts();
      if (!mounted) return;
      setState(() {
        // Convert ForumPost to raw map-like structure for display
        _posts = posts
            .map((p) => {
                  '_id': p.id ?? '',
                  'content': p.preview,
                  'authorName': p.author,
                  'authorRole': p.role,
                  'likes': p.likes,
                  'timeAgo': p.timeAgo,
                  'commentCount': p.comments,
                })
            .toList();
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

  Future<void> _setStatus(String postId, _ModerationStatus status) async {
    if (status == _ModerationStatus.removed) {
      // Show confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Remove Content'),
          content: const Text(
              'This will permanently delete the post. This action cannot be undone.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      setState(() => _moderationStatus[postId] = _ModerationStatus.removed);
      try {
        await BackendRepository.instance.deletePost(postId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post removed successfully.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _moderationStatus.remove(postId));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(e.toString()),
                backgroundColor: AppColors.danger),
          );
        }
      }
    } else {
      setState(() => _moderationStatus[postId] = status);
      if (mounted) {
        final label = status == _ModerationStatus.approved
            ? 'approved'
            : 'flagged for review';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post $label.'),
            backgroundColor: status == _ModerationStatus.approved
                ? AppColors.success
                : AppColors.warning,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _filtered() {
    var list = _posts;

    // Tab filter
    switch (_tabs.index) {
      case 1: // Flagged
        list = list
            .where((p) =>
                _moderationStatus[p['_id']] == _ModerationStatus.underReview)
            .toList();
        break;
      case 2: // Approved
        list = list
            .where((p) =>
                _moderationStatus[p['_id']] == _ModerationStatus.approved)
            .toList();
        break;
      case 3: // Removed
        list = list
            .where((p) =>
                _moderationStatus[p['_id']] == _ModerationStatus.removed)
            .toList();
        break;
      default:
        break;
    }

    // Search filter
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((p) =>
              (p['content']?.toString().toLowerCase().contains(q) ?? false) ||
              (p['authorName']?.toString().toLowerCase().contains(q) ?? false))
          .toList();
    }

    return list;
  }

  int _countByStatus(_ModerationStatus s) =>
      _posts.where((p) => _moderationStatus[p['_id']] == s).length;

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered();
    final flaggedCount = _countByStatus(_ModerationStatus.underReview);
    final approvedCount = _countByStatus(_ModerationStatus.approved);
    final removedCount = _countByStatus(_ModerationStatus.removed);
    final pendingCount = _posts.length - flaggedCount - approvedCount - removedCount;

    return SimpleScreenScaffold(
      title: 'Content Moderation',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
          onPressed: _load,
        ),
      ],
      body: Column(
        children: [
          // Stats row
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  _MiniStat(
                      label: 'Total',
                      value: _posts.length,
                      color: AppColors.primary),
                  const SizedBox(width: 8),
                  _MiniStat(
                      label: 'Pending',
                      value: pendingCount,
                      color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  _MiniStat(
                      label: 'Flagged',
                      value: flaggedCount,
                      color: AppColors.warning),
                  const SizedBox(width: 8),
                  _MiniStat(
                      label: 'Removed',
                      value: removedCount,
                      color: AppColors.danger),
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
              Tab(text: 'All (${_posts.length})'),
              Tab(text: 'Flagged ($flaggedCount)'),
              Tab(text: 'Approved ($approvedCount)'),
              Tab(text: 'Removed ($removedCount)'),
            ],
          ),
          const SizedBox(height: 12),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppSearchField(
              hint: 'Search by content or author...',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 14),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(error: _error!, onRetry: _load)
                    : filtered.isEmpty
                        ? const Center(
                            child: EmptyState(
                              icon: Icons.fact_check_rounded,
                              title: 'No Content Here',
                              subtitle:
                                  'No posts match the current filter.',
                            ),
                          )
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(20, 0, 20, 40),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final post = filtered[i];
                              final postId = post['_id'].toString();
                              final status = _moderationStatus[postId] ??
                                  _ModerationStatus.none;
                              return _PostCard(
                                post: post,
                                status: status,
                                onApprove: () => _setStatus(
                                    postId, _ModerationStatus.approved),
                                onRemove: () => _setStatus(
                                    postId, _ModerationStatus.removed),
                                onReview: () => _setStatus(
                                    postId, _ModerationStatus.underReview),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final _ModerationStatus status;
  final VoidCallback onApprove;
  final VoidCallback onRemove;
  final VoidCallback onReview;

  const _PostCard({
    required this.post,
    required this.status,
    required this.onApprove,
    required this.onRemove,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final content = post['content']?.toString() ?? '';
    final author = post['authorName']?.toString() ?? 'Unknown';
    final role = post['authorRole']?.toString() ?? 'student';
    final likes = (post['likes'] as num?)?.toInt() ?? 0;
    final commentCount = (post['commentCount'] as num?)?.toInt() ?? 0;
    final timeAgo = post['timeAgo']?.toString();

    Color cardColor = AppColors.surface;
    if (status == _ModerationStatus.approved) cardColor = AppColors.successSoft;
    if (status == _ModerationStatus.removed) cardColor = AppColors.dangerSoft;
    if (status == _ModerationStatus.underReview) cardColor = AppColors.warningSoft;

    return AppCard(
      color: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: AppColors.roleGradient(role),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  author.isNotEmpty ? author[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(author,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            role,
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (timeAgo != null) ...[
                          const SizedBox(width: 6),
                          Text(timeAgo,
                              style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textMuted)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Status chip
              if (status == _ModerationStatus.approved)
                _StatusPill(
                    label: 'Approved', color: AppColors.success)
              else if (status == _ModerationStatus.removed)
                _StatusPill(label: 'Removed', color: AppColors.danger)
              else if (status == _ModerationStatus.underReview)
                _StatusPill(label: 'Under Review', color: AppColors.warning),
            ],
          ),
          const SizedBox(height: 12),
          // Content preview
          Text(
            content.length > 280
                ? '${content.substring(0, 280)}…'
                : content,
            style: const TextStyle(fontSize: 13.5, height: 1.5),
          ),
          const SizedBox(height: 10),
          // Metadata row
          Row(
            children: [
              const Icon(Icons.favorite_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('$likes',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(width: 12),
              const Icon(Icons.comment_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('$commentCount',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          // Action buttons (only if not already removed)
          if (status != _ModerationStatus.removed) ...[
            const Divider(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (status != _ModerationStatus.approved)
                    _ActionButton(
                      label: 'Approve',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                      onTap: onApprove,
                    ),
                  if (status != _ModerationStatus.underReview) ...[
                    const SizedBox(width: 8),
                    _ActionButton(
                      label: 'Review',
                      icon: Icons.flag_rounded,
                      color: AppColors.warning,
                      onTap: onReview,
                    ),
                  ],
                  const SizedBox(width: 8),
                  _ActionButton(
                    label: 'Remove',
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.danger,
                    onTap: onRemove,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ],
        ),
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
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.textMuted),
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
