import 'package:flutter/material.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  final _bioCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _graduationYearCtrl = TextEditingController();
  final _currentPositionCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await BackendRepository.instance.getMyProfileRaw();
      if (profile != null) {
        _bioCtrl.text = profile['bio'] as String? ?? '';
        _phoneCtrl.text = profile['phone'] as String? ?? '';
        _addressCtrl.text = profile['address'] as String? ?? '';
        _departmentCtrl.text = profile['department'] as String? ?? '';
        _graduationYearCtrl.text = profile['graduationYear']?.toString() ?? '';
        _currentPositionCtrl.text = profile['currentPosition'] as String? ?? '';
        _companyCtrl.text = profile['company'] as String? ?? '';
        _linkedinCtrl.text = profile['linkedin'] as String? ?? '';
        _githubCtrl.text = profile['github'] as String? ?? '';
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await BackendRepository.instance.saveProfile({
        'bio': _bioCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'department': _departmentCtrl.text.trim(),
        if (_graduationYearCtrl.text.trim().isNotEmpty)
          'graduationYear': int.tryParse(_graduationYearCtrl.text.trim()),
        'currentPosition': _currentPositionCtrl.text.trim(),
        'company': _companyCtrl.text.trim(),
        'linkedin': _linkedinCtrl.text.trim(),
        'github': _githubCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _departmentCtrl.dispose();
    _graduationYearCtrl.dispose();
    _currentPositionCtrl.dispose();
    _companyCtrl.dispose();
    _linkedinCtrl.dispose();
    _githubCtrl.dispose();
    super.dispose();
  }

  Widget _field(TextEditingController ctrl, String label, {
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
        decoration: InputDecoration(labelText: label),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Edit Profile',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: [
                      _field(_bioCtrl, 'Bio', maxLines: 3, maxLength: 500),
                      _field(_phoneCtrl, 'Phone', keyboardType: TextInputType.phone, validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final ok = RegExp(r'^[0-9+\-\s()]{7,20}$').hasMatch(v.trim());
                        return ok ? null : 'Invalid phone number';
                      }),
                      _field(_addressCtrl, 'Address', maxLines: 2),
                      _field(_departmentCtrl, 'Department'),
                      _field(_graduationYearCtrl, 'Graduation Year', keyboardType: TextInputType.number, validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final year = int.tryParse(v.trim());
                        if (year == null || year < 1950 || year > 2100) return 'Invalid year';
                        return null;
                      }),
                      _field(_currentPositionCtrl, 'Current Position'),
                      _field(_companyCtrl, 'Company'),
                      _field(_linkedinCtrl, 'LinkedIn URL', keyboardType: TextInputType.url, validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return Uri.tryParse(v.trim())?.isAbsolute == true ? null : 'Enter a valid URL';
                      }),
                      _field(_githubCtrl, 'GitHub URL', keyboardType: TextInputType.url, validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return Uri.tryParse(v.trim())?.isAbsolute == true ? null : 'Enter a valid URL';
                      }),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save Changes'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
