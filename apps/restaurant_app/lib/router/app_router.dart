import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/session.dart';
import '../providers/session_provider.dart';
import '../screens/auth/complete_profile_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/otp_login_screen.dart';
import '../screens/auth/pin_unlock_screen.dart';
import '../screens/auth/profile_picker_screen.dart';
import '../screens/auth/set_pin_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/customers/customers_screen.dart';
import '../screens/customers/customer_detail_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/order_detail/order_detail_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/insights/ai_insights_screen.dart';
import '../screens/inventory/item_detail_screen.dart';
import '../screens/inventory/reorders_screen.dart';
import '../screens/placeholder/module_placeholder_screen.dart';
import '../screens/pos/pos_screen.dart';
import '../screens/sales/couriers_screen.dart';
import '../screens/sales/sales_screen.dart';
import '../screens/settings/account_settings_screen.dart';
import '../screens/settings/app_preferences_screen.dart';
import '../screens/settings/business_profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/store_management_screen.dart';
import '../screens/settings/store_settings_screen.dart';
import '../screens/staff/roles_screen.dart';
import '../screens/staff/staff_detail_screen.dart';
import '../screens/staff/staff_screen.dart';
import '../screens/finance/other_expenses_screen.dart';
import '../screens/finance/other_incomes_screen.dart';
import '../widgets/responsive_scaffold.dart';

/// Route paths and names in one place, so navigation calls never spell a
/// string literal twice.
abstract final class AppRoute {
  /// The splash, and the app's entry point. It renders a brand moment and then
  /// the guard sends the user wherever [SessionState.entryRoute] says.
  static const splashPath = '/';
  static const splashName = 'splash';

  /// Everything under here is reachable signed out; everything else is not.
  static const authPrefix = '/auth';

  static const profilesPath = '$authPrefix/profiles';
  static const profilesName = 'authProfiles';

  static const loginPath = '$authPrefix/login';
  static const loginName = 'authLogin';

  static const completeProfilePath = '$authPrefix/complete-profile';
  static const completeProfileName = 'authCompleteProfile';

  static const setPinPath = '$authPrefix/set-pin';
  static const setPinName = 'authSetPin';

  /// `?mode=change` re-runs Set PIN from Account Settings rather than as
  /// first-time setup — same screen, different copy and different exit.
  static const setPinModeParam = 'mode';
  static const setPinChangeMode = 'change';

  static String setPin({bool change = false}) =>
      change ? '$setPinPath?$setPinModeParam=$setPinChangeMode' : setPinPath;

  static const unlockPath = '$authPrefix/unlock';
  static const unlockName = 'authUnlock';

  static const onboardingPath = '$authPrefix/onboarding';
  static const onboardingName = 'authOnboarding';

  static const dashboardPath = '/dashboard';
  static const dashboardName = 'dashboard';

  static const posPath = '/pos';
  static const posName = 'pos';

  static const salesPath = '/sales';
  static const salesName = 'sales';

  /// Nested under sales so the shell's Sales tab stays selected on detail.
  static const orderDetailPath = ':orderId';
  static const orderDetailName = 'orderDetail';

  static String orderDetail(String orderId) => '$salesPath/$orderId';

  static const customersPath = '/customers';
  static const customersName = 'customers';

  /// Nested under customers so the shell's Customers tab stays selected.
  static const customerDetailPath = ':customerId';
  static const customerDetailName = 'customerDetail';

  static String customerDetail(String customerId) =>
      '$customersPath/$customerId';

  static const reportsPath = '/reports';
  static const reportsName = 'reports';

  static const insightsPath = '/insights';
  static const insightsName = 'insights';

  static const inventoryPath = '/inventory';
  static const inventoryName = 'inventory';

  /// Nested under inventory so the shell's Inventory tab stays selected.
  static const itemDetailPath = ':itemId';
  static const itemDetailName = 'itemDetail';

  static String itemDetail(String itemId) => '$inventoryPath/$itemId';

  static const staffPath = '/staff';
  static const staffName = 'staff';

  /// Declared before [staffDetailPath] in the route table: `/staff/roles` has
  /// to match the literal segment, not be swallowed as a staff id.
  static const rolesPath = 'roles';
  static const rolesName = 'staffRoles';

  static String roles() => '$staffPath/$rolesPath';

  static const staffDetailPath = ':staffId';
  static const staffDetailName = 'staffDetail';

  static String staffDetail(String staffId) => '$staffPath/$staffId';

  static const financePath = '/finance';
  static const financeName = 'finance';

  static const financeExpensesPath = 'expenses';
  static const financeExpensesName = 'financeExpenses';

  static String financeExpenses() => '$financePath/$financeExpensesPath';

  static const financeIncomesPath = 'incomes';
  static const financeIncomesName = 'financeIncomes';

  static String financeIncomes() => '$financePath/$financeIncomesPath';

  static const settingsPath = '/settings';
  static const settingsName = 'settings';

