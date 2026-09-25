import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos/auth/auth_dtos.dart';
import 'package:restaurant_pos/models/store_settings.dart';
import 'package:restaurant_pos/providers/store_settings_hydration.dart';

StoreSettingReadDto _dto({
  String currency = 'TZS',
  bool inclusive = false,
}) {
  final now = DateTime(2026, 8, 6, 14, 15);
  return StoreSettingReadDto(
    id: 'setting-1',
    storeId: 'store-2',
    active: true,
    preferredCurrency: currency,
    offerRetail: true,
    offerWholesale: false,
    displayPricesInclusiveOfTax: inclusive,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('hydrateStoreSettings', () {
    test('adopts the new store currency and tax display', () {
      const current = StoreSettings();

      final hydrated = hydrateStoreSettings(
        current: current,
        dto: _dto(currency: 'USD', inclusive: true),
      );

      expect(hydrated.currency, Currency.usd);
      expect(hydrated.taxInclusive, isTrue);
    });

    test('keeps local values that have no backend home', () {
      const current = StoreSettings(
        taxRate: 0.18,
        receiptPrefix: 'K-',
        autoPrintReceipt: false,
        checkoutPrintMode: CheckoutPrintMode.coupon,
      );

      final hydrated = hydrateStoreSettings(
        current: current,
        dto: _dto(currency: 'TZS', inclusive: false),
      );

      expect(hydrated.taxRate, 0.18);
      expect(hydrated.receiptPrefix, 'K-');
      expect(hydrated.autoPrintReceipt, isFalse);
      expect(hydrated.checkoutPrintMode, CheckoutPrintMode.coupon);
    });

    test('unknown currency codes keep the current currency', () {
      const current = StoreSettings(currency: Currency.eur);

      final hydrated = hydrateStoreSettings(
        current: current,
        dto: _dto(currency: 'XXX'),
      );

      expect(hydrated.currency, Currency.eur);
    });
  });
}
