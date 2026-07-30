import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';

/// Placeholder profile-picker screen (shift-login).
///
/// When a device is shared by multiple staff members this screen shows
/// the available profiles (businesses / roles) and lets the user pick
/// one.  Full multi-profile UI will be built in a later stage.
class ProfilePickerScreen extends StatelessWidget {
  const ProfilePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profilePickerTitle)),
      body: Center(
        child: Text(
          AppStrings.profilePickerSubtitle,
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
