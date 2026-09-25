import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/identity_service_api.dart';
import '../../constants/app_durations.dart';
import '../../constants/app_strings.dart';
import '../../database/app_database.dart';
import '../../models/permission.dart';
import '../../models/store_location.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/database_providers.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/order_session_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/other_expenses_provider.dart';
import '../../providers/other_incomes_provider.dart';
import '../../providers/permissions_provider.dart';
import '../../providers/reorder_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/store_api_provider_real.dart';
import '../../providers/store_settings_hydration.dart';
import '../../providers/sync_status_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/dialog_helper.dart';

/// Whether the terminal may be moved to [target]: the switch permission plus
/// business-staff status. The backend re-checks both on the switch endpoint;
/// this only decides whether the Switch action renders.
bool canSwitchStore(WidgetRef ref, StoreLocation target) {
  final currentId = ref.watch(currentStoreIdProvider);
  if (currentId != null && currentId == target.id) return false;
  if (!ref.watch(hasPermissionProvider(AppPermissions.storesSwitch))) {
    return false;
  }
  return ref.watch(currentClaimsProvider)?.isBusinessStaff ?? false;
}

/// WhatsApp-style store switch: pre-flight, guarded execution, full reload.
///
/// 1. Open ticket → must be discarded (a ticket belongs to one store).
/// 2. Unsynced sales → sync is attempted; what won't push triggers the
///    switch-anyway-or-stay choice.
/// 3. Confirm sheet states what happens; execution runs under a loading
///    overlay, then the whole app is the new store: tokens (when online),
///    device pointer, hydrated settings, cleared ticket, resynced caches.
Future<void> runStoreSwitchFlow(
  BuildContext context,
  WidgetRef ref,
  StoreLocation target,
) async {
  final currentId = ref.read(currentStoreIdProvider);
  if (currentId != null && currentId == target.id) return;

  // Open ticket belongs to the old store and can never move with it.
  var hadCart = ref.read(cartProvider).isNotEmpty;
  if (hadCart) {
    final discard = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.switchDiscardTitle),
        content: Text(AppStrings.switchDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppStrings.stayHere),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppStrings.discardAndSwitch),
          ),
        ],
      ),
    );
    if (discard != true || !context.mounted) return;
  }

  // Push the old store's outbox first; what won't push is the user's call.
  var pending = await _pendingSalesCount(ref, currentId);
  if (pending > 0) {
    try {
      await ref.read(syncServiceProvider).syncNow();
    } catch (_) {
      // Offline or backend error — decided below, never thrown here.
    }
    pending = await _pendingSalesCount(ref, currentId);
  }
  if (!context.mounted) return;

  // Pre-flight sheet: what the switch will do, stated before it happens.
  final lines = <String>[
    if (hadCart) AppStrings.switchPreflightCart,
    if (pending > 0)
      AppStrings.switchPreflightPending(pending)
    else
      AppStrings.switchPreflightClean,
  ];
  final confirmed = await showAppDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(AppStrings.switchToStoreTitle(target.name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines) ...[
            Text(line),
            const SizedBox(height: 8),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(pending > 0 ? AppStrings.stayAndSync : AppStrings.stayHere),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            pending > 0 ? AppStrings.switchAnyway : AppStrings.switchStoreAction,
          ),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  await _executeSwitch(context, ref, target, currentId, pending);
}

/// Runs the switch under a blocking loading overlay: token exchange (when
/// online), device re-point, settings hydration, ticket reset, audit,
/// cache resync, then landing on the dashboard as the new store.
Future<void> _executeSwitch(
  BuildContext context,
  WidgetRef ref,
  StoreLocation target,
  String? fromStoreId,
  int pendingLeft,
) async {
  if (!context.mounted) return;
  // Captured before any async gap: provider invalidation below rebuilds the
  // settings page, and lookups on an unmounted context throw — which used to
  // strand this overlay open with no way out. These three are long-lived
  // (root navigator, root messenger, app router), so they stay valid.
  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);

  var overlayOpen = false;
  Future<void> dismissOverlay() async {
    if (!overlayOpen) return;
    overlayOpen = false;
    try {
      navigator.pop();
    } catch (_) {
      // Already gone — nothing to dismiss.
    }
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(AppStrings.switchingTo(target.name))),
          ],
        ),
      ),
    ),
  );
  overlayOpen = true;

  Future<void> fail(String detail) async {
    await dismissOverlay();
    messenger.showSnackBar(
      SnackBar(content: Text(AppStrings.switchFailed(detail))),
    );
  }

  try {
    await _doSwitchWork(
      ref,
      target,
      fromStoreId,
      pendingLeft,
    ).timeout(AppDurations.storeSwitchTimeout);
  } on AuthException catch (e) {
    await fail(e.message);
    return;
  } on TimeoutException {
    // No single step may hang: every await inside is bounded, so this means
    // something stopped resolving entirely — say so instead of spinning.
    await fail(AppStrings.switchTimedOut);
    return;
  } catch (e) {
    await fail(e.toString());
    return;
  }

  await dismissOverlay();
  messenger.showSnackBar(
    SnackBar(content: Text(AppStrings.switchedTo(target.name))),
  );
  router.goNamed(AppRoute.dashboardName);
}

