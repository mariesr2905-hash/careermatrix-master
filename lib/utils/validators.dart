/// Shared form-field validators for auth screens. Kept dependency-free
/// (plain functions returning an error string or null) to work directly
/// with Flutter's built-in `Form` / `TextFormField.validator`.
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your full name';
    if (v.length < 2) return 'Name looks too short';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email address';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter your password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? organization(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'This field is required';
    return null;
  }

  static String? required(String? value, {String message = 'This field is required'}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return message;
    return null;
  }
}
