import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_dtos.dart';
import '../models/store_settings.dart';

/// Adopts a newly selected store's backend settings onto the terminal.
///
/// Only fields with a backend home move: the preferred currency and the
/// tax-inclusive display flag. Everything else (tax *rate*, receipt prefix,
/// auto-print, print mode, hours) has no `StoreSetting` column yet, so the
/// terminal keeps its local values for those — see `StoreSettingReadDto`.
/// Pure function so the mapping is unit-testable without providers.
StoreSettings hydrateStoreSettings({
  required StoreSettings current,
  required StoreSettingReadDto dto,
}) {
  final code = dto.preferredCurrency.trim().toUpperCase();
  final currency = Currency.values.firstWhere(
    (c) => c.code.toUpperCase() == code,
    orElse: () => current.currency,
  );
  return current.copyWith(
    currency: currency,
    taxInclusive: dto.displayPricesInclusiveOfTax,
  );
}

/// True once the terminal's store token has been refreshed after an offline
/// switch — until then the till runs on cached data under the new store.
///
/// Set by the store-switch flow; cleared by a successful online token
/// exchange (switch or refresh-while-pending). Drives the pending-token
/// banner.
final storeTokenRefreshPendingProvider = StateProvider<bool>((ref) => false);