/// The switch itself: token exchange, hydration, ticket reset, audit and
/// cache reload. Throws on failure; the caller owns the overlay and the
/// error surface.
Future<void> _doSwitchWork(
  WidgetRef ref,
  StoreLocation target,
  String? fromStoreId,
  int pendingLeft,
) async {
  final tokenOk = await ref
      .read(authProvider.notifier)
      .switchStore(storeId: target.id);

  await _hydrateSettings(ref, target);

  // Ticket state belonged to the old store in every field.
  ref.read(cartProvider.notifier).clear();
  ref.read(selectedCustomerIdProvider.notifier).state = null;
  ref.invalidate(orderTypeProvider);
  ref.invalidate(tableNumberProvider);

  await _auditSwitch(ref, target, fromStoreId, tokenOk, pendingLeft);

  ref.read(storeTokenRefreshPendingProvider.notifier).state = !tokenOk;

  // Store-scoped caches reload for the new store; business-scoped ones
  // (customers, staff, roles) are untouched.
  ref
    ..invalidate(ordersProvider)
    ..invalidate(inventoryItemsProvider)
    ..invalidate(otherExpensesProvider)
    ..invalidate(otherIncomesProvider)
    ..invalidate(reordersProvider);
}

/// Adopts the new store's backend settings (currency, tax display). Skipped
/// silently offline — the terminal keeps its local settings until the next
/// online switch or settings visit pulls them.
Future<void> _hydrateSettings(WidgetRef ref, StoreLocation target) async {
  try {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) return;
    final dto = await ref
        .read(storeApiServiceProvider)
        .getStoreSettings(businessId: businessId, storeId: target.id);
    final current = ref.read(storeSettingsProvider);
    ref
        .read(storeSettingsProvider.notifier)
        .save(hydrateStoreSettings(current: current, dto: dto));
    // The app root watches the currency and re-points Fmt before anything
    // below it formats a number, so no manual formatter reset is needed.
  } catch (_) {
    // Offline: local settings stand until connectivity returns.
  }
}

/// Append-only trail of who moved the terminal where, synced last with
/// everything else. Best-effort: a failed write must never fail a switch.
Future<void> _auditSwitch(
  WidgetRef ref,
  StoreLocation target,
  String? fromStoreId,
  bool tokenRefreshed,
  int pendingLeft,
) async {
  try {
    final db = ref.read(appDatabaseProvider);
    final userId = ref.read(authProvider).userId ?? 'unknown';
    final now = DateTime.now().toUtc();
    await db
        .into(db.localAuditLog)
        .insert(
          LocalAuditLogCompanion.insert(
            actorUserId: userId,
            action: 'store.switched',
            resourceType: const Value('store'),
            resourceId: Value(target.id),
            detailsJson: Value(
              jsonEncode({
                'fromStoreId': fromStoreId,
                'tokenRefreshed': tokenRefreshed,
                'pendingLeft': pendingLeft,
              }),
            ),
            occurredAt: now,
            createdAt: now,
          ),
        );
  } catch (_) {
    // Audit is useful-not-critical; the switch already happened.
  }
}

/// Unsynced sales still queued for [storeId] — the money that must not
/// silently change stores.
Future<int> _pendingSalesCount(WidgetRef ref, String? storeId) async {
  if (storeId == null) return 0;
  try {
    final db = ref.read(appDatabaseProvider);
    final rows = await (db.select(
      db.pendingSales,
    )..where((row) => row.storeId.equals(storeId))).get();
    return rows.length;
  } catch (_) {
    return 0;
  }
}

/// Retries the store-token exchange after an offline switch. Clears the
/// pending banner on success.
Future<void> retryStoreTokenRefresh(BuildContext context, WidgetRef ref) async {
  final storeId = ref.read(currentStoreIdProvider);
  if (storeId == null) return;
  try {
    final ok = await ref
        .read(authProvider.notifier)
        .switchStore(storeId: storeId);
    if (ok) {
      ref.read(storeTokenRefreshPendingProvider.notifier).state = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.storeTokenRefreshed)),
        );
      }
    }
  } on AuthException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.switchFailed(e.message))),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.switchFailed(e.toString()))),
      );
    }
  }
}

/// Banner for the offline-switch state: the till runs on cached data under
/// the new store until the token exchange succeeds.
class StoreTokenBanner extends ConsumerWidget {
  const StoreTokenBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(storeTokenRefreshPendingProvider)) {
      return const SizedBox.shrink();
    }
    final colors = context.colors;
    return Material(
      color: colors.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 18,
              color: colors.onTertiaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppStrings.tokenPendingBanner,
                style: context.text.bodySmall?.copyWith(
                  color: colors.onTertiaryContainer,
                ),
              ),
            ),
            TextButton(
              onPressed: () => retryStoreTokenRefresh(context, ref),
              child: Text(AppStrings.tokenRetryAction),
            ),
          ],
        ),
      ),
    );
  }
}
