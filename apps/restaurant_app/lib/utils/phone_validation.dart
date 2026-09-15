/// Shared Tanzanian mobile phone validation, used by every screen that
/// collects a phone number during auth/onboarding — keeping one rule here
/// means the OTP login screen and the business wizard can never disagree
/// about what counts as a valid number.
library;

import '../constants/app_limits.dart';
import '../constants/app_strings.dart';

/// True when [digits] (national number, no +255 prefix) is a valid
/// Tanzanian mobile number: 9 digits, starting with 6 or 7.
bool isValidTanzanianPhone(String digits) {
  if (digits.length != AppLimits.tzPhoneDigits) return false;
  return digits.startsWith('6') || digits.startsWith('7');
}

const tanzanianPhoneHint = AppStrings.tanzanianPhoneError;
