import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import 'education_detail_screen.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  late Future<List<EducationRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = BackendRepository.instance.getMyEducation();
  }

  void _reload() {
    setState(() {
      _future = BackendRepository.instance.getMyEducation();
    });
  }

  Future<void> _openForm({EducationRecord? existing}) async {
    final institutionCtrl = TextEditingController(text: existing?.institution ?? '');
    final degreeCtrl = TextEditingController(text: existing?.degree ?? '');
    final departmentCtrl = TextEditingController(text: existing?.department ?? '');
    final courseCtrl = TextEditingController(text: existing?.course ?? '');
    final startYearCtrl = TextEditingController(text: existing?.startYear.toString() ?? '');
    final endYearCtrl = TextEditingController(text: existing?.endYear?.toString() ?? '');
    final gradeCtrl = TextEditingController(text: existing?.grade ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(existing == null ? 'Add Education' : 'Edit Education'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: institutionCtrl,
                  decoration: const InputDecoration(labelText: 'College / Institution'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: degreeCtrl,
                  decoration: const InputDecoration(labelText: 'Degree'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: departmentCtrl,
                  decoration: const InputDecoration(labelText: 'Department (optional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: courseCtrl,
                  decoration: const InputDecoration(labelText: 'Course (optional)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: startYearCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Start year'),
                        validator: (v) => (v == null || int.tryParse(v.trim()) == null) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: endYearCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'End year (optional)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: gradeCtrl,
                  decoration: const InputDecoration(labelText: 'CGPA / Percentage (optional)'),
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
                if (existing == null) {
                  await BackendRepository.instance.addEducation(
                    institution: institutionCtrl.text.trim(),
                    degree: degreeCtrl.text.trim(),
                    department: departmentCtrl.text.trim(),
                    course: courseCtrl.text.trim(),
                    startYear: int.parse(startYearCtrl.text.trim()),
                    endYear: endYearCtrl.text.trim().isEmpty ? null : int.tryParse(endYearCtrl.text.trim()),
                    grade: gradeCtrl.text.trim(),
                  );
                } else {
                  await BackendRepository.instance.updateEducation(
                    existing.id!,
                    institution: institutionCtrl.text.trim(),
                    degree: degreeCtrl.text.trim(),
                    department: departmentCtrl.text.trim(),
                    course: courseCtrl.text.trim(),
                    startYear: int.parse(startYearCtrl.text.trim()),
                    endYear: endYearCtrl.text.trim().isEmpty ? null : int.tryParse(endYearCtrl.text.trim()),
                    grade: gradeCtrl.text.trim(),
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx)
                      .showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Education record saved')));
      }
    }
  }

  Future<void> _delete(EducationRecord record) async {
    if (record.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete education record?'),
        content: Text('This will remove ${record.institution} from your profile.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await BackendRepository.instance.deleteEducation(record.id!);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Education Details',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<EducationRecord>>(
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
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
              children: const [
                Center(
                  child: Text(
                    "You haven't added any education records yet.\nTap + to add your first one.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final r = records[i];
              return AppCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => EducationDetailScreen(record: r)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.school_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.institution, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                          const SizedBox(height: 2),
                          Text(
                            [r.degree, if ((r.department ?? '').isNotEmpty) r.department].join(' · '),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${r.startYear} - ${r.endYear ?? 'Present'}${(r.grade ?? '').isNotEmpty ? ' · ${r.grade}' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _openForm(existing: r),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                          onPressed: () => _delete(r),
                        ),
                      ],
                    ),
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
