import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late Future<List<ForumPost>> _future;

  @override
  void initState() {
    super.initState();
    _future = BackendRepository.instance.getForumPosts();
  }

  void _reload() {
    setState(() {
      _future = BackendRepository.instance.getForumPosts();
    });
  }

  Future<void> _createPostDialog() async {
    final ctrl = TextEditingController();
    final posted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Share with the community'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: "What's on your mind?"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Post')),
        ],
      ),
    );
    if (posted != true || ctrl.text.trim().isEmpty) return;
    try {
      await BackendRepository.instance.createPost(ctrl.text.trim());
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: FutureBuilder<List<ForumPost>>(
            future: _future,
            builder: (context, snapshot) {
              final loading = snapshot.connectionState == ConnectionState.waiting;
              final posts = snapshot.data ?? const [];
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Community', style: Theme.of(context).textTheme.headlineSmall),
                      InkWell(
                        onTap: _createPostDialog,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.add_rounded, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Discussions, interview experiences & events', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(gradient: AppColors.cyanGradient, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        const Icon(Icons.event_available_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text('Career Matrix Hackathon — Registrations Open! Build an AI project in 48 hours.',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Trending Discussions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 14),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _reload, child: const Text('Retry')),
                        ],
                      ),
                    )
                  else if (posts.isEmpty)
                    const Text('No posts yet. Be the first to share something!', style: TextStyle(color: AppColors.textMuted))
                  else
                    ...posts.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ForumPostCard(post: p, onLike: () => _like(p)),
                        )),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _like(ForumPost p) async {
    if (p.id == null) return;
    try {
      await BackendRepository.instance.toggleLikePost(p.id!);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }
}

class _ForumPostCard extends StatelessWidget {
  final ForumPost post;
  final VoidCallback onLike;
  const _ForumPostCard({required this.post, required this.onLike});

  void _openComments(BuildContext context) {
    if (post.id == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(postId: post.id!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => _openComments(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(gradient: AppColors.heroGradient, shape: BoxShape.circle),
                child: Text(post.author.isNotEmpty ? post.author.substring(0, 1) : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.author, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    Text(post.role, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                  ],
                ),
              ),
              Text(post.timeAgo, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 6),
          Text(post.preview, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: onLike,
                child: Icon(post.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 17, color: post.likedByMe ? AppColors.danger : AppColors.textMuted),
              ),
              const SizedBox(width: 5),
              Text('${post.likes}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              InkWell(
                onTap: () => _openComments(context),
                child: const Icon(Icons.mode_comment_outlined, size: 16, color: AppColors.textMuted),
              ),
              const SizedBox(width: 5),
              Text('${post.comments}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              const Spacer(),
              const Icon(Icons.share_outlined, size: 17, color: AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final String postId;
  const _CommentsSheet({required this.postId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  late Future<List<PostComment>> _future;
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = BackendRepository.instance.getPostComments(widget.postId);
  }

  void _reload() {
    setState(() {
      _future = BackendRepository.instance.getPostComments(widget.postId);
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await BackendRepository.instance.addComment(widget.postId, text);
      _controller.clear();
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 14),
              Container(width: 40, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 14),
              const Text('Comments', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<PostComment>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(snapshot.error.toString(), style: const TextStyle(color: AppColors.textMuted)),
                      );
                    }
                    final comments = snapshot.data ?? const [];
                    if (comments.isEmpty) {
                      return const Center(child: Text('No comments yet. Be the first!', style: TextStyle(color: AppColors.textMuted)));
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: comments.length,
                      itemBuilder: (context, i) {
                        final c = comments[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(c.author, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                  const SizedBox(width: 8),
                                  Text(c.timeAgo, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(c.text, style: const TextStyle(fontSize: 13, height: 1.4)),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(hintText: 'Write a comment...'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
                            : const Icon(Icons.send_rounded, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
