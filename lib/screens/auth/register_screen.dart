import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/common_widgets.dart';
import '../dashboard/home_shell.dart';
import 'role_select_sheet.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _orgController = TextEditingController();
  final _passwordController = TextEditingController();

  UserRole _role = UserRole.student;
  int _step = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _orgController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isLoading = true);
    try {
      final isPending = await AuthService.instance.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _role,
      );

      if (isPending) {
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Registration Submitted', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
              'Your account has been submitted successfully.\n\n'
              'Your account is waiting for administrator approval.\n\n'
              'You will be able to access Career Matrix after your account is approved.',
              style: TextStyle(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pop(); // Back to login screen
        return;
      }

      final session = await AuthService.instance.restoreSession();
      if (session == null) throw Exception('Session could not be restored');

      AppState.instance.applySession(role: session.role, name: session.name, email: session.email);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToDetailsStep() {
    // Step 0 has no text fields to validate (role picker only) — just advance.
    setState(() => _step = 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(16)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset('assets/career_matrix_logo.jpg', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 18),
              Text('Create your account', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Join thousands building smarter careers with AI guidance.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
              const SizedBox(height: 24),
              Row(
                children: List.generate(2, (i) {
                  final active = i <= _step;
                  return Expanded(
                    child: Container(
                      height: 5,
                      margin: EdgeInsets.only(right: i == 0 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 26),
              if (_step == 0)
                _buildRoleStep()
              else
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: _buildDetailsStep(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select your role', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 14),
        ...UserRole.values.map((role) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _role = role),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: role == _role ? AppColors.primarySoft : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                    border: role == _role ? Border.all(color: AppColors.primary, width: 1.4) : null,
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
                      if (role == _role) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            )),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _goToDetailsStep, child: const Text('Continue')),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 16),
        const Text('Full name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          enabled: !_isLoading,
          textInputAction: TextInputAction.next,
          validator: Validators.name,
          decoration: const InputDecoration(hintText: 'Enter your full name'),
        ),
        const SizedBox(height: 16),
        const Text('Email address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: Validators.email,
          decoration: const InputDecoration(hintText: 'you@example.com'),
        ),
        const SizedBox(height: 16),
        Text(_role == UserRole.company ? 'Company name' : 'Institution / Organization',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _orgController,
          enabled: !_isLoading,
          textInputAction: TextInputAction.next,
          validator: Validators.organization,
          decoration: InputDecoration(hintText: _role == UserRole.company ? 'e.g. Acme Corp' : 'e.g. NIT Trichy'),
        ),
        const SizedBox(height: 16),
        const Text('Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          enabled: !_isLoading,
          obscureText: true,
          textInputAction: TextInputAction.done,
          validator: Validators.password,
          onFieldSubmitted: (_) => _createAccount(),
          decoration: const InputDecoration(hintText: '••••••••'),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => setState(() => _step = 0),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: LoadingElevatedButton(loading: _isLoading, onPressed: _createAccount, child: const Text('Create Account')),
            ),
          ],
        ),
      ],
    );
  }
}
