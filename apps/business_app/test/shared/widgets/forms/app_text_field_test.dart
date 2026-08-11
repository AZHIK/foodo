import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/shared/widgets/forms/app_text_field.dart';

void main() {
  group('AppTextField', () {
    testWidgets('renders label text', (tester) async {
await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppTextField(label: 'Full name'),
        ),
      ),
    );
      expect(find.text('Full name'), findsOneWidget);
    });

    testWidgets('validator shows error text', (tester) async {
      final key = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: key,
              child: AppTextField(
                label: 'Required',
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter a value' : null,
              ),
            ),
          ),
        ),
      );
      key.currentState!.validate();
      await tester.pumpAndSettle();
      expect(find.text('Please enter a value'), findsOneWidget);
    });

    testWidgets('onChanged fires on text entry', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Name',
              onChanged: values.add,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'Hello');
      expect(values.last, equals('Hello'));
    });

    testWidgets('prefixIcon renders', (tester) async {
await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppTextField(
            label: 'Search',
            prefixIcon: Icons.search,
          ),
        ),
      ),
    );
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('readOnly field does not accept input', (tester) async {
      final ctrl = TextEditingController(text: 'locked');
      addTearDown(ctrl.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'RO',
              controller: ctrl,
              readOnly: true,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'attempt');
      expect(ctrl.text, equals('locked'));
    });
  });
}
