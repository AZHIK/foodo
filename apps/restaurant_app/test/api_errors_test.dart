import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos/utils/api_errors.dart';

void main() {
  group('errorDetail', () {
    test('reads FastAPI HTTPException bodies', () {
      expect(
        errorDetail(
          {'detail': "A store named 'X' already exists in this business."},
          fallback: 'fallback',
        ),
        "A store named 'X' already exists in this business.",
      );
    });

    test('joins FastAPI validation error lists', () {
      final text = errorDetail(
        {
          'detail': [
            {'loc': ['body', 'phone'], 'msg': 'Phone number is not valid'},
          ],
        },
        fallback: 'fallback',
      );
      expect(text, contains('Phone number is not valid'));
    });

    test('passes plain-text bodies through instead of crashing', () {
      expect(
        errorDetail('Internal Server Error', fallback: 'fallback'),
        'Internal Server Error',
      );
    });

    test('falls back on null, empty and unknown shapes', () {
      expect(errorDetail(null, fallback: 'fallback'), 'fallback');
      expect(errorDetail('', fallback: 'fallback'), 'fallback');
      expect(errorDetail(42, fallback: 'fallback'), 'fallback');
      expect(errorDetail({'detail': []}, fallback: 'fallback'), 'fallback');
    });
  });
}
