import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/shared/widgets/forms/app_number_field.dart';

void main() {
  group('AppNumberField', () {
    testWidgets('initial value displays correctly', (tester) async {
await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppNumberField(label: 'Qty', initialValue: 5),
        ),
      ),
    );
      expect(find.widgetWithText(TextField, '5'), findsOneWidget);
    });

    testWidgets('+ button increments value by step', (tester) async {
      int? last;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppNumberField(
              label: 'Qty',
              initialValue: 1,
              step: 1,
              onChanged: (v) => last = v,
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(last, equals(2));
      expect(find.widgetWithText(TextField, '2'), findsOneWidget);
    });

    testWidgets('- button decrements value by step', (tester) async {
      int? last;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppNumberField(
              label: 'Qty',
              initialValue: 10,
              step: 2,
              onChanged: (v) => last = v,
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(last, equals(8));
    });

    testWidgets('allowNegative=false clamps negative to zero or step', (tester) async {
      int? last;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppNumberField(
              label: 'Qty',
              initialValue: 1,
              step: 1,
              allowNegative: false,
              onChanged: (v) => last = v,
            ),
          ),
        ),
      );
      // From 1 → push - twice; expect it can't go below 0 (allowZero default is true)
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(last, isNotNull);
      expect(last, greaterThanOrEqualTo(0));
    });

    testWidgets('allowZero=false + allowNegative=false prevents 0', (tester) async {
      int? last;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppNumberField(
              label: 'Qty',
              initialValue: 1,
              step: 1,
              allowZero: false,
              allowNegative: false,
              onChanged: (v) => last = v,
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(last, equals(1)); // clamped back to step=1
    });

    testWidgets('min/max clamp stepper output', (tester) async {
      int? last;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppNumberField(
              label: 'Qty',
              initialValue: 1,
              step: 1,
              min: 1,
              max: 3,
              onChanged: (v) => last = v,
            ),
          ),
        ),
      );
      // Go up 5 times → max 3
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
      }
      expect(last, equals(3));
      // Go down 10 times → min 1
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.byIcon(Icons.remove));
        await tester.pumpAndSettle();
      }
      expect(last, equals(1));
    });

    testWidgets('validator captures clamped value', (tester) async {
      final key = GlobalKey<FormState>();
      String? err;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: key,
              child: AppNumberField(
                label: 'Qty',
                initialValue: 0,
                validator: (v) {
                  err = (v == null || v < 1) ? 'Must be >= 1' : null;
                  return err;
                },
              ),
            ),
          ),
        ),
      );
      key.currentState!.validate();
      await tester.pumpAndSettle();
      expect(err, equals('Must be >= 1'));
    });
  });
}
