String? validateRequired(String? value, String message) {
  if (value == null || value.trim().isEmpty) {
    return message;
  }
  return null;
}

String? validateEmail(String? value) {
  final requiredError = validateRequired(value, 'Informe o e-mail.');
  if (requiredError != null) {
    return requiredError;
  }

  final email = value!.trim();
  final parts = email.split('@');
  if (parts.length != 2 ||
      parts.first.isEmpty ||
      !parts.last.contains('.') ||
      parts.last.startsWith('.') ||
      parts.last.endsWith('.')) {
    return 'Informe um e-mail válido.';
  }
  return null;
}
