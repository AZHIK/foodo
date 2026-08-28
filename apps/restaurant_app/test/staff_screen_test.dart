import 'dart:async' show unawaited;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/main.dart';
import 'package:restaurant_pos/models/business_role.dart';
import 'package:restaurant_pos/models/permission.dart';
import 'package:restaurant_pos/models/session.dart';
import 'package:restaurant_pos/models/staff_member.dart';
import 'package:restaurant_pos/providers/auth_provider.dart';
import 'package:restaurant_pos/providers/roles_provider.dart';
import 'package:restaurant_pos/providers/session_provider.dart';
import 'package:restaurant_pos/providers/staff_provider.dart';
import 'package:restaurant_pos/router/app_router.dart';
import 'package:restaurant_pos/widgets/data_page/summary_metric_card.dart';

import 'test_helpers/fake_identity_backend.dart';

const _widths = <double>[360, 400, 768, 1024, 1440, 1920];
const _businessId = 'biz-1';

const _ownerRoleId = 'role-owner';
const _managerRoleId = 'role-manager';
const _cashierRoleId = 'role-cashier';
const _stockRoleId = 'role-stock';

/// A business with a handful of real-shaped roles and staff, seeded into a
/// [FakeIdentityBackendState] — these screens now call the real
/// identity-service endpoints (via `identityServiceDioProvider`), so there's
/// no more `MockStaff` for them to read; this is the fixture in its place.
Map<String, dynamic> _role(
  String id,
  String name, {
  bool protected = false,
  List<String> permissions = const [],
}) {
  final now = DateTime.now().toUtc().toIso8601String();
  return {
    'id': id,
    'business_id': _businessId,
    'name': name,
    'description': '$name role',
    'is_protected': protected,
    'created_at': now,
    'updated_at': now,
    'permission_codes': [...permissions],
  };
}

Map<String, dynamic> _staff(
  String userId,
  String phone,
  String name, {
  required String status,
  required List<(String, String)> roles,
}) {
  return {
    'user_id': userId,
    'phone': phone,
    'full_name': name,
    'email': '$userId@example.com',
    'status': status,
    'roles': [
      for (final (roleId, roleName) in roles) {'business_role_id': roleId, 'name': roleName},
    ],
  };
}

FakeIdentityBackendState _seededState() {
  final state = FakeIdentityBackendState()
    ..businessId = _businessId
    ..businessName = 'Test Business'
    ..needsOnboarding = false;

  state.roles.addAll([
    _role(_ownerRoleId, 'Owner', protected: true, permissions: const ['*']),
    _role(_managerRoleId, 'Manager', permissions: [AppPermissions.posAccess]),
    _role(_cashierRoleId, 'Cashier', permissions: [AppPermissions.posAccess]),
    _role(_stockRoleId, 'Stock Controller'),
  ]);

  state.staff.addAll([
    _staff('stf-01', '+255700000001', 'Ava Mensah',
        status: 'active', roles: const [(_ownerRoleId, 'Owner')]),
    _staff('stf-02', '+255700000002', 'Dan Okoye',
        status: 'active', roles: const [(_cashierRoleId, 'Cashier')]),
    _staff('stf-03', '+255700000003', 'Lena Vogel',
        status: 'active', roles: const [(_stockRoleId, 'Stock Controller')]),
    _staff('stf-04', '+255700000004', 'Tomas Alvarez',
        status: 'invited', roles: const [(_cashierRoleId, 'Cashier')]),
  ]);

  return state;
}

