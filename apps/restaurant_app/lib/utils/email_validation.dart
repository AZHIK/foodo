/// Lightweight email format check shared across auth/onboarding screens.
///
/// Not a full RFC 5322 validator — just enough to catch an obvious typo
/// before it's sent to the backend, which does the real validation.
library;

final _emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool isValidEmailFormat(String email) => _emailFormat.hasMatch(email.trim());
