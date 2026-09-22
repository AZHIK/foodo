import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/providers/production_provider.dart';
import 'package:restaurant_pos/screens/inventory/record_production_dialog.dart';
import 'package:restaurant_pos/theme/app_theme.dart';

import 'production_module_screen_test.dart' show FakeRunsNotifier;
import 'production_preview_test.dart' show pilauRecipe;
import 'test_helpers/test_container.dart';

/// Pumps just the dialog (not the whole app) with an in-memory container.
///
/// The dialog takes its recipe as a constructor argument and reads only
/// unwrapped list providers, so it renders fully with no business context —
/// submitting is what needs the backend, and that path is exercised as the
/// error snackbar rather than a success. Pass [runsNotifier] to answer
/// run writes (used by the finish-later exit).
Future<ProviderContainer> pumpDialog(
  WidgetTester tester, {
  ProductionRunsNotifier? runsNotifier,
}) async {
  final container = newTestContainer(
    extraOverrides: [
      if (runsNotifier != null)
        productionRunsProvider.overrideWith(() => runsNotifier),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showRecordProductionDialog(context, pilauRecipe()),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return container;
}

/// Target step → measure step: the plan call has no backend here, so the
/// dialog falls back to its local `requirement × target` seeding.
Future<void> enterTargetAndContinue(WidgetTester tester, String target) async {
  await tester.enterText(find.byKey(ProductionDialogKeys.targetQty), target);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ProductionDialogKeys.toMeasure));
  await tester.pumpAndSettle();
}

void main() {
  group('RecordProductionDialog', () {
    testWidgets('asks for the target first', (tester) async {
      await pumpDialog(tester);

      expect(find.text('Record production'), findsWidgets);
      expect(find.byKey(ProductionDialogKeys.targetQty), findsOneWidget);
      // Nothing to measure yet — continue waits for a target quantity.
      expect(
        tester
            .widget<FilledButton>(find.byKey(ProductionDialogKeys.toMeasure))
            .onPressed,
        isNull,
      );

      await tester.enterText(
        find.byKey(ProductionDialogKeys.targetQty),
        '10',
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FilledButton>(find.byKey(ProductionDialogKeys.toMeasure))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('target seeds every adjustable ingredient amount', (
      tester,
    ) async {
      await pumpDialog(tester);
      await enterTargetAndContinue(tester, '10');

      // 10 plates at 0.2kg rice + 0.1kg meat per plate, adjustable.
      expect(find.text('Rice'), findsOneWidget);
      expect(find.text('Meat'), findsOneWidget);
      expect(find.widgetWithText(TextField, '2'), findsOneWidget);
      expect(find.widgetWithText(TextField, '1'), findsOneWidget);
      // First line keeps the legacy leading key.
      expect(find.byKey(ProductionDialogKeys.leadingQty), findsOneWidget);
    });

    testWidgets('confirm step previews the within-threshold verdict', (
      tester,
    ) async {
      await pumpDialog(tester);
      await enterTargetAndContinue(tester, '10');

      await tester.tap(find.byKey(ProductionDialogKeys.toConfirm));
      await tester.pumpAndSettle();

      // Actual tracks the target until edited — plan met.
      expect(find.widgetWithText(TextField, '10'), findsOneWidget);
      expect(find.textContaining('Within threshold'), findsOneWidget);
    });

    testWidgets('a shortfall previews the below-target verdict', (
      tester,
    ) async {
      await pumpDialog(tester);
      await enterTargetAndContinue(tester, '10');

      await tester.tap(find.byKey(ProductionDialogKeys.toConfirm));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(ProductionDialogKeys.actualQty), '8');
      await tester.pumpAndSettle();

      expect(find.textContaining('Below target'), findsOneWidget);
    });

    testWidgets('finish later saves a cooking run instead of demanding output', (
      tester,
    ) async {
      await pumpDialog(tester, runsNotifier: FakeRunsNotifier());
      await enterTargetAndContinue(tester, '10');

      await tester.tap(find.byKey(ProductionDialogKeys.toConfirm));
      await tester.pumpAndSettle();

      // No output entered — the cook leaves for the kitchen instead.
      await tester.tap(find.byKey(ProductionDialogKeys.finishLater));
      await tester.pumpAndSettle();

      // Dialog closed with guidance to finish on the Runs tab.
      expect(find.byKey(ProductionDialogKeys.finishLater), findsNothing);
      expect(find.textContaining('Runs'), findsOneWidget);
    });

    testWidgets('submitting without a backend shows the error, not a crash', (
      tester,
    ) async {
      await pumpDialog(tester);
      await enterTargetAndContinue(tester, '10');

      await tester.tap(find.byKey(ProductionDialogKeys.toConfirm));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ProductionDialogKeys.submit));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not record'), findsOneWidget);
    });
  });
}
