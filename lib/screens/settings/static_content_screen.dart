import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class StaticContentScreen extends StatelessWidget {
  final String title;
  final String body;

  const StaticContentScreen({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: title,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text(body, style: const TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

const String kTermsOfServiceText = '''
Career Matrix Terms of Service

By using Career Matrix, you agree to provide accurate information when creating your profile, applying to jobs and internships, and interacting with mentors and other members of the community.

Your account is personal to you. Do not share your login credentials with anyone else. You are responsible for all activity that happens under your account.

Career Matrix connects students, alumni, mentors, and companies. We do not guarantee job placement, mentorship acceptance, or any specific outcome from using the platform.

Content you post in the community feed, including comments and posts, should be respectful and relevant to career development. Career Matrix reserves the right to remove content that violates these guidelines.

We may update these terms from time to time. Continued use of the app after changes are published constitutes acceptance of the updated terms.
''';

const String kPrivacyPolicyText = '''
Career Matrix Data & Privacy Policy

We store the information you provide — including your profile details, education history, skills, resume, and certificates — securely in our database, associated only with your account.

Your data is only accessible to you and, where the platform's role-based permissions allow it (for example, a company viewing applicants to their own job posting, or an admin managing accounts), to the relevant authorized users.

Uploaded files (resumes, certificates, profile photos) are stored on our servers and are only served to authenticated, authorized requests.

We do not sell your personal information to third parties.

You can update or remove most of your profile information at any time from the Profile section of the app. If you would like your account and associated data fully deleted, please contact an administrator.
''';
