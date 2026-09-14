import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/screens/inventory/record_production_dialog.dart';
import 'package:restaurant_pos/theme/app_theme.dart';

import 'production_preview_test.dart' show pilauRecipe;
import 'test_helpers/test_container.dart';

/// Pumps just the dialog (not the whole app) with an in-memory container.
///
/// The dialog takes its recipe as a constructor argument and reads only
/// unwrapped list providers, so it renders fully with no business context —
/// submitting is what needs the backend, and that path is exercised as the
/// error snackbar rather than a success.
Future<ProviderContainer> pumpDialog(WidgetTester tester) async {
  final container = newTestContainer();

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

void main() {
  group('RecordProductionDialog', () {
    testWidgets('submit waits for a measured quantity', (tester) async {
      await pumpDialog(tester);

      expect(find.text('Record production'), findsWidgets);
      expect(
        tester
            .widget<FilledButton>(find.byKey(ProductionDialogKeys.submit))
            .onPressed,
        isNull,
      );

      await tester.enterText(
        find.byKey(ProductionDialogKeys.leadingQty),
        '2',
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FilledButton>(find.byKey(ProductionDialogKeys.submit))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('typing a quantity previews consumption and suggestion', (
      tester,
    ) async {
      await pumpDialog(tester);

      await tester.enterText(
        find.byKey(ProductionDialogKeys.leadingQty),
        '2',
      );
      await tester.pumpAndSettle();

      // 2kg rice at 0.2kg/plate: the suggestion and every consumption.
      expect(find.text('Suggested output'), findsOneWidget);
      expect(find.textContaining('10 × Pilau'), findsWidgets);
      expect(find.text('Meat'), findsOneWidget);
      expect(find.textContaining('1 kg'), findsWidgets);
      // The confirmed-output field tracks the suggestion until edited.
      expect(find.widgetWithText(TextField, '10'), findsOneWidget);
    });

    testWidgets('submitting without a backend shows the error, not a crash', (
      tester,
    ) async {
      await pumpDialog(tester);

      await tester.enterText(
        find.byKey(ProductionDialogKeys.leadingQty),
        '2',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ProductionDialogKeys.submit));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not record'), findsOneWidget);
    });
  });
}
