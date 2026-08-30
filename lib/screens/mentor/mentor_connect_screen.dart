import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/listing_cards.dart';

class MentorConnectScreen extends StatefulWidget {
  const MentorConnectScreen({super.key});

  @override
  State<MentorConnectScreen> createState() => _MentorConnectScreenState();
}

class _MentorConnectScreenState extends State<MentorConnectScreen> {
  String _filter = 'All';
  String _query = '';
  final _domains = const ['All', 'Data Science', 'Product', 'Web Development', 'Cloud Computing', 'Career Coaching', 'General'];
  late Future<List<MentorProfile>> _mentorsFuture;

  @override
  void initState() {
    super.initState();
    _mentorsFuture = BackendRepository.instance.getMentors();
  }

  void _reload() {
    setState(() => _mentorsFuture = BackendRepository.instance.getMentors());
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Mentor Connect',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: AppSearchField(
              hint: 'Search mentors by name or domain...',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _domains.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final d = _domains[i];
                final selected = d == _filter;
                return ChoiceChip(
                  label: Text(d),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = d),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceMuted,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide.none),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: FutureBuilder<List<MentorProfile>>(
              future: _mentorsFuture,
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
                var mentors = snapshot.data ?? const [];
                if (_filter != 'All') mentors = mentors.where((m) => m.domain == _filter).toList();
                if (_query.trim().isNotEmpty) {
                  final q = _query.toLowerCase();
                  mentors = mentors.where((m) => m.name.toLowerCase().contains(q) || m.domain.toLowerCase().contains(q)).toList();
                }
                if (mentors.isEmpty) {
                  return const Center(child: Text('No mentors found.', style: TextStyle(color: AppColors.textMuted)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  itemCount: mentors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final m = mentors[i];
                    return MentorCard(
                      mentor: m,
                      onTap: () => _showMentorProfile(context, m),
                      onBook: () => _bookSession(context, m),
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

  void _showMentorProfile(BuildContext context, MentorProfile m) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 4),
            Text('${m.role} at ${m.company}', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Text(
              '${m.name} has ${m.experienceYears}+ years of experience in ${m.domain} and mentors students '
              'through Career Matrix, helping them prepare for roles at top companies.',
              style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _sendMentorshipRequest(context, m);
                    },
                    child: const Text('Request Mentorship'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _bookSession(context, m);
                    },
                    child: const Text('Book a Session'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _bookSession(BuildContext context, MentorProfile m) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    final timeCtrl = TextEditingController(text: '10:00 AM');
    final topicCtrl = TextEditingController();
    bool booking = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirm Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Book a session with ${m.name}.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Date: ${selectedDate.toLocal().toString().split(' ').first}'),
                trailing: const Icon(Icons.calendar_today_rounded, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogCtx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
              ),
              TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Time (e.g. 10:00 AM)')),
              const SizedBox(height: 8),
              TextField(controller: topicCtrl, decoration: const InputDecoration(labelText: 'Topic (optional)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: booking || m.id == null
                  ? null
                  : () async {
                      setDialogState(() => booking = true);
                      try {
                        await BackendRepository.instance.bookMentorSession(
                          mentorId: m.id!,
                          sessionDate: selectedDate,
                          sessionTime: timeCtrl.text.trim().isEmpty ? '10:00 AM' : timeCtrl.text.trim(),
                          topic: topicCtrl.text.trim(),
                        );
                        if (!dialogCtx.mounted) return;
                        Navigator.of(dialogCtx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Session request sent to ${m.name}!'), backgroundColor: AppColors.success),
                        );
                      } catch (e) {
                        setDialogState(() => booking = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                        );
                      }
                    },
              child: booking
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMentorshipRequest(BuildContext context, MentorProfile m) async {
    if (m.id == null) return;
    final messageCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Request Mentorship from ${m.name}'),
        content: TextField(
          controller: messageCtrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Introduce yourself and what you\'re looking for (optional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Send Request')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await BackendRepository.instance.sendMentorshipRequest(m.id!, message: messageCtrl.text.trim());
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mentorship request sent to ${m.name}!'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
    }
  }
}
