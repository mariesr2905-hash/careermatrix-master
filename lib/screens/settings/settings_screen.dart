import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import 'static_content_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _prefsKeyPush = 'cm_pref_push';
  static const _prefsKeyEmail = 'cm_pref_email';
  static const _prefsKeyJobAlerts = 'cm_pref_job_alerts';
  static const _prefsKeyMentorAlerts = 'cm_pref_mentor_alerts';

  bool _push = true;
  bool _email = true;
  bool _jobAlerts = true;
  bool _mentorAlerts = false;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _push = prefs.getBool(_prefsKeyPush) ?? true;
      _email = prefs.getBool(_prefsKeyEmail) ?? true;
      _jobAlerts = prefs.getBool(_prefsKeyJobAlerts) ?? true;
      _mentorAlerts = prefs.getBool(_prefsKeyMentorAlerts) ?? false;
    });
  }

  Future<void> _setPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SwitchRow(title: 'Push Notifications', value: _push, onChanged: (v) {
                  setState(() => _push = v);
                  _setPref(_prefsKeyPush, v);
                }),
                const Divider(height: 1, indent: 16),
                _SwitchRow(title: 'Email Updates', value: _email, onChanged: (v) {
                  setState(() => _email = v);
                  _setPref(_prefsKeyEmail, v);
                }),
                const Divider(height: 1, indent: 16),
                _SwitchRow(title: 'Job & Internship Alerts', value: _jobAlerts, onChanged: (v) {
                  setState(() => _jobAlerts = v);
                  _setPref(_prefsKeyJobAlerts, v);
                }),
                const Divider(height: 1, indent: 16),
                _SwitchRow(title: 'Mentor Session Reminders', value: _mentorAlerts, onChanged: (v) {
                  setState(() => _mentorAlerts = v);
                  _setPref(_prefsKeyMentorAlerts, v);
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Appearance', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: _SwitchRow(
              title: 'Dark Mode',
              subtitle: 'Career Matrix looks best in Light mode',
              value: _darkMode,
              onChanged: (v) => setState(() => _darkMode = v),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Privacy', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _NavRow(title: 'Profile Visibility', onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile visibility controls are not available yet.')),
                  );
                }),
                const Divider(height: 1, indent: 16),
                _NavRow(
                  title: 'Data & Privacy Policy',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const StaticContentScreen(title: 'Data & Privacy Policy', body: kPrivacyPolicyText),
                  )),
                ),
                const Divider(height: 1, indent: 16),
                _NavRow(title: 'Blocked Users', onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No blocked users yet.')),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('About', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _NavRow(
                  title: 'Terms of Service',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const StaticContentScreen(title: 'Terms of Service', body: kTermsOfServiceText),
                  )),
                ),
                const Divider(height: 1, indent: 16),
                _NavRow(title: 'App Version', trailing: 'v1.0.0', onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({required this.title, this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: Colors.white, activeTrackColor: AppColors.primary),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  const _NavRow({required this.title, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
            if (trailing != null) Text(trailing!, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
