import 'package:flutter/material.dart';
import '../jobs/job_portal_screen.dart';

/// Internship Portal — reuses the unified Opportunity Center, pre-selected
/// to the Internships tab so students reach it directly in one tap.
class InternshipPortalScreen extends StatelessWidget {
  const InternshipPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const JobPortalScreen(initialTab: 1);
  }
}
