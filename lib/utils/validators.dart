/// Pure functions so they are trivial to unit test.
class Validators {
  static final _idPattern = RegExp(r'^\d{6,10}$');
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? name(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Name is required';
    if (v.length < 2) return 'Enter your full name';
    return null;
  }

  static String? studentId(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Student ID is required';
    if (!_idPattern.hasMatch(v)) return 'Student ID must be 6–10 digits';
    return null;
  }

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// At least 8 characters, with a letter and a number.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Include both letters and numbers';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }
}
