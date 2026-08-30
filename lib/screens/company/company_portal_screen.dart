import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

class CompanyPortalScreen extends StatefulWidget {
  final int initialTab;
  const CompanyPortalScreen({super.key, this.initialTab = 0});

  @override
  State<CompanyPortalScreen> createState() => _CompanyPortalScreenState();
}

class _CompanyPortalScreenState extends State<CompanyPortalScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Company Portal',
      body: Column(
        children: [
          TabBar(
            controller: _tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            tabs: const [Tab(text: 'Find Candidates'), Tab(text: 'Post a Job')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [_CandidateSearchTab(), _PostJobTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateSearchTab extends StatefulWidget {
  const _CandidateSearchTab();

  @override
  State<_CandidateSearchTab> createState() => _CandidateSearchTabState();
}

class _CandidateSearchTabState extends State<_CandidateSearchTab> {
  late Future<List<CandidateProfile>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = BackendRepository.instance.getCandidates();
  }

  void _search(String query) {
    setState(() {
      _query = query;
      _future = BackendRepository.instance.getCandidates(skill: query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        AppSearchField(hint: 'Search by skill (e.g. React, Python)...', onChanged: _search),
        const SizedBox(height: 16),
        FutureBuilder<List<CandidateProfile>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => _search(_query), child: const Text('Retry')),
                  ],
                ),
              );
            }
            final candidates = snapshot.data ?? const [];
            if (candidates.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('No candidates found.', style: TextStyle(color: AppColors.textMuted))),
              );
            }
            return Column(
              children: candidates
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CandidateCard(candidate: c),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final CandidateProfile candidate;
  const _CandidateCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialsAvatar(initials: candidate.initials, size: 50),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(candidate.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                    AppTag(label: '${candidate.matchPercent}%', bg: AppColors.successSoft, fg: AppColors.success),
                  ],
                ),
                const SizedBox(height: 3),
                Text('${candidate.course} · ${candidate.college}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: candidate.skills.map((s) => AppTag(label: s, bg: AppColors.surfaceMuted, fg: AppColors.textSecondary)).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(38), textStyle: const TextStyle(fontSize: 12.5)),
                        child: const Text('View Profile'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Invited ${candidate.name} to apply!'), backgroundColor: AppColors.success),
                          );
                        },
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(38), textStyle: const TextStyle(fontSize: 12.5)),
                        child: const Text('Invite'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostJobTab extends StatefulWidget {
  const _PostJobTab();

  @override
  State<_PostJobTab> createState() => _PostJobTabState();
}

class _PostJobTabState extends State<_PostJobTab> {
  String _type = 'Full-time';
  bool _posting = false;
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _salaryOrStipendCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '3 months');

  @override
  void dispose() {
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _locationCtrl.dispose();
    _salaryOrStipendCtrl.dispose();
    _skillsCtrl.dispose();
    _descriptionCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _companyCtrl.text.trim().isEmpty ||
        _locationCtrl.text.trim().isEmpty ||
        _descriptionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title, company, location & description.'), backgroundColor: AppColors.warning),
      );
      return;
    }

    final skills = _skillsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    setState(() => _posting = true);
    try {
      if (_type == 'Internship') {
        await BackendRepository.instance.createInternship(
          title: _titleCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          company: _companyCtrl.text.trim(),
          location: _locationCtrl.text.trim(),
          duration: _durationCtrl.text.trim().isEmpty ? '3 months' : _durationCtrl.text.trim(),
          stipend: num.tryParse(_salaryOrStipendCtrl.text.trim()),
          skillsRequired: skills,
        );
      } else {
        await BackendRepository.instance.createJob(
          title: _titleCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          company: _companyCtrl.text.trim(),
          location: _locationCtrl.text.trim(),
          jobType: 'Full-time',
          skillsRequired: skills,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opportunity posted successfully!'), backgroundColor: AppColors.success),
      );
      _titleCtrl.clear();
      _companyCtrl.clear();
      _locationCtrl.clear();
      _salaryOrStipendCtrl.clear();
      _skillsCtrl.clear();
      _descriptionCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        const Text('Role Title', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'e.g. Data Analyst')),
        const SizedBox(height: 16),
        const Text('Opportunity Type', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: ['Full-time', 'Internship'].map((t) {
            final selected = _type == t;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(t),
                selected: selected,
                onSelected: (_) => setState(() => _type = t),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceMuted,
                labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide.none),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Text('Company', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(controller: _companyCtrl, decoration: const InputDecoration(hintText: 'e.g. Flipkart')),
        const SizedBox(height: 16),
        const Text('Location', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(controller: _locationCtrl, decoration: const InputDecoration(hintText: 'e.g. Bengaluru / Remote')),
        if (_type == 'Internship') ...[
          const SizedBox(height: 16),
          const Text('Duration', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(controller: _durationCtrl, decoration: const InputDecoration(hintText: 'e.g. 3 months')),
        ],
        const SizedBox(height: 16),
        Text(_type == 'Internship' ? 'Monthly Stipend' : 'Salary (annual, ₹)', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _salaryOrStipendCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: _type == 'Internship' ? 'e.g. 15000' : 'e.g. 1000000'),
        ),
        const SizedBox(height: 16),
        const Text('Required Skills', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(controller: _skillsCtrl, decoration: const InputDecoration(hintText: 'e.g. SQL, Python, Power BI (comma separated)')),
        const SizedBox(height: 16),
        const Text('Job Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(controller: _descriptionCtrl, maxLines: 4, decoration: const InputDecoration(hintText: 'Describe the role & responsibilities...')),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _posting ? null : _submit,
          child: _posting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
              : const Text('Post Opportunity'),
        ),
      ],
    );
  }
}
