import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

import '../../utils/file_downloader.dart';


class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  late Future<List<CertificateItem>> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = BackendRepository.instance.getMyCertificates();
  }

  void _reload() {
    setState(() {
      _future = BackendRepository.instance.getMyCertificates();
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Build the preview / download URL for a certificate
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> _buildCertUrl(CertificateItem cert) async {
    final token = await BackendRepository.instance.getToken();
    final base = AppConfig.baseUrl; // e.g. http://localhost:5000/api
    final url = '$base/certificates/${cert.id}/download';
    if (token != null && token.isNotEmpty) {
      return '$url?token=$token';
    }
    return url;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Open certificate for viewing
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _view(CertificateItem cert) async {
    if (kIsWeb) {
      // On web: open in new browser tab for preview
      final url = await _buildCertUrl(cert);
      openUrlInNewTab(url);
    } else {
      // On native: show bottom-sheet preview dialog
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _NativePreviewSheet(cert: cert),
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Add certificate
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _addCertificate() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;
    final file = result.files.first;

    if (!mounted) return;

    final titleCtrl = TextEditingController();
    final issuerCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Certificate Details'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('File: ${file.name}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
              const SizedBox(height: 12),
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Certificate name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: issuerCtrl,
                decoration: const InputDecoration(labelText: 'Issued by (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      await BackendRepository.instance.addCertificate(
        bytes: file.bytes!,
        filename: file.name,
        title: titleCtrl.text.trim(),
        issuer: issuerCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Certificate uploaded'),
            backgroundColor: AppColors.success),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Download (native)
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _download(CertificateItem cert) async {
    if (kIsWeb) {
      // On web, "download" = open with download intent
      final url = await _buildCertUrl(cert);
      openUrlInNewTab(url);
      return;
    }
    setState(() => _busy = true);
    try {
      final path = await BackendRepository.instance
          .downloadCertificate(cert.id, cert.originalName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Saved to $path — open from your file manager.'),
            backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Delete
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _delete(CertificateItem cert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete certificate?'),
        content: Text('This will remove "${cert.title}" from your profile.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await BackendRepository.instance.deleteCertificate(cert.id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Certificates & Achievements',
      floatingActionButton: FloatingActionButton(
        onPressed: _busy ? null : _addCertificate,
        backgroundColor: AppColors.primary,
        tooltip: 'Upload Certificate',
        child: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<CertificateItem>>(
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
                    const Icon(Icons.cloud_off_rounded,
                        size: 42, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _reload, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }

          final certs = snapshot.data ?? const [];

          if (certs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                          color: AppColors.warningSoft, shape: BoxShape.circle),
                      child: const Icon(Icons.emoji_events_rounded,
                          size: 48, color: AppColors.warning),
                    ),
                    const SizedBox(height: 20),
                    const Text('No Certificates Yet',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text(
                      "Upload your certificates to showcase\nyour achievements to employers.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _addCertificate,
                      icon: const Icon(Icons.upload_rounded),
                      label: const Text('Upload Certificate'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: certs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final c = certs[i];
              final isPdf = c.originalName.toLowerCase().endsWith('.pdf');
              return AppCard(
                onTap: () => _view(c),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Icon
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isPdf
                                ? AppColors.dangerSoft
                                : AppColors.warningSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isPdf
                                ? Icons.picture_as_pdf_rounded
                                : Icons.emoji_events_rounded,
                            color: isPdf ? AppColors.danger : AppColors.warning,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5)),
                              const SizedBox(height: 2),
                              if ((c.issuer ?? '').isNotEmpty)
                                Text(c.issuer!,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600)),
                              Row(
                                children: [
                                  Icon(
                                    isPdf
                                        ? Icons.picture_as_pdf_rounded
                                        : Icons.image_rounded,
                                    size: 12,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(c.originalName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11.5)),
                                  ),
                                ],
                              ),
                              if (c.createdAt != null)
                                Text(
                                  'Uploaded ${_timeAgo(c.createdAt!)}',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10.5),
                                ),
                            ],
                          ),
                        ),
                        // Tap-to-view hint
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textMuted),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _view(c),
                            icon: const Icon(Icons.visibility_rounded, size: 16),
                            label: const Text('View'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : () => _download(c),
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('Download'),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _delete(c),
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 20, color: AppColors.danger),
                          tooltip: 'Delete',
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.dangerSoft,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return 'just now';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Native preview bottom sheet (non-web platforms)
// ─────────────────────────────────────────────────────────────────────────────

class _NativePreviewSheet extends StatelessWidget {
  final CertificateItem cert;
  const _NativePreviewSheet({required this.cert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
                color: AppColors.border, borderRadius: BorderRadius.circular(4)),
          ),
          const Icon(Icons.emoji_events_rounded,
              size: 48, color: AppColors.warning),
          const SizedBox(height: 16),
          Text(cert.title,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          if ((cert.issuer ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(cert.issuer!,
                style: const TextStyle(color: AppColors.textMuted)),
          ],
          const SizedBox(height: 8),
          Text(cert.originalName,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 24),
          const Text(
            'To view this certificate, please use the Download button to save it to your device.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
