class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? required(String? v, [String field = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Use at least 8 characters';
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) {
    return (v) {
      if (v == null || v.isEmpty) return 'Confirm your password';
      if (v != original()) return 'Passwords do not match';
      return null;
    };
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    final digits = v.replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^\+?\d{10,13}$').hasMatch(digits)) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}