Future<ProviderContainer> pumpAt(
  WidgetTester tester,
  Size size,
  String route, {
  FakeIdentityBackendState? state,
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.reset);

  final backendState = state ?? _seededState();
  final container = ProviderContainer(
    overrides: [
      identityServiceDioProvider.overrideWithValue(
        Dio()..httpClientAdapter = FakeIdentityAdapter(backendState),
      ),
    ],
  );
  addTearDown(container.dispose);

  // These screens all assume an authenticated, business-scoped, unlocked,
  // onboarded session — seeded directly rather than driven through the real
  // OTP + business creation flow, which `auth_flow_test.dart` already
  // covers on its own. The router guard reads `sessionProvider` (not
  // `authProvider`) to decide whether a route is even reachable, so both
  // need seeding or every route redirects to the login screen.
  container.read(authProvider.notifier).state = AuthContext(
    state: AuthState.complete,
    accessToken: fakeScopedToken(userId: 'stf-01', businessId: backendState.businessId),
  );
  container.read(sessionProvider.notifier).state = const SessionState(
    activeStaffId: 'stf-01',
    isLoggedIn: true,
    pin: 'fake-pin-hash',
    isUnlocked: true,
    hasCompletedOnboarding: true,
    bootstrapped: true,
  );

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
  group('Staff list', () {
    testWidgets('no overflow at any target width', (tester) async {
      for (final width in _widths) {
        await pumpAt(tester, Size(width, 900), '/staff');
        expect(
          tester.takeException(),
          isNull,
          reason: 'staff list broke at ${width}px',
        );
      }
    });

    testWidgets('summary cards report the roster', (tester) async {
      final container = await pumpAt(tester, const Size(1440, 900), '/staff');
      final summary = container.read(staffSummaryProvider);

      expect(find.byType(SummaryMetricCard), findsNWidgets(3));
      expect(find.text('${summary.total}'), findsWidgets);
      expect(summary.total, 4);
    });

    testWidgets('inviting adds a pending member to the shared provider', (
      tester,
    ) async {
      final container = await pumpAt(tester, const Size(1440, 900), '/staff');
      final before = (container.read(staffMembersProvider).valueOrNull ?? const []).length;

      await tester.tap(find.text('Invite staff'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g. Tomas Alvarez'),
        'Casey Nkemdirim',
      );
      await tester.enterText(find.widgetWithText(TextFormField, '6XXXXXXXX or 7XXXXXXXX'), '712300099');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Select a role'));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cashier').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Send invite'));
      await tester.pumpAndSettle();

      final members = container.read(staffMembersProvider).valueOrNull ?? const [];
      expect(members, hasLength(before + 1));

      final added = members.firstWhere((m) => m.phone == '+255712300099');
      expect(added.status, StaffStatus.pendingInvite);
      expect(added.roles.single.roleId, _cashierRoleId);
    });
  });

  group('Roles', () {
    testWidgets('no overflow at any target width', (tester) async {
      for (final width in _widths) {
        await pumpAt(tester, Size(width, 900), '/staff/roles');
        expect(
          tester.takeException(),
          isNull,
          reason: 'roles list broke at ${width}px',
        );
      }
    });

    testWidgets('/staff/roles resolves to the roles page, not a staff id', (
      tester,
    ) async {
      await pumpAt(tester, const Size(1440, 900), '/staff/roles');

      expect(find.text('Roles & permissions'), findsOneWidget);
      expect(find.textContaining('not found'), findsNothing);
    });

    testWidgets('a permission edit reaches every screen reading the provider', (
      tester,
    ) async {
      final container = await pumpAt(
        tester,
        const Size(1440, 900),
        '/staff/roles',
      );
      await tester.pumpAndSettle();

      final before = container.read(roleByIdProvider(_cashierRoleId))!.permissionCount;

      // Row tap opens the form in edit mode.
      await tester.tap(find.text('Cashier'));
      await tester.pumpAndSettle();

      // Grant everything in the Point of Sale group via its bulk action.
      await tester.tap(find.widgetWithText(TextButton, 'All').first);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save role'));
      await tester.pumpAndSettle();

      final after = container.read(roleByIdProvider(_cashierRoleId))!;
      expect(after.permissionCount, greaterThan(before));
      expect(after.has(AppPermissions.posRefund), isTrue);
    });

    testWidgets('protected roles cannot be deleted', (tester) async {
      final container = await pumpAt(
        tester,
        const Size(1440, 900),
        '/staff/roles',
      );
      await tester.pumpAndSettle();

      final owner = container.read(roleByIdProvider(_ownerRoleId))!;
      expect(owner.isProtected, isTrue);

      final before = (container.read(rolesProvider).valueOrNull ?? const []).length;

      // The real backend 403s a delete on a protected role — verified
      // directly against the fake adapter's same rule (see
      // FakeIdentityAdapter's PATCH/DELETE role handling). Kicked off
      // without a direct `await` — the fake HTTP call's Future only
      // resolves once `pumpAndSettle` advances the test zone's microtask
      // queue, which a bare `await` outside a widget interaction never does.
      Object? error;
      unawaited(
        container.read(rolesProvider.notifier).delete(owner.id).catchError((e) {
          error = e;
        }),
      );
      await tester.pumpAndSettle();

      expect(error, isNotNull, reason: 'deleting a protected role should be rejected');
      expect(
        container.read(rolesProvider).valueOrNull,
        hasLength(before),
        reason: 'a protected role must survive a rejected delete call',
      );
    });

    testWidgets('duplicating a role gives it a distinct name', (tester) async {
      final container = await pumpAt(
        tester,
        const Size(1440, 900),
        '/staff/roles',
      );
      await tester.pumpAndSettle();

      BusinessRole? copy;
      unawaited(
        container.read(rolesProvider.notifier).duplicate(_managerRoleId).then((r) => copy = r),
      );
      await tester.pumpAndSettle();

      expect(copy, isNotNull);
      final created = copy!;
      expect(created.isProtected, isFalse);
      expect(created.name, isNot('Manager'));
      expect(
        (container.read(rolesProvider).valueOrNull ?? const [])
            .where((r) => r.name == created.name),
        hasLength(1),
      );
    });
  });

  group('Staff detail', () {
    testWidgets('no overflow at any target width', (tester) async {
      for (final width in _widths) {
        await pumpAt(tester, Size(width, 900), '/staff/stf-02');
        expect(
          tester.takeException(),
          isNull,
          reason: 'staff detail broke at ${width}px',
        );
      }
    });

    testWidgets("performance block follows the role's POS permission", (
      tester,
    ) async {
      // stf-02 is a Cashier — has till access.
      var container = await pumpAt(
        tester,
        const Size(1440, 900),
        '/staff/stf-02',
      );
      await tester.pumpAndSettle();
      expect(container.read(staffPerformanceProvider('stf-02')).applies, isTrue);
      // SummaryMetricCard uppercases its label.
      expect(find.text('ORDERS TODAY'), findsOneWidget);

      // stf-03 is a Stock controller — no till access, so no block at all.
      container = await pumpAt(tester, const Size(1440, 900), '/staff/stf-03');
      await tester.pumpAndSettle();
      expect(
        container.read(staffPerformanceProvider('stf-03')).applies,
        isFalse,
      );
      expect(find.text('ORDERS TODAY'), findsNothing);
    });

    testWidgets('a pending invite shows no invented activity', (tester) async {
      await pumpAt(tester, const Size(1440, 900), '/staff/stf-04');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('has not been accepted'),
        findsOneWidget,
        reason: 'an account never signed into cannot have a history',
      );
    });
  });
}
