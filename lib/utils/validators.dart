class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != original) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? requiredField(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a phone number';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? aadharNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter Aadhar number';
    }
    final digits = value.replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d{12}$').hasMatch(digits)) {
      return 'Enter a valid 12-digit Aadhar number';
    }
    return null;
  }
}
