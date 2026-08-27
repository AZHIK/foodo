/// Shared Tanzanian mobile phone validation, used by every screen that
/// collects a phone number during auth/onboarding — keeping one rule here
/// means the OTP login screen and the business wizard can never disagree
/// about what counts as a valid number.
library;

/// True when [digits] (national number, no +255 prefix) is a valid
/// Tanzanian mobile number: 9 digits, starting with 6 or 7.
bool isValidTanzanianPhone(String digits) {
  if (digits.length != 9) return false;
  return digits.startsWith('6') || digits.startsWith('7');
}

const tanzanianPhoneHint = 'Enter a valid Tanzanian phone number (6 or 7XXXXXXXX)';
