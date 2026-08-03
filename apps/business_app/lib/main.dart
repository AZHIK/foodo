import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';

/// App entrypoint.
///
/// Wraps the entire widget tree in a [ProviderScope] for Riverpod
/// dependency injection, then delegates to [MaterialApp.router] with
/// the app's theme and GoRouter instance.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loads .env from the Flutter asset bundle. The API base URLs are read
  // lazily when the Dio client is first constructed, so this must happen
  // before any request is made.
  await dotenv.load();
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
