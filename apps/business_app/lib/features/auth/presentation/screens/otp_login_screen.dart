import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';

/// Placeholder OTP login screen.
///
/// Receives a phone number (passed from the profile-picker or a direct
/// login flow), sends an OTP via Identity Service, and verifies the
/// code.  Full implementation — including OTP input widget, countdown
/// timer, and resend logic — will be added in the auth integration stage.
class OtpLoginScreen extends StatelessWidget {
  const OtpLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.loginTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppStrings.loginOtpHint,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
