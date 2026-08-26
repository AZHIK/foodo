import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/business_profile.dart';
import '../models/order.dart';
import '../models/store_settings.dart';

/// App-wide theme mode.
///
/// In-memory for now; persisting it later means overriding this provider with
/// one backed by shared_preferences and nothing else has to change.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void set(ThemeMode mode) => state = mode;

  /// Cycles system → light → dark, for the app bar toggle.
  void cycle() {
    state = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

// ---------------------------------------------------------------------------
// Business identity
// ---------------------------------------------------------------------------

/// The venue's own details. Mutable because the Business Profile screen edits
/// them; everything that displays store identity reads through this.
class BusinessProfileNotifier extends Notifier<BusinessProfile> {
  @override
  BusinessProfile build() => BusinessProfile.seed;

  void save(BusinessProfile profile) => state = profile;

  void setLogo(String name, Uint8List bytes) =>
      state = state.copyWith(logoName: name, logoBytes: bytes);

  void clearLogo() => state = state.copyWith(clearLogo: true);

  void setBrandColor(Color color) => state = state.copyWith(brandColor: color);
}

final businessProfileProvider =
    NotifierProvider<BusinessProfileNotifier, BusinessProfile>(
      BusinessProfileNotifier.new,
    );

/// Store identity shown in the nav header.
///
/// Still its own provider so the header rebuilds only when the *name* changes,
/// not on every edit to an address or a receipt footer.
final storeNameProvider = Provider<String>(
  (ref) => ref.watch(businessProfileProvider.select((p) => p.name)),
);

/// The thank-you line printed at the bottom of every receipt.
///
/// Exposed separately so the receipt renderer depends on the one string it
/// prints rather than on the whole profile — and so no receipt ever ships with
/// a hardcoded message again.
final receiptFooterProvider = Provider<String>(
  (ref) => ref.watch(businessProfileProvider.select((p) => p.receiptFooter)),
);

/// The business's accent colour, for receipts and customer-facing surfaces.
final brandColorProvider = Provider<Color>(
  (ref) => ref.watch(businessProfileProvider.select((p) => p.brandColor)),
);

// ---------------------------------------------------------------------------
// Store operation
// ---------------------------------------------------------------------------

/// How this store trades: tax, currency, receipt numbering, opening hours.
///
/// Every field here has a consumer somewhere else in the app, which is the
/// test a setting has to pass before it earns a place on the screen.
class StoreSettingsNotifier extends Notifier<StoreSettings> {
  @override
  StoreSettings build() => const StoreSettings();

  void save(StoreSettings settings) => state = settings;

  void setDay(int index, DayHours day) => state = state.withDay(index, day);

  void setCurrency(Currency currency) =>
      state = state.copyWith(currency: currency);
}

final storeSettingsProvider =
    NotifierProvider<StoreSettingsNotifier, StoreSettings>(
      StoreSettingsNotifier.new,
    );

/// The tax rate new tickets are opened at.
///
/// Selected out of [storeSettingsProvider] rather than read whole, so the cart
/// is not rebuilt when someone edits the receipt prefix.
final taxRateProvider = Provider<double>(
  (ref) => ref.watch(storeSettingsProvider.select((s) => s.taxRate)),
);

/// Whether menu prices already carry their tax.
final taxInclusiveProvider = Provider<bool>(
  (ref) => ref.watch(storeSettingsProvider.select((s) => s.taxInclusive)),
);

final serviceChargeRateProvider = Provider<double>(
  (ref) => ref.watch(storeSettingsProvider.select((s) => s.serviceChargeRate)),
);

/// The currency every amount in the app is formatted in.
///
/// Read once at the root of the widget tree, where it configures [Fmt] before
/// anything below it formats a number.
final currencyProvider = Provider<Currency>(
  (ref) => ref.watch(storeSettingsProvider.select((s) => s.currency)),
);

/// What a fresh ticket's order type starts as.
final defaultOrderTypeProvider = Provider<OrderType>(
  (ref) => ref.watch(storeSettingsProvider.select((s) => s.defaultOrderType)),
);

/// Prefix on printed receipt numbers, e.g. "INV-".
final receiptPrefixProvider = Provider<String>(
  (ref) => ref.watch(storeSettingsProvider.select((s) => s.receiptPrefix)),
);

final autoPrintReceiptProvider = Provider<bool>(
  (ref) => ref.watch(storeSettingsProvider.select((s) => s.autoPrintReceipt)),
);

/// Note and coin values offered as one-tap top-ups when taking cash.
///
/// Store configuration rather than constants in the widget, and *amounts*
/// rather than pre-baked labels: a venue on a currency with no 5 note, or one
/// whose smallest bill is 10.000, changes this list and every quick-amount
/// control follows. The labels are formatted through [Fmt.money], so the
/// currency itself is still decided in exactly one place.
final cashQuickAmountsProvider = Provider<List<double>>(
  (ref) => const [5, 10, 20, 50],
);

/// Signed-in staff member, used as the default server on new orders.
final currentStaffProvider = Provider<String>((ref) => 'Ava');