  /// All nested under settings so the shell's Settings tab stays selected on
  /// every one of them.
  static const businessProfilePath = 'business-profile';
  static const businessProfileName = 'businessProfile';

  static String businessProfile() => '$settingsPath/$businessProfilePath';

  static const storeSettingsPath = 'store-settings';
  static const storeSettingsName = 'storeSettings';

  static String storeSettings() => '$settingsPath/$storeSettingsPath';

  static const storeManagementPath = 'store-management';
  static const storeManagementName = 'storeManagement';

  static String storeManagement() => '$settingsPath/$storeManagementPath';

  static const appPreferencesPath = 'app-preferences';
  static const appPreferencesName = 'appPreferences';

  static String appPreferences() => '$settingsPath/$appPreferencesPath';

  static const accountPath = 'account';
  static const accountName = 'account';

  static String account() => '$settingsPath/$accountPath';

  /// Top-level route outside the shell, reached via the bell icon in the app bar.
  static const notificationsPath = '/notifications';
  static const notificationsName = 'notifications';

  static const reordersPath = '/reorders';
  static const reordersName = 'reorders';

  static const couriersPath = '/couriers';
  static const couriersName = 'couriers';
}

/// The app's router, exposed through Riverpod so it is created and disposed
/// with the rest of the app state rather than as a global.
final goRouterProvider = Provider<GoRouter>((ref) {
  // Owned by the router rather than the library. Module-level keys would be
  // shared by every router ever built, so a second ProviderScope — a test
  // pumping the app twice, or a second window — would collide on them.
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final dashboardNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'dashboard',
  );
  final posNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'pos');
  final salesNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'sales');
  final customersNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'customers',
  );
  final reordersNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'reorders',
  );
  final couriersNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'couriers',
  );
  final reportsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'reports');
  final insightsNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'insights',
  );
  final inventoryNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'inventory',
  );
  final financeNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'finance',
  );
  final staffNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'staff');
  final settingsNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'settings',
  );

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    // The splash, always. What comes after it is the guard's decision, made
    // from session state rather than from wherever the app happened to launch.
    initialLocation: AppRoute.splashPath,
    debugLogDiagnostics: false,
    refreshListenable: ref.watch(sessionRefreshProvider),
    redirect: (context, state) => _guard(ref, state),
    routes: [
      // Outside the shell: an auth screen has no nav rail, no bottom bar and
      // nothing to switch to. They are the app's front door, not a tab in it.
      GoRoute(
        path: AppRoute.splashPath,
        name: AppRoute.splashName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoute.profilesPath,
        name: AppRoute.profilesName,
        builder: (context, state) => const ProfilePickerScreen(),
      ),
      GoRoute(
        path: AppRoute.loginPath,
        name: AppRoute.loginName,
        builder: (context, state) => const OtpLoginScreen(),
      ),
      GoRoute(
        path: AppRoute.completeProfilePath,
        name: AppRoute.completeProfileName,
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: AppRoute.setPinPath,
        name: AppRoute.setPinName,
        builder: (context, state) => SetPinScreen(
          isChangingPin:
              state.uri.queryParameters[AppRoute.setPinModeParam] ==
              AppRoute.setPinChangeMode,
        ),
      ),
      GoRoute(
        path: AppRoute.unlockPath,
        name: AppRoute.unlockName,
        builder: (context, state) => const PinUnlockScreen(),
      ),
      GoRoute(
        path: AppRoute.onboardingPath,
        name: AppRoute.onboardingName,
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Top-level notifications screen (not under shell branches)
      GoRoute(
        path: AppRoute.notificationsPath,
        name: AppRoute.notificationsName,
        builder: (context, state) => const NotificationsScreen(),
      ),
      // An IndexedStack shell: each branch keeps its own Navigator, so the
      // POS cart and the Sales scroll position both survive tab switches.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ResponsiveScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: dashboardNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoute.dashboardPath,
                name: AppRoute.dashboardName,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: posNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoute.posPath,
                name: AppRoute.posName,
                builder: (context, state) => const PosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: salesNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoute.salesPath,
                name: AppRoute.salesName,
                builder: (context, state) => const SalesScreen(),
                routes: [
                  GoRoute(
                    path: AppRoute.orderDetailPath,
                    name: AppRoute.orderDetailName,
                    builder: (context, state) => OrderDetailScreen(
                      orderId: state.pathParameters['orderId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: customersNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoute.customersPath,
                name: AppRoute.customersName,
                builder: (context, state) => const CustomersScreen(),
                routes: [
                  GoRoute(
                    path: AppRoute.customerDetailPath,
                    name: AppRoute.customerDetailName,
                    builder: (context, state) => CustomerDetailScreen(
                      customerId: state.pathParameters['customerId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: reordersNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoute.reordersPath,
                name: AppRoute.reordersName,
                builder: (context, state) => const ReordersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: couriersNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoute.couriersPath,
                name: AppRoute.couriersName,
                builder: (context, state) => const CouriersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: financeNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoute.financePath,
                name: AppRoute.financeName,
                builder: (context, state) => const OtherExpensesScreen(),
                routes: [
                  GoRoute(
                    path: AppRoute.financeExpensesPath,
                    name: AppRoute.financeExpensesName,
                    builder: (context, state) => const OtherExpensesScreen(),
                  ),
                  GoRoute(
                    path: AppRoute.financeIncomesPath,
                    name: AppRoute.financeIncomesName,
                    builder: (context, state) => const OtherIncomesScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Advertised by the rail but not part of this UI build. Real
          // branches, so each keeps its own Navigator and swapping in a real
          // screen is a one-line change here.
          StatefulShellBranch(
            navigatorKey: reportsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoute.reportsPath,
                name: AppRoute.reportsName,
                builder: (context, state) => const ModulePlaceholderScreen(
                  title: 'Reports',
                  icon: Icons.insights_rounded,
                  blurb:
                      'Daily takings, item mix and staff performance land '
                      'here once the reporting service is wired up.',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: insightsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoute.insightsPath,
                name: AppRoute.insightsName,
                builder: (context, state) => const AiInsightsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: inventoryNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoute.inventoryPath,
                name: AppRoute.inventoryName,
                builder: (context, state) => const InventoryScreen(),
                routes: [
                  GoRoute(
                    path: AppRoute.itemDetailPath,
                    name: AppRoute.itemDetailName,
                    builder: (context, state) => ItemDetailScreen(
                      itemId: state.pathParameters['itemId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: staffNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoute.staffPath,
                name: AppRoute.staffName,
                builder: (context, state) => const StaffScreen(),
                routes: [
                  // Order matters: the literal `roles` segment is declared
                  // first so it is not captured by the `:staffId` pattern
                  // below it.
                  GoRoute(
                    path: AppRoute.rolesPath,
                    name: AppRoute.rolesName,
                    builder: (context, state) => const RolesScreen(),
                  ),
                  GoRoute(
                    path: AppRoute.staffDetailPath,
                    name: AppRoute.staffDetailName,
                    builder: (context, state) => StaffDetailScreen(
                      staffId: state.pathParameters['staffId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: settingsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoute.settingsPath,
                name: AppRoute.settingsName,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: AppRoute.businessProfilePath,
                    name: AppRoute.businessProfileName,
                    builder: (context, state) => const BusinessProfileScreen(),
                  ),
                  GoRoute(
                    path: AppRoute.storeSettingsPath,
                    name: AppRoute.storeSettingsName,
                    builder: (context, state) => const StoreSettingsScreen(),
                  ),
                  GoRoute(
                    path: AppRoute.storeManagementPath,
                    name: AppRoute.storeManagementName,
                    builder: (context, state) => const StoreManagementScreen(),
                  ),
                  GoRoute(
                    path: AppRoute.appPreferencesPath,
                    name: AppRoute.appPreferencesName,
                    builder: (context, state) => const AppPreferencesScreen(),
                  ),
                  GoRoute(
                    path: AppRoute.accountPath,
                    name: AppRoute.accountName,
                    builder: (context, state) => const AccountSettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => _RouteErrorScreen(error: state.error),
  );

  ref.onDispose(router.dispose);
  return router;
});

/// The app's only route guard.
///
/// Returns null to allow a navigation and a path to divert it. Two rules, in
/// this order:
///
///  1. The splash holds everything until it has had its moment, then hands off
///     to wherever [SessionState.entryRoute] points.
///  2. Anything outside `/auth` needs a signed-in, unlocked, onboarded session
///     and is bounced back to the right step of the flow when it does not have
///     one.
///
/// Auth routes themselves are deliberately *not* guarded in reverse: reaching
/// `/auth/unlock` while already unlocked is someone locking the till on
/// purpose at the end of a shift, and bouncing them to the Dashboard would
/// make that impossible.
String? _guard(Ref ref, GoRouterState state) {
  final session = ref.read(sessionProvider);
  final location = state.matchedLocation;

  if (location == AppRoute.splashPath) {
    return session.bootstrapped ? session.entryRoute : null;
  }

  if (location.startsWith(AppRoute.authPrefix)) return null;

  // Everything below here is inside the shell and needs a real session.
  if (!session.isLoggedIn) {
    return session.hasSavedProfiles
        ? AppRoute.profilesPath
        : AppRoute.loginPath;
  }
  if (!session.hasPin) return AppRoute.setPinPath;
  if (!session.isUnlocked) return AppRoute.unlockPath;
  if (!session.hasCompletedOnboarding) return AppRoute.onboardingPath;

  return null;
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.explore_off_rounded,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text('Page not found', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    error?.toString() ?? 'That route does not exist.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.goNamed(AppRoute.posName),
                    icon: const Icon(Icons.point_of_sale_rounded),
                    label: const Text('Back to POS'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
