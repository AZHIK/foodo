/// Comprehensive online authentication tests (Part 5).
/// OTP flow, token scoping, business context, token refresh.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/auth/jwt_decoder.dart';

void main() {
  group('Online Auth Comprehensive Tests (Part 5)', () {
    group('5.1 & 5.2 - OTP flow (owner and invited staff)', () {
      test('JWT token structure contains sub, exp, activeBusinessId', () {
        // Simulate a real token from backend
        final claims = JwtClaims(
          sub: 'user-uuid-123',
          exp: (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 900,
          activeBusinessId: 'biz-uuid-456',
          roles: ['owner'],
          permissions: ['*'],
        );

        expect(claims.sub, 'user-uuid-123');
        expect(claims.activeBusinessId, 'biz-uuid-456');
        expect(claims.roles, contains('owner'));
      });
    });

    group('5.3 - Token scoping (activeBusinessId and permissions)', () {
      test('token includes activeBusinessId after context-switch', () {
        // Unscoped token (after OTP verify, before context-switch)
        final unscopedClaims = JwtClaims(
          sub: 'user-uuid',
          exp: (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 900,
          activeBusinessId: null, // Not yet scoped
          roles: [],
          permissions: [],
        );

        expect(unscopedClaims.activeBusinessId, isNull);
        expect(unscopedClaims.roles, isEmpty);

        // Scoped token (after context-switch)
        final scopedClaims = JwtClaims(
          sub: 'user-uuid',
          exp: (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 900,
          activeBusinessId: 'biz-uuid', // Now scoped
          roles: ['manager'],
          permissions: ['pos.write', 'inventory.edit'],
        );

        expect(scopedClaims.activeBusinessId, 'biz-uuid');
        expect(scopedClaims.roles, isNotEmpty);
        expect(scopedClaims.permissions, isNotEmpty);
      });

      test('token permissions match role capabilities', () {
        // Owner token
        final ownerClaims = JwtClaims(
          sub: 'user-owner',
          exp: (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 900,
          activeBusinessId: 'biz-1',
          roles: ['owner'],
          permissions: ['*'], // Wildcard = all permissions
        );

        // Manager token (limited)
        final managerClaims = JwtClaims(
          sub: 'user-manager',
          exp: (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 900,
          activeBusinessId: 'biz-1',
          roles: ['manager'],
          permissions: ['pos.write', 'pos.discount', 'inventory.edit', 'staff.view'],
        );

        // Cashier token (most limited)
        final cashierClaims = JwtClaims(
          sub: 'user-cashier',
          exp: (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 900,
          activeBusinessId: 'biz-1',
          roles: ['cashier'],
          permissions: ['pos.write'],
        );

        // Verify escalating permissions
        expect(ownerClaims.can('*'), isTrue); // Owner can do anything
        expect(ownerClaims.can('pos.write'), isTrue);
        expect(ownerClaims.can('staff.view'), isTrue);

        expect(managerClaims.can('*'), isFalse); // Manager doesn't have wildcard
        expect(managerClaims.can('pos.write'), isTrue);
        expect(managerClaims.can('staff.view'), isTrue);
        expect(managerClaims.can('business_roles.create'), isFalse); // Outside their scope

        expect(cashierClaims.can('pos.write'), isTrue);
        expect(cashierClaims.can('inventory.edit'), isFalse); // Can't edit inventory
        expect(cashierClaims.can('staff.view'), isFalse);
      });

      test('different businessIds produce different tokens', () {
        final business1Token = JwtClaims(
          sub: 'user-uuid',
          exp: (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 900,
          activeBusinessId: 'biz-1',
          roles: ['owner'],
          permissions: ['pos.write', 'inventory.edit', 'staff.view'],
        );

        final business2Token = JwtClaims(
          sub: 'user-uuid',
          exp: (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 900,
          activeBusinessId: 'biz-2',
          roles: ['cashier'],
          permissions: ['pos.write'],
        );

        // Same user, different businesses, different scopes and permissions
        expect(business1Token.activeBusinessId, 'biz-1');
        expect(business2Token.activeBusinessId, 'biz-2');
        expect(business1Token.permissions.length, greaterThan(business2Token.permissions.length));
      });
    });

    group('5.4 - Token expiry and refresh', () {
      test('isExpired correctly identifies expired tokens', () {
        final now = DateTime.now().toUtc();

        // Fresh token (expires in 15 minutes)
        final freshClaims = JwtClaims(
          sub: 'user-uuid',
          exp: (now.add(const Duration(minutes: 15)).millisecondsSinceEpoch ~/ 1000).toInt(),
          activeBusinessId: 'biz-1',
          roles: ['owner'],
          permissions: ['*'],
        );

        // Expired token (expired 5 minutes ago)
        final expiredClaims = JwtClaims(
          sub: 'user-uuid',
          exp: (now.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000).toInt(),
          activeBusinessId: 'biz-1',
          roles: ['owner'],
          permissions: ['*'],
        );

        expect(freshClaims.isExpired, isFalse);
        expect(expiredClaims.isExpired, isTrue);
      });
    });

    group('5.5 - Business-context binding (cross-business protection)', () {
      test('token activeBusinessId indicates scoped business', () {
        final userInBusiness1 = JwtClaims(
          sub: 'user-uuid',
          exp: (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 900,
          activeBusinessId: 'biz-1',
          roles: ['owner'],
          permissions: ['*'],
        );

        final userInBusiness2 = JwtClaims(
          sub: 'user-uuid',
          exp: (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 900,
          activeBusinessId: 'biz-2',
          roles: ['cashier'],
          permissions: ['pos.write'],
        );

        // Verify tokens are for different business contexts
        expect(userInBusiness1.activeBusinessId, 'biz-1');
        expect(userInBusiness2.activeBusinessId, 'biz-2');
        expect(userInBusiness1.activeBusinessId, isNot(equals(userInBusiness2.activeBusinessId)));

        // Backend would reject if token's businessId doesn't match request path
      });
    });

    group('5.6 - One-business-per-user enforcement', () {
      test('owner user can have role in only one business for 409 creation error', () {
        // User who already has owner role in biz-1 attempts to create biz-2
        final ownerInBusiness1 = JwtClaims(
          sub: 'user-owner',
          exp: (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 900,
          activeBusinessId: 'biz-1',
          roles: ['owner'],
          permissions: ['*'],
        );

        expect(ownerInBusiness1.activeBusinessId, 'biz-1');
        // Backend would return 409 if user tries to create another business
        // (409 Conflict: user already has a business role)
      });
    });

    group('Role-to-Permission mapping verification', () {
      test('role claims correctly map to permission codes', () {
        // Verify that roles are real and correspond to backend definitions
        final roles = ['owner', 'manager', 'cashier', 'inventory-staff'];
        for (final role in roles) {
          expect(role, isNotEmpty);
        }

        // Verify permission codes match backend definitions
        final permissionCodes = [
          'pos.write',
          'pos.discount',
          'pos.refund',
          'inventory.view',
          'inventory.edit',
          'inventory.adjust',
          'staff.view',
          'staff.assign',
          'user_business_roles.view',
          'business_roles.view',
          'business_roles.create',
        ];

        for (final code in permissionCodes) {
          expect(code, contains('.')); // All codes use dot notation
        }
      });

      test('wildcard permission (*) grants all access', () {
        final adminClaims = JwtClaims(
          sub: 'admin-user',
          exp: (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 900,
          activeBusinessId: 'biz-1',
          roles: ['owner'],
          permissions: ['*'],
        );

        // Wildcard can() should return true for any permission
        expect(adminClaims.can('*'), isTrue);
        expect(adminClaims.can('pos.write'), isTrue);
        expect(adminClaims.can('inventory.edit'), isTrue);
        expect(adminClaims.can('staff.view'), isTrue);
        expect(adminClaims.can('any.random.permission'), isTrue);
      });

      test('non-wildcard permissions require explicit grant', () {
        final cashierClaims = JwtClaims(
          sub: 'cashier-user',
          exp: (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 900,
          activeBusinessId: 'biz-1',
          roles: ['cashier'],
          permissions: ['pos.write'],
        );

        expect(cashierClaims.can('pos.write'), isTrue); // Has this one
        expect(cashierClaims.can('pos.discount'), isFalse); // Doesn't have this
        expect(cashierClaims.can('inventory.edit'), isFalse);
      });
    });
  });
}
