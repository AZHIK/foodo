import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/main.dart';
import 'package:restaurant_pos/models/ai_insight.dart';
import 'package:restaurant_pos/models/inventory_item.dart';
import 'package:restaurant_pos/models/order.dart';
import 'package:restaurant_pos/models/store_location.dart';
import 'package:restaurant_pos/models/store_settings.dart';
import 'package:restaurant_pos/providers/ai_insights_provider.dart';
import 'package:restaurant_pos/providers/cart_provider.dart';
import 'package:restaurant_pos/providers/inventory_provider.dart';
import 'package:restaurant_pos/providers/order_session_provider.dart';
import 'package:restaurant_pos/providers/preferences_provider.dart';
import 'package:restaurant_pos/providers/settings_provider.dart';
import 'package:restaurant_pos/providers/store_locations_provider.dart';
import 'package:restaurant_pos/router/app_router.dart';
import 'package:restaurant_pos/screens/settings/app_preferences_screen.dart';
import 'package:restaurant_pos/screens/settings/business_profile_screen.dart';
import 'package:restaurant_pos/screens/settings/store_settings_screen.dart';
import 'package:restaurant_pos/theme/brand_palette.dart';
import 'package:restaurant_pos/utils/formatters.dart';

const _widths = <double>[360, 400, 768, 1024, 1440, 1920];

