import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/file_downloader.dart';

class ResumeHubScreen extends StatefulWidget {
  const ResumeHubScreen({super.key});

  @override
  State<ResumeHubScreen> createState() => _ResumeHubScreenState();
}

class _ResumeHubScreenState extends State<ResumeHubScreen> {
  bool _loading = true;
  bool _busy = false;
  bool _hasResume = false;
  String? _fileName;
  String? _error;
  Future<ResumeAnalysis>? _analysisFuture;

  @override
  void initState() {
    super.initState();
    _checkResume();
  }

  Future<void> _checkResume() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final meta = await BackendRepository.instance.getMyResumeMeta();
      setState(() {
        _hasResume = meta != null;
        _fileName = meta?['fileName'] as String?;
        _analysisFuture = BackendRepository.instance.getResumeAnalysis();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload({required bool replacing}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;

    final file = result.files.first;
    setState(() => _busy = true);
    try {
      if (replacing) {
        await BackendRepository.instance.updateResume(file.bytes!, file.name);
      } else {
        await BackendRepository.instance.uploadResume(file.bytes!, file.name);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(replacing ? 'Resume replaced' : 'Resume uploaded'), backgroundColor: AppColors.success),
      );
      await _checkResume();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _preview() async {
    setState(() => _busy = true);
    try {
      if (kIsWeb) {
        // On web: open the PDF in a new browser tab for inline viewing
        final token = await BackendRepository.instance.getToken();
        final url = '${AppConfig.baseUrl}/resume/download';
        final separator = url.contains('?') ? '&' : '?';
        final viewUrl = token != null ? '$url${separator}token=$token' : url;
        openUrlInNewTab(viewUrl);
      } else {
        // On native: download to device
        final path = await BackendRepository.instance.downloadResume();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to $path — open it from your file manager.'), backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete resume?'),
        content: const Text('This will remove your uploaded resume from the server.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await BackendRepository.instance.deleteResume();
      await _checkResume();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Smart Resume Hub',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _checkResume, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  children: [
                    AppCard(
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(18)),
                            child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 30),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _hasResume ? (_fileName ?? 'resume.pdf') : 'No resume uploaded yet',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hasResume ? 'Stored on server · PDF' : 'Upload a PDF to get started',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: (_busy || !_hasResume) ? null : _preview,
                                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                                  label: const Text('Preview'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _busy ? null : () => _pickAndUpload(replacing: _hasResume),
                                  icon: const Icon(Icons.upload_rounded, size: 18),
                                  label: Text(_hasResume ? 'Replace' : 'Upload'),
                                ),
                              ),
                            ],
                          ),
                          if (_hasResume) ...[
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: _busy ? null : _delete,
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                              label: const Text('Delete resume', style: TextStyle(color: AppColors.danger)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('AI Resume Analysis', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 14),
                    FutureBuilder<ResumeAnalysis>(
                      future: _analysisFuture,
                      builder: (context, snapshot) {
                        if (_analysisFuture == null || snapshot.connectionState == ConnectionState.waiting) {
                          return const AppCard(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return AppCard(
                            child: Text(snapshot.error.toString(), style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                          );
                        }
                        final analysis = snapshot.data!;
                        final color = analysis.score >= 70
                            ? AppColors.success
                            : analysis.score >= 40
                                ? AppColors.warning
                                : AppColors.danger;
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                                    child: Text('${analysis.score}',
                                        style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 18)),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Profile Strength Score', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                                        Text('Computed from your resume, skills & profile', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 6),
                              ...analysis.strengths.map(
                                (s) => _AnalysisRow(icon: Icons.check_circle_rounded, color: AppColors.success, text: s),
                              ),
                              ...analysis.improvements.map(
                                (s) => _AnalysisRow(icon: Icons.warning_rounded, color: AppColors.warning, text: s),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('Portfolio', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 14),
                    AppCard(
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(color: AppColors.accentIndigo.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.web_rounded, color: AppColors.accentIndigo),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Build your portfolio site', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                                Text('Showcase projects, certificates & achievements', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _AnalysisRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _AnalysisRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.3))),
        ],
      ),
    );
  }
}
