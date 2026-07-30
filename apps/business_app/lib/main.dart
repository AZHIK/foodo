import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../app/theme/app_theme.dart';

/// App entrypoint.
///
/// Wraps the entire widget tree in a [ProviderScope] for Riverpod
/// dependency injection, then delegates to [MaterialApp.router] with
/// the app's theme and GoRouter instance.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: FoodLinkBusinessApp()));
}

class FoodLinkBusinessApp extends StatelessWidget {
  const FoodLinkBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FoodLink Business',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
