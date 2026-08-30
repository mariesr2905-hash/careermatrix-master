// lib/screens/admin/admin_system_settings_screen.dart
//
// Comprehensive System Settings page for the Admin Dashboard.
// Has 5 sections: Profile/Account, Notifications, User Management,
// Security, and Application Preferences. Each section has Save
// functionality with immediate SnackBar feedback.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

class AdminSystemSettingsScreen extends StatefulWidget {
  const AdminSystemSettingsScreen({super.key});

  @override
  State<AdminSystemSettingsScreen> createState() =>
      _AdminSystemSettingsScreenState();
}

class _AdminSystemSettingsScreenState extends State<AdminSystemSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'System Settings',
      body: Column(
        children: [
          // Tab bar — scrollable so it fits on narrow screens
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Profile'),
              Tab(text: 'Notifications'),
              Tab(text: 'Users'),
              Tab(text: 'Security'),
              Tab(text: 'App'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                _ProfileSection(),
                _NotificationsSection(),
                _UserManagementSection(),
                _SecuritySection(),
                _AppPreferencesSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 1. Profile / Account section
// ────────────────────────────────────────────────────────────────────────────

class _ProfileSection extends StatefulWidget {
  const _ProfileSection();

  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _initialLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await BackendRepository.instance.getMyAppUser();
      if (!mounted) return;
      setState(() {
        _nameCtrl.text = user.name;
        _initialLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _initialLoaded = true);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await BackendRepository.instance.saveProfile({
        'bio': _bioCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _successSnack('Profile updated successfully!'),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _errorSnack(e.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        const Text('Profile & Account',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 14),
        AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _nameCtrl.text.isNotEmpty
                              ? _nameCtrl.text[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 32),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio / Description',
                    prefixIcon: Icon(Icons.notes_rounded),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: LoadingElevatedButton(
                    loading: _loading,
                    onPressed: _save,
                    child: const Text('Save Profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 2. Notifications section
// ────────────────────────────────────────────────────────────────────────────

class _NotificationsSection extends StatefulWidget {
  const _NotificationsSection();

  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
  static const _kPush = 'sys_push';
  static const _kEmail = 'sys_email';
  static const _kJobAlerts = 'sys_job_alerts';
  static const _kMentorAlerts = 'sys_mentor_alerts';
  static const _kNewUserAlerts = 'sys_new_user_alerts';
  static const _kModerationAlerts = 'sys_moderation_alerts';

  bool _push = true;
  bool _email = true;
  bool _jobAlerts = true;
  bool _mentorAlerts = true;
  bool _newUserAlerts = true;
  bool _moderationAlerts = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _push = prefs.getBool(_kPush) ?? true;
      _email = prefs.getBool(_kEmail) ?? true;
      _jobAlerts = prefs.getBool(_kJobAlerts) ?? true;
      _mentorAlerts = prefs.getBool(_kMentorAlerts) ?? true;
      _newUserAlerts = prefs.getBool(_kNewUserAlerts) ?? true;
      _moderationAlerts = prefs.getBool(_kModerationAlerts) ?? true;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setBool(_kPush, _push),
        prefs.setBool(_kEmail, _email),
        prefs.setBool(_kJobAlerts, _jobAlerts),
        prefs.setBool(_kMentorAlerts, _mentorAlerts),
        prefs.setBool(_kNewUserAlerts, _newUserAlerts),
        prefs.setBool(_kModerationAlerts, _moderationAlerts),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(_successSnack('Notification settings saved!'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_errorSnack(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        const Text('Notification Settings',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 14),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SwitchTile(
                icon: Icons.notifications_rounded,
                title: 'Push Notifications',
                subtitle: 'Receive real-time push alerts',
                value: _push,
                onChanged: (v) => setState(() => _push = v),
              ),
              const Divider(height: 1, indent: 16),
              _SwitchTile(
                icon: Icons.email_rounded,
                title: 'Email Updates',
                subtitle: 'Receive digest emails',
                value: _email,
                onChanged: (v) => setState(() => _email = v),
              ),
              const Divider(height: 1, indent: 16),
              _SwitchTile(
                icon: Icons.work_rounded,
                title: 'Job & Internship Alerts',
                subtitle: 'Notify users of new opportunities',
                value: _jobAlerts,
                onChanged: (v) => setState(() => _jobAlerts = v),
              ),
              const Divider(height: 1, indent: 16),
              _SwitchTile(
                icon: Icons.handshake_rounded,
                title: 'Mentor Session Reminders',
                subtitle: 'Remind users of upcoming sessions',
                value: _mentorAlerts,
                onChanged: (v) => setState(() => _mentorAlerts = v),
              ),
              const Divider(height: 1, indent: 16),
              _SwitchTile(
                icon: Icons.person_add_rounded,
                title: 'New User Registrations',
                subtitle: 'Alert admin on new sign-ups',
                value: _newUserAlerts,
                onChanged: (v) => setState(() => _newUserAlerts = v),
              ),
              const Divider(height: 1, indent: 16),
              _SwitchTile(
                icon: Icons.flag_rounded,
                title: 'Moderation Alerts',
                subtitle: 'Notify admin of flagged content',
                value: _moderationAlerts,
                onChanged: (v) => setState(() => _moderationAlerts = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: LoadingElevatedButton(
            loading: _saving,
            onPressed: _save,
            child: const Text('Save Notification Settings'),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 3. User Management settings
// ────────────────────────────────────────────────────────────────────────────

class _UserManagementSection extends StatefulWidget {
  const _UserManagementSection();

  @override
  State<_UserManagementSection> createState() => _UserManagementSectionState();
}

class _UserManagementSectionState extends State<_UserManagementSection> {
  static const _kAutoApprove = 'sys_auto_approve';
  static const _kRegistrationOpen = 'sys_registration_open';
  static const _kRequireEmailVerification = 'sys_require_email_verification';
  static const _kAllowSelfRoleChange = 'sys_allow_self_role_change';

  bool _autoApprove = false;
  bool _registrationOpen = true;
  bool _requireEmailVerification = true;
  bool _allowSelfRoleChange = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _autoApprove = prefs.getBool(_kAutoApprove) ?? false;
      _registrationOpen = prefs.getBool(_kRegistrationOpen) ?? true;
      _requireEmailVerification =
          prefs.getBool(_kRequireEmailVerification) ?? true;
      _allowSelfRoleChange = prefs.getBool(_kAllowSelfRoleChange) ?? false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setBool(_kAutoApprove, _autoApprove),
        prefs.setBool(_kRegistrationOpen, _registrationOpen),
        prefs.setBool(_kRequireEmailVerification, _requireEmailVerification),
        prefs.setBool(_kAllowSelfRoleChange, _allowSelfRoleChange),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(_successSnack('User management settings saved!'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_errorSnack(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        const Text('User Management Settings',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 14),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SwitchTile(
                icon: Icons.verified_user_rounded,
                title: 'Auto-Approve Alumni & Mentors',
                subtitle: 'Skip manual verification for new accounts',
                value: _autoApprove,
                onChanged: (v) => setState(() => _autoApprove = v),
              ),
              const Divider(height: 1, indent: 16),
              _SwitchTile(
                icon: Icons.app_registration_rounded,
                title: 'Open Registration',
                subtitle: 'Allow new users to sign up',
                value: _registrationOpen,
                onChanged: (v) => setState(() => _registrationOpen = v),
              ),
              const Divider(height: 1, indent: 16),
              _SwitchTile(
                icon: Icons.mark_email_read_rounded,
                title: 'Require Email Verification',
                subtitle: 'Users must verify their email before login',
                value: _requireEmailVerification,
                onChanged: (v) =>
                    setState(() => _requireEmailVerification = v),
              ),
              const Divider(height: 1, indent: 16),
              _SwitchTile(
                icon: Icons.manage_accounts_rounded,
                title: 'Allow Self Role Change',
                subtitle: 'Let users change their own role',
                value: _allowSelfRoleChange,
                onChanged: (v) => setState(() => _allowSelfRoleChange = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warningSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'These settings affect all users platform-wide. Changes take effect immediately.',
                  style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: LoadingElevatedButton(
            loading: _saving,
            onPressed: _save,
            child: const Text('Save User Management Settings'),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 4. Security settings
// ────────────────────────────────────────────────────────────────────────────

class _SecuritySection extends StatefulWidget {
  const _SecuritySection();

  @override
  State<_SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<_SecuritySection> {
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  static const _kTwoFactor = 'sys_two_factor';
  static const _kSessionTimeout = 'sys_session_timeout';

  bool _twoFactor = false;
  int _sessionTimeout = 60; // minutes
  bool _savingPassword = false;
  bool _savingOther = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _twoFactor = prefs.getBool(_kTwoFactor) ?? false;
      _sessionTimeout = prefs.getInt(_kSessionTimeout) ?? 60;
    });
  }

  Future<void> _changePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _savingPassword = true);
    try {
      // Attempt real backend call — /api/auth/change-password
      await BackendRepository.instance.changePassword(
        currentPassword: _currentPasswordCtrl.text,
        newPassword: _newPasswordCtrl.text,
      );
      if (mounted) {
        _currentPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
        ScaffoldMessenger.of(context)
            .showSnackBar(_successSnack('Password changed successfully!'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_errorSnack(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _saveOtherSettings() async {
    setState(() => _savingOther = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kTwoFactor, _twoFactor);
      await prefs.setInt(_kSessionTimeout, _sessionTimeout);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(_successSnack('Security settings saved!'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_errorSnack(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _savingOther = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        const Text('Change Password',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 14),
        AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _currentPasswordCtrl,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrent
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _newPasswordCtrl,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 8) ? 'Min 8 characters' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) => v != _newPasswordCtrl.text
                      ? 'Passwords do not match'
                      : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: LoadingElevatedButton(
                    loading: _savingPassword,
                    onPressed: _changePassword,
                    child: const Text('Update Password'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Security Preferences',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 14),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SwitchTile(
                icon: Icons.security_rounded,
                title: 'Two-Factor Authentication',
                subtitle: 'Require 2FA for admin login',
                value: _twoFactor,
                onChanged: (v) => setState(() => _twoFactor = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Session Timeout',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                'Auto logout after $_sessionTimeout minutes of inactivity',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              Slider(
                value: _sessionTimeout.toDouble(),
                min: 15,
                max: 480,
                divisions: 19,
                label: '$_sessionTimeout min',
                activeColor: AppColors.primary,
                onChanged: (v) =>
                    setState(() => _sessionTimeout = v.round()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: LoadingElevatedButton(
            loading: _savingOther,
            onPressed: _saveOtherSettings,
            child: const Text('Save Security Settings'),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 5. Application Preferences
// ────────────────────────────────────────────────────────────────────────────

class _AppPreferencesSection extends StatefulWidget {
  const _AppPreferencesSection();

  @override
  State<_AppPreferencesSection> createState() => _AppPreferencesSectionState();
}

class _AppPreferencesSectionState extends State<_AppPreferencesSection> {
  static const _kMaintenanceMode = 'sys_maintenance_mode';
  static const _kPlatformName = 'sys_platform_name';
  static const _kSupportEmail = 'sys_support_email';

  final _platformNameCtrl = TextEditingController(text: 'Career Matrix');
  final _supportEmailCtrl =
      TextEditingController(text: 'support@careermatrix.io');
  bool _maintenanceMode = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _platformNameCtrl.dispose();
    _supportEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _maintenanceMode = prefs.getBool(_kMaintenanceMode) ?? false;
      final name = prefs.getString(_kPlatformName);
      final email = prefs.getString(_kSupportEmail);
      if (name != null) _platformNameCtrl.text = name;
      if (email != null) _supportEmailCtrl.text = email;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setBool(_kMaintenanceMode, _maintenanceMode),
        prefs.setString(_kPlatformName, _platformNameCtrl.text.trim()),
        prefs.setString(_kSupportEmail, _supportEmailCtrl.text.trim()),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(_successSnack('Application preferences saved!'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_errorSnack(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        const Text('Application Preferences',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            children: [
              TextFormField(
                controller: _platformNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Platform Name',
                  prefixIcon: Icon(Icons.label_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _supportEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Support Email',
                  prefixIcon: Icon(Icons.support_agent_rounded),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: EdgeInsets.zero,
          child: _SwitchTile(
            icon: Icons.construction_rounded,
            title: 'Maintenance Mode',
            subtitle: _maintenanceMode
                ? 'Platform is currently in maintenance'
                : 'Platform is live and accessible',
            value: _maintenanceMode,
            onChanged: (v) => setState(() => _maintenanceMode = v),
            iconColor: _maintenanceMode ? AppColors.warning : null,
          ),
        ),
        if (_maintenanceMode) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.danger.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.danger, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Maintenance mode will prevent all users from accessing the platform.',
                    style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: LoadingElevatedButton(
            loading: _saving,
            onPressed: _save,
            child: const Text('Save Application Settings'),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Shared helper widgets
// ────────────────────────────────────────────────────────────────────────────

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? iconColor;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: iconColor ?? AppColors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11.5)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Snackbar helpers
// ────────────────────────────────────────────────────────────────────────────

SnackBar _successSnack(String msg) => SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ],
      ),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

SnackBar _errorSnack(String msg) => SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ],
      ),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