Future<ProviderContainer> pumpAt(
  WidgetTester tester,
  Size size,
  String route,
) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.reset);

  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const RestaurantPosApp(),
    ),
  );
  await tester.pumpAndSettle();

  container.read(goRouterProvider).go(route);
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('Settings', () {
    testWidgets('no overflow at any target width', (tester) async {
      for (final width in _widths) {
        await pumpAt(tester, Size(width, 900), '/settings');
        expect(
          tester.takeException(),
          isNull,
          reason: 'settings broke at ${width}px',
        );
      }
    });

    testWidgets('the index reports each area\'s current value', (tester) async {
      final container = await pumpAt(tester, const Size(1440, 900), '/settings');
      final profile = container.read(businessProfileProvider);

      expect(find.text('Business profile'), findsOneWidget);
      expect(find.text(profile.name), findsWidgets);
      // Areas the roadmap has not reached are shown, not hidden.
      expect(find.text('Coming soon'), findsWidgets);
    });
  });

  group('Business profile', () {
    testWidgets('no overflow at any target width', (tester) async {
      for (final width in _widths) {
        await pumpAt(tester, Size(width, 900), '/settings/business-profile');
        expect(
          tester.takeException(),
          isNull,
          reason: 'business profile broke at ${width}px',
        );
      }
    });

    testWidgets('save is inert until something changes', (tester) async {
      await pumpAt(tester, const Size(1440, 900), '/settings/business-profile');

      final before = tester.widget<FilledButton>(
        find.byKey(BusinessProfileKeys.save),
      );
      expect(before.onPressed, isNull);

      await tester.enterText(
        find.byKey(BusinessProfileKeys.name),
        'The Brass Olive',
      );
      await tester.pumpAndSettle();

      final after = tester.widget<FilledButton>(
        find.byKey(BusinessProfileKeys.save),
      );
      expect(after.onPressed, isNotNull);
    });

    testWidgets('renaming reaches every screen reading the provider', (
      tester,
    ) async {
      final container = await pumpAt(
        tester,
        const Size(1440, 900),
        '/settings/business-profile',
      );

      await tester.enterText(
        find.byKey(BusinessProfileKeys.name),
        'The Brass Olive',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(BusinessProfileKeys.save));
      await tester.pumpAndSettle();

      expect(container.read(storeNameProvider), 'The Brass Olive');
      expect(
        container.read(businessProfileProvider).name,
        'The Brass Olive',
      );
    });

    testWidgets('the brand colour is stored on the profile', (tester) async {
      final container = await pumpAt(
        tester,
        const Size(1440, 900),
        '/settings/business-profile',
      );

      // The seed profile ships on the app's own accent.
      expect(
        container.read(businessProfileProvider).brandColor.toARGB32(),
        BrandPalette.swatches.first.color.toARGB32(),
      );

      container
          .read(businessProfileProvider.notifier)
          .setBrandColor(BrandPalette.swatches[2].color);
      await tester.pumpAndSettle();

      expect(
        container.read(brandColorProvider).toARGB32(),
        BrandPalette.swatches[2].color.toARGB32(),
      );
    });

    testWidgets('the receipt footer is read from the profile, not hardcoded', (
      tester,
    ) async {
      final container = await pumpAt(
        tester,
        const Size(1440, 900),
        '/settings/business-profile',
      );

      await tester.enterText(
        find.byKey(BusinessProfileKeys.receiptFooter),
        'See you next time!',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(BusinessProfileKeys.save));
      await tester.pumpAndSettle();

      expect(container.read(receiptFooterProvider), 'See you next time!');
    });
  });

  group('Store settings', () {
    testWidgets('no overflow at any target width', (tester) async {
      for (final width in _widths) {
        await pumpAt(tester, Size(width, 900), '/settings/store-settings');
        expect(
          tester.takeException(),
          isNull,
          reason: 'store settings broke at ${width}px',
        );
      }
    });

    testWidgets('save is inert until something changes', (tester) async {
      await pumpAt(tester, const Size(1440, 900), '/settings/store-settings');

      final before = tester.widget<FilledButton>(
        find.byKey(StoreSettingsKeys.save),
      );
      expect(before.onPressed, isNull);

      await tester.enterText(find.byKey(StoreSettingsKeys.taxRate), '12.5');
      await tester.pumpAndSettle();

      final after = tester.widget<FilledButton>(
        find.byKey(StoreSettingsKeys.save),
      );
      expect(after.onPressed, isNotNull);
    });

    testWidgets('tax rate round-trips between percent and fraction', (
      tester,
    ) async {
      final container = await pumpAt(
        tester,
        const Size(1440, 900),
        '/settings/store-settings',
      );

      // Seeded as a percentage of the stored fraction.
      final field = tester.widget<TextFormField>(
        find.byKey(StoreSettingsKeys.taxRate),
      );
      expect(field.controller?.text, '8.25');

      await tester.enterText(find.byKey(StoreSettingsKeys.taxRate), '12.5');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(StoreSettingsKeys.save));
      await tester.pumpAndSettle();

      expect(container.read(taxRateProvider), closeTo(0.125, 0.0001));
    });

    testWidgets('a new ticket opens at the configured tax rate', (
      tester,
    ) async {
      final container = await pumpAt(
        tester,
        const Size(1440, 900),
        '/settings/store-settings',
      );

      // The default has to match what the Cart model shipped with, or existing
      // behaviour would have shifted the moment this screen landed.
      expect(container.read(cartProvider).taxRate, closeTo(0.0825, 0.0001));

      await tester.enterText(find.byKey(StoreSettingsKeys.taxRate), '20');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(StoreSettingsKeys.save));
      await tester.pumpAndSettle();

      // The open cart keeps the rate it was opened at; only a fresh one picks
      // up the change.
      expect(container.read(cartProvider).taxRate, closeTo(0.0825, 0.0001));

      container.invalidate(cartProvider);
      expect(container.read(cartProvider).taxRate, closeTo(0.20, 0.0001));
    });

    testWidgets('the default order type pre-selects the POS ticket', (
      tester,
    ) async {
      final container = await pumpAt(
        tester,
        const Size(1440, 900),
        '/settings/store-settings',
      );

      expect(container.read(orderTypeProvider), OrderType.dineIn);

      container
          .read(storeSettingsProvider.notifier)
          .save(
            container
                .read(storeSettingsProvider)
                .copyWith(defaultOrderType: OrderType.takeaway),
          );
      await tester.pumpAndSettle();

      expect(container.read(orderTypeProvider), OrderType.takeaway);
    });

    testWidgets('the currency reaches every formatted amount', (tester) async {
      final container = await pumpAt(
        tester,
        const Size(1440, 900),
        '/settings/store-settings',
      );

      expect(Fmt.money(48), startsWith(r'$'));

      container.read(storeSettingsProvider.notifier).setCurrency(Currency.gbp);
      await tester.pumpAndSettle();

      expect(container.read(currencyProvider), Currency.gbp);
      expect(Fmt.money(48), startsWith('£'));

      // Left as the app found it: Fmt is a static, so a currency set here
      // would otherwise leak into whichever test runs next.
      container.read(storeSettingsProvider.notifier).setCurrency(Currency.usd);
      await tester.pumpAndSettle();
    });

    testWidgets('a closed day hides its time pickers', (tester) async {
      await pumpAt(tester, const Size(1440, 900), '/settings/store-settings');

      // Monday ships closed, Tuesday open.
      expect(find.byKey(StoreSettingsKeys.openTime(0)), findsNothing);
      expect(find.byKey(StoreSettingsKeys.openTime(1)), findsOneWidget);

      await tester.tap(find.byKey(StoreSettingsKeys.day(0)));
      await tester.pumpAndSettle();

      expect(find.byKey(StoreSettingsKeys.openTime(0)), findsOneWidget);
    });
  });

  group('Store management', () {
    testWidgets('no overflow at any target width', (tester) async {
      for (final width in _widths) {
        await pumpAt(tester, Size(width, 900), '/settings/store-management');
        expect(
          tester.takeException(),
          isNull,
          reason: 'store management broke at ${width}px',
        );
      }
    });

    testWidgets('the summary counts what the table lists', (tester) async {
      final container = await pumpAt(
        tester,
        const Size(1440, 900),
        '/settings/store-management',
      );

      final summary = container.read(locationsSummaryProvider);
      expect(summary.total, container.read(storeLocationsProvider).length);
      expect(find.text('${summary.total}'), findsWidgets);
    });

    testWidgets('a new location becomes a transfer destination', (
      tester,
    ) async {
      final container = await pumpAt(
        tester,
        const Size(1440, 900),
        '/settings/store-management',
      );

      final before = container.read(transferTargetsProvider).length;

      final notifier = container.read(storeLocationsProvider.notifier);
      notifier.upsert(
        StoreLocation(id: notifier.nextId(), name: 'Airport Kiosk'),
      );
      await tester.pumpAndSettle();

      final targets = container.read(transferTargetsProvider);
      expect(targets.length, before + 1);
      expect(targets.any((l) => l.name == 'Airport Kiosk'), isTrue);
    });

    testWidgets('the last active location cannot be deleted', (tester) async {
      final container = await pumpAt(
        tester,
        const Size(1440, 900),
        '/settings/store-management',
      );

      final notifier = container.read(storeLocationsProvider.notifier);
      // Everything except the current store, which is protected in its own
      // right and would mask the rule under test.
      for (final location in [...container.read(storeLocationsProvider)]) {
        if (!location.isCurrent) notifier.delete(location.id);
      }
      await tester.pumpAndSettle();

      final remaining = container.read(storeLocationsProvider);
      expect(remaining.length, 1);
      expect(notifier.canDelete(remaining.first.id), isFalse);
      expect(notifier.delete(remaining.first.id), isFalse);
      expect(container.read(storeLocationsProvider), hasLength(1));
    });
  });

  group('App preferences', () {
    testWidgets('no overflow at any target width', (tester) async {
      for (final width in _widths) {
        await pumpAt(tester, Size(width, 900), '/settings/app-preferences');
        expect(
          tester.takeException(),
          isNull,
          reason: 'app preferences broke at ${width}px',
        );
      }
    });

    testWidgets('the theme selector drives the app\'s ThemeMode', (
      tester,
    ) async {
      final container = await pumpAt(
        tester,
        const Size(1440, 900),
        '/settings/app-preferences',
      );

      expect(container.read(themeModeProvider), ThemeMode.system);

      await tester.tap(find.byKey(AppPreferencesKeys.themeDark));
      await tester.pumpAndSettle();

      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
    });

    testWidgets('density is a real value the tables read', (tester) async {
      final container = await pumpAt(
        tester,
        const Size(1440, 900),
        '/settings/app-preferences',
      );

      expect(container.read(tableDensityProvider), TableDensity.comfortable);

      await tester.tap(
        find.byKey(AppPreferencesKeys.density(TableDensity.compact)),
      );
      await tester.pumpAndSettle();

      expect(container.read(tableDensityProvider), TableDensity.compact);
      expect(
        TableDensity.compact.rowPadding,
        lessThan(TableDensity.comfortable.rowPadding),
      );
    });

    testWidgets('notification toggles hold their state', (tester) async {
      final container = await pumpAt(
        tester,
        const Size(1440, 900),
        '/settings/app-preferences',
      );

      expect(container.read(notificationPrefsProvider).dailySummary, isFalse);

      await tester.tap(find.byKey(AppPreferencesKeys.dailySummary));
      await tester.pumpAndSettle();

      expect(container.read(notificationPrefsProvider).dailySummary, isTrue);
    });
  });

  group('Insights', () {
    testWidgets('no overflow at any target width', (tester) async {
      for (final width in _widths) {
        await pumpAt(tester, Size(width, 900), '/insights');
        expect(
          tester.takeException(),
          isNull,
          reason: 'insights broke at ${width}px',
        );
      }
    });

    testWidgets('insights are derived from live data, not canned', (
      tester,
    ) async {
      final container = await pumpAt(tester, const Size(1440, 900), '/insights');

      final withStockGap = container.read(aiInsightsProvider);
      expect(
        withStockGap.any((i) => i.category == InsightCategory.stock),
        isTrue,
      );

      // The mock stockroom ships with out-of-stock lines, so the urgent
      // stock insight must be present.
      expect(
        withStockGap.any(
          (i) => i.id == 'stock-out' && i.priority == InsightPriority.urgent,
        ),
        isTrue,
      );

      // Restock everything; the urgent insight has to disappear on its own.
      final restocked = [
        for (final item in container.read(inventoryItemsProvider))
          item.copyWith(stock: item.reorderLevel + 100),
      ];
      final notifier = container.read(inventoryItemsProvider.notifier);
      for (final item in restocked) {
        notifier.upsert(item);
      }

      final healthy = container.read(aiInsightsProvider);
      expect(healthy.any((i) => i.id == 'stock-out'), isFalse);
      expect(healthy.any((i) => i.id == 'stock-healthy'), isTrue);
    });

    testWidgets('every insight carries checkable evidence or an action', (
      tester,
    ) async {
      final container = await pumpAt(tester, const Size(1440, 900), '/insights');

      for (final insight in container.read(aiInsightsProvider)) {
        expect(
          insight.evidence.isNotEmpty || insight.hasAction,
          isTrue,
          reason:
              '"${insight.title}" states a conclusion with nothing to check '
              'it against',
        );
      }
    });

    testWidgets('an out-of-stock line names itself in the urgent insight', (
      tester,
    ) async {
      final container = await pumpAt(tester, const Size(1440, 900), '/insights');

      final out = container
          .read(inventoryItemsProvider)
          .where((i) => i.status == StockStatus.outOfStock)
          .toList();
      expect(out, isNotEmpty, reason: 'fixture should include empty lines');

      final insight = container
          .read(aiInsightsProvider)
          .firstWhere((i) => i.id == 'stock-out');

      expect(insight.body, contains(out.first.name));
    });
  });
}
