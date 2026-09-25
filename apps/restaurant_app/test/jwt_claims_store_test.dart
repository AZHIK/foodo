import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_pos/auth/jwt_decoder.dart';

String _token(Map<String, dynamic> payload) {
  String part(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${part({'alg': 'RS256'})}.${part(payload)}.sig';
}

void main() {
  group('JwtClaims store scope', () {
    test('decodes active_store_id and user_category', () {
      final claims = decodeAccessToken(
        _token({
          'sub': 'user-1',
          'exp': 9999999999,
          'active_business_id': 'biz-1',
          'active_store_id': 'store-2',
          'user_category': 'business_staff',
          'permissions': ['stores.switch'],
          'roles': ['Manager'],
        }),
      );

      expect(claims.activeStoreId, 'store-2');
      expect(claims.isBusinessStaff, isTrue);
      expect(claims.can('stores.switch'), isTrue);
    });

    test('legacy tokens without store scope decode as before', () {
      final claims = decodeAccessToken(
        _token({
          'sub': 'user-1',
          'exp': 9999999999,
          'active_business_id': 'biz-1',
          'permissions': <String>[],
          'roles': <String>[],
        }),
      );

      expect(claims.activeStoreId, isNull);
      expect(claims.isBusinessStaff, isFalse);
    });

    test('store staff is not business staff', () {
      final claims = decodeAccessToken(
        _token({
          'sub': 'user-2',
          'exp': 9999999999,
          'user_category': 'business_store_staff',
          'permissions': <String>[],
          'roles': <String>[],
        }),
      );

      expect(claims.isBusinessStaff, isFalse);
    });
  });
}
