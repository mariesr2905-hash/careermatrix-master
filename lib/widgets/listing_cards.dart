import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';
import 'common_widgets.dart';

class MentorCard extends StatelessWidget {
  final MentorProfile mentor;
  final VoidCallback? onTap;
  final VoidCallback? onBook;

  const MentorCard({super.key, required this.mentor, this.onTap, this.onBook});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialsAvatar(initials: mentor.initials, size: 54),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(mentor.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                    ),
                    AppTag(label: '${mentor.matchPercent}% match', bg: AppColors.successSoft, fg: AppColors.success),
                  ],
                ),
                const SizedBox(height: 3),
                Text('${mentor.role} · ${mentor.company}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppTag(label: mentor.domain, icon: Icons.workspace_premium_rounded),
                    AppTag(label: '${mentor.experienceYears} yrs exp', bg: AppColors.surfaceMuted, fg: AppColors.textSecondary),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                    const SizedBox(width: 3),
                    Text(mentor.rating.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const Spacer(),
                    SizedBox(
  width: 120,
  height: 36,
  child: ElevatedButton(
    onPressed: onBook,
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      textStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
    child: const Text('Book Session'),
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

class JobCard extends StatelessWidget {
  final JobListing job;
  final VoidCallback? onTap;
  final bool showApply;

  const JobCard({super.key, required this.job, this.onTap, this.showApply = true});

  @override
  Widget build(BuildContext context) {
    final isInternship = job.type == 'Internship';
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isInternship ? AppColors.accentIndigo.withOpacity(0.1) : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isInternship ? Icons.school_rounded : Icons.business_center_rounded,
                  color: isInternship ? AppColors.accentIndigo : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                    const SizedBox(height: 2),
                    Text('${job.company} · ${job.location}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              AppTag(label: '${job.matchPercent}%', bg: AppColors.successSoft, fg: AppColors.success),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: job.tags.map((t) => AppTag(label: t, bg: AppColors.surfaceMuted, fg: AppColors.textSecondary)).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.payments_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(job.salary, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 14),
              const Icon(Icons.schedule_rounded, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(job.postedAgo, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const Spacer(),
              if (showApply)
               SizedBox(
  width: 80,
  height: 34,
  child: OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
