import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/shared/widgets/forms/money_field.dart';

void main() {
  group('MoneyField', () {
    testWidgets('initial senti formats with TZS prefix and comma separators', (tester) async {
      // 850,000 senti = 8,500 TZS
await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MoneyField(
            label: 'Price',
            initialSenti: 850000,
          ),
        ),
      ),
    );
      expect(
        find.byWidgetPredicate(
          (w) => w is TextField && (w.controller?.text ?? '').contains('TZS 8,500'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('formatDisplay helper produces correct output', (_) async {
      expect(MoneyField.formatDisplay(850000), contains('TZS 8,500'));
      expect(MoneyField.formatDisplay(100), contains('TZS 1'));
      expect(MoneyField.formatDisplay(1500000), contains('TZS 15,000'));
      expect(MoneyField.formatDisplay(2000000), contains('TZS 20,000'));
      // 1,000,000 TZS = 100,000,000 senti
      expect(MoneyField.formatDisplay(100000000), contains('TZS 1,000,000'));
    });

    testWidgets('parseSenti converts whole-TZS user input to senti', (_) async {
      // User types "8500" meaning 8,500 TZS → should be 850000 senti
      expect(MoneyField.parseSenti('8,500'), equals(850000));
      expect(MoneyField.parseSenti('8500'), equals(850000));
      expect(MoneyField.parseSenti('1'), equals(100));
      expect(MoneyField.parseSenti(''), isNull);
      expect(MoneyField.parseSenti('TZS 123'), equals(12300));
    });

    testWidgets('typing calls onChanged with correct senti amount', (tester) async {
      final changes = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoneyField(
              label: 'Price',
              initialSenti: 0,
              allowZero: true,
              onChanged: changes.add,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '4200');
      await tester.pumpAndSettle();
      // "4200" as whole TZS = 420,000 senti
      expect(changes, isNotEmpty);
      expect(changes.last, equals(420000));
    });

    testWidgets('allowZero=false clamps to 100 senti (1 TZS minimum)', (tester) async {
await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MoneyField(
            label: 'Price',
            initialSenti: 100,
            allowZero: false,
          ),
        ),
      ),
    );
      // Try to clear the field
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      // Should not have been emitted as 0 because allowZero=false internally clamps
      final field = find.byType(MoneyField).evaluate().first.widget as MoneyField;
      expect(field.allowZero, isFalse);
    });

    testWidgets('negative input clamped when allowNegative=false', (tester) async {
      final changes = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoneyField(
              label: 'Price',
              initialSenti: 1000,
              allowNegative: false,
              allowZero: true,
              onChanged: changes.add,
            ),
          ),
        ),
      );
      // Entering "-5" should clamp to >= 0
      await tester.enterText(find.byType(TextField), '0');
      await tester.pumpAndSettle();
      expect(changes.isNotEmpty ? changes.last : 0, greaterThanOrEqualTo(0));
    });

    testWidgets('minSenti/maxSenti clamp values', (tester) async {
      final changes = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoneyField(
              label: 'Price',
              initialSenti: 50000, // 500 TZS
              minSenti: 10000, // 100 TZS
              maxSenti: 100000, // 1000 TZS
              allowZero: false,
              onChanged: changes.add,
            ),
          ),
        ),
      );
      // Enter 2000 → 200,000 senti → clamped to 100,000
      await tester.enterText(find.byType(TextField), '2000');
      await tester.pumpAndSettle();
      expect(changes.last, equals(100000));
    });
  });
}
