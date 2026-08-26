import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/app_database.dart';
import 'database/database_connection.dart';
import 'database/encryption_key_service.dart';
import 'providers/database_providers.dart';
import 'providers/settings_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'utils/formatters.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Resolve or generate the encryption key.
  final keyService = EncryptionKeyService();
  final encryptionKey = await keyService.getOrCreateKey();

  // 2. Create and open the database.
  final database = AppDatabase(driftDatabaseConnection(encryptionKey));

  // 3. Run the app with the database injected into providers.
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const RestaurantPosApp(),
    ),
  );
}

class RestaurantPosApp extends ConsumerWidget {
  const RestaurantPosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Money is formatted through static helpers, so the store's currency is
    // applied here — above everything that prints a price — rather than passed
    // down through several hundred call sites. Watching it also means changing
    // the currency in Store Settings rebuilds the tree that reads it, which is
    // what makes every amount on screen change at once.
    Fmt.use(ref.watch(currencyProvider));

    return MaterialApp.router(
      title: '',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
    );
  }
}
