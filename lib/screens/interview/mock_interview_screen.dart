import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/score_gauge.dart';

class MockInterviewScreen extends StatefulWidget {
  const MockInterviewScreen({super.key});

  @override
  State<MockInterviewScreen> createState() => _MockInterviewScreenState();
}

class _MockInterviewScreenState extends State<MockInterviewScreen> {
  late Future<List<InterviewSession>> _future;

  @override
  void initState() {
    super.initState();
    _future = BackendRepository.instance.getInterviewHistory();
  }

  void _reload() {
    setState(() {
      _future = BackendRepository.instance.getInterviewHistory();
    });
  }

  Future<void> _startRound(String type) async {
    List<Map<String, dynamic>> questions;
    try {
      questions = await BackendRepository.instance.getInterviewQuestions(category: type);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      return;
    }
    if (questions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No $type questions are in the question bank yet.'), backgroundColor: AppColors.warning),
      );
      return;
    }

    final question = questions[Random().nextInt(questions.length)];
    final answerCtrl = TextEditingController();

    if (!mounted) return;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('$type Round'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question['question'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: answerCtrl,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Type your answer...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Submit')),
        ],
      ),
    );

    if (submitted != true) return;

    // No AI-scoring backend exists yet; a light heuristic (answer length /
    // completeness) stands in until a real scoring model is wired up.
    final answer = answerCtrl.text.trim();
    final score = answer.isEmpty ? 0.0 : (4 + min(answer.split(' ').length / 12, 6)).clamp(0, 10);

    try {
      await BackendRepository.instance.saveInterviewResult(
        type: type,
        questionsAttempted: [
          {
            'questionText': question['question'],
            'userAnswer': answer,
            'score': score,
          }
        ],
      );
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Round submitted — scored ${score.toStringAsFixed(1)}/10'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Mock Interview Arena',
      body: FutureBuilder<List<InterviewSession>>(
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
          final sessions = snapshot.data ?? const [];
          final completed = sessions.where((s) => s.lastScore > 0).toList();
          final avg = completed.isEmpty
              ? 0
              : (completed.map((s) => s.lastScore).reduce((a, b) => a + b) / completed.length).round();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            children: [
              AppCard(
                color: AppColors.primaryDeep,
                child: Row(
                  children: [
                    ScoreGauge(score: avg, size: 72, color: Colors.white, trackColor: Colors.white24, label: 'AVG'),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Average Interview Score', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 6),
                          Text('Across ${completed.length} completed sessions',
                              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _TypeCard(
                      icon: Icons.terminal_rounded,
                      title: 'Technical',
                      subtitle: 'DSA, System Design, SQL',
                      color: AppColors.primary,
                      onTap: () => _startRound('Technical'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeCard(
                      icon: Icons.forum_rounded,
                      title: 'HR Round',
                      subtitle: 'Behavioral & culture-fit',
                      color: AppColors.accentIndigo,
                      onTap: () => _startRound('HR'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text('Past Sessions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 14),
              if (sessions.isEmpty)
                const Text('No mock interview attempts yet. Start a round above!', style: TextStyle(color: AppColors.textMuted))
              else
                ...sessions.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SessionCard(session: s),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _TypeCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final InterviewSession session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final completed = session.lastScore > 0;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: session.type == 'Technical' ? AppColors.primarySoft : AppColors.accentIndigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              session.type == 'Technical' ? Icons.terminal_rounded : Icons.forum_rounded,
              color: session.type == 'Technical' ? AppColors.primary : AppColors.accentIndigo,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    AppTag(label: session.difficulty, bg: AppColors.surfaceMuted, fg: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('~${session.durationMins} min', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          if (completed)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${session.lastScore}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.success, fontSize: 16)),
                const Text('score', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
        ],
      ),
    );
  }
}
