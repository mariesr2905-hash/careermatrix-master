import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

class EducationDetailScreen extends StatelessWidget {
  final EducationRecord record;
  const EducationDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Education Details',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    record.institution,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.degree,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    context,
                    icon: Icons.business_rounded,
                    label: 'College / Institution',
                    value: record.institution,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    icon: Icons.workspace_premium_rounded,
                    label: 'Degree',
                    value: record.degree,
                  ),
                  if ((record.department ?? '').trim().isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      context,
                      icon: Icons.account_tree_outlined,
                      label: 'Department',
                      value: record.department!,
                    ),
                  ],
                  if ((record.course ?? '').trim().isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      context,
                      icon: Icons.book_outlined,
                      label: 'Course / Field of Study',
                      value: record.course!,
                    ),
                  ],
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    icon: Icons.calendar_today_rounded,
                    label: 'Duration / Study Period',
                    value: '${record.startYear} - ${record.endYear ?? 'Present'}',
                  ),
                  if ((record.grade ?? '').trim().isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      context,
                      icon: Icons.grade_rounded,
                      label: 'Marks / CGPA / Percentage',
                      value: record.grade!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryLight),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
