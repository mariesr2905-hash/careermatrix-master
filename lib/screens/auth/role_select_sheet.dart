import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';

IconData roleIcon(UserRole r) {
  switch (r) {
    case UserRole.student:
      return Icons.school_rounded;
    case UserRole.alumni:
      return Icons.workspace_premium_rounded;
    case UserRole.mentor:
      return Icons.diversity_3_rounded;
    case UserRole.company:
      return Icons.apartment_rounded;
    case UserRole.admin:
      return Icons.admin_panel_settings_rounded;
  }
}

class RoleSelectSheet extends StatelessWidget {
  final UserRole initial;
  const RoleSelectSheet({super.key, required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Choose your role', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                const Text('This personalizes your dashboard and features.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 16),
                ...UserRole.values.map((role) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.of(context).pop(role),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: role == initial ? AppColors.primarySoft : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(16),
                            border: role == initial ? Border.all(color: AppColors.primary, width: 1.4) : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    gradient: AppColors.roleGradient(role.key), borderRadius: BorderRadius.circular(12)),
                                child: Icon(roleIcon(role), color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(role.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                    Text(role.tagline, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                  ],
                                ),
                              ),
                              if (role == initial) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
