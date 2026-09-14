import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/widgets/item_photo.dart';

import 'test_helpers/test_container.dart';

/// A 1x1 PNG — only needs to decode, not to look like anything.
final _tinyPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
  0x0C, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0x0F, 0x00, 0x00,
  0x01, 0x01, 0x00, 0x05, 0x18, 0xD8, 0x4E, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Future<void> _pumpPhoto(
  WidgetTester tester,
  ItemPhoto photo,
) async {
  final container = newTestContainer();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: SizedBox(width: 40, height: 40)),
      ),
    ),
  );
  // Swap in the photo under test inside the same scope.
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(body: SizedBox(width: 40, height: 40, child: photo)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('ItemPhoto', () {
    testWidgets('local bytes render an image, not the placeholder',
        (tester) async {
      await _pumpPhoto(
        tester,
        ItemPhoto(emoji: '🍚', bytes: _tinyPng),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('🍚'), findsNothing);
    });

    testWidgets('no photo at all renders the emoji placeholder',
        (tester) async {
      await _pumpPhoto(
        tester,
        const ItemPhoto(emoji: '🍚'),
      );

      expect(find.text('🍚'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('a remote URL with no business context falls back to emoji',
        (tester) async {
      // No business context in the container, so the bytes provider
      // resolves null — the photo must degrade, not spin or error.
      await _pumpPhoto(
        tester,
        const ItemPhoto(
          emoji: '🍚',
          imageUrl: '/businesses/biz/items/item-1/image',
          catalogItemId: 'item-1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('🍚'), findsOneWidget);
    });
  });
}
