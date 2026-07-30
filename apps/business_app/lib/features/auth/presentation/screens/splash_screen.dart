import 'package:flutter/material.dart';

import 'package:foodlink_business/app/theme/app_theme.dart';
import 'package:foodlink_business/core/constants/app_colors.dart';
import 'package:foodlink_business/core/constants/app_strings.dart';

/// Placeholder splash screen.
///
/// Displays the app logo (text-based for now) and a loading indicator.
/// Once auth logic is wired, this screen will decide whether to route
/// to [ProfilePickerScreen], [OtpLoginScreen], or [DashboardScreen]
/// based on stored session state.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.seedTerracotta,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.appTagline,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
