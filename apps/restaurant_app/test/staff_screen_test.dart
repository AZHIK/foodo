import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurant_pos/data/mock_staff.dart';
import 'package:restaurant_pos/main.dart';
import 'package:restaurant_pos/models/permission.dart';
import 'package:restaurant_pos/models/staff_member.dart';
import 'package:restaurant_pos/providers/roles_provider.dart';
import 'package:restaurant_pos/providers/staff_provider.dart';
import 'package:restaurant_pos/router/app_router.dart';
import 'package:restaurant_pos/widgets/data_page/summary_metric_card.dart';

const _widths = <double>[360, 400, 768, 1024, 1440, 1920];

Future<ProviderContainer> pumpAt(
  WidgetTester tester,
  Size size,
  String route,
) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.reset);

  final container = ProviderContainer();
  addTearDown(container.dispose);

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
      expect(summary.total, MockStaff.members.length);
    });

    testWidgets('inviting adds a pending member to the shared provider', (
      tester,
    ) async {
      final container = await pumpAt(tester, const Size(1440, 900), '/staff');
      final before = container.read(staffMembersProvider).length;

      await tester.tap(find.text('Invite staff'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'e.g. Tomas Alvarez'),
        'Casey Nkemdirim',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'name@example.com'),
        'casey@example.com',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Select a role'));
      await tester.tap(find.byType(DropdownButton).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cashier'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Send invite'));
      await tester.pumpAndSettle();

      final members = container.read(staffMembersProvider);
      expect(members, hasLength(before + 1));

      final added = members.firstWhere((m) => m.email == 'casey@example.com');
      expect(added.status, StaffStatus.pendingInvite);
      expect(added.roleId, MockStaff.cashierRoleId);
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

      final before = container
          .read(roleByIdProvider(MockStaff.cashierRoleId))!
          .permissionCount;

      // Row tap opens the form in edit mode.
      await tester.tap(find.text('Cashier'));
      await tester.pumpAndSettle();

      // Grant everything in the Point of Sale group via its bulk action.
      await tester.tap(find.widgetWithText(TextButton, 'All').first);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save role'));
      await tester.pumpAndSettle();

      final after = container.read(roleByIdProvider(MockStaff.cashierRoleId))!;
      expect(after.permissionCount, greaterThan(before));
      expect(after.has(AppPermissions.posRefund), isTrue);
    });

    testWidgets('system roles cannot be deleted', (tester) async {
      final container = await pumpAt(
        tester,
        const Size(1440, 900),
        '/staff/roles',
      );

      final owner = container.read(roleByIdProvider(MockStaff.ownerRoleId))!;
      expect(owner.isSystem, isTrue);

      final before = container.read(rolesProvider).length;
      container.read(rolesProvider.notifier).delete(owner.id);
      expect(
        container.read(rolesProvider),
        hasLength(before),
        reason: 'a system role must survive a delete call',
      );
    });

    testWidgets('duplicating a role gives it a distinct name', (tester) async {
      final container = await pumpAt(
        tester,
        const Size(1440, 900),
        '/staff/roles',
      );

      final copy = container
          .read(rolesProvider.notifier)
          .duplicate(MockStaff.managerRoleId);

      expect(copy.isSystem, isFalse);
      expect(copy.name, isNot('Manager'));
      expect(
        container.read(rolesProvider).where((r) => r.name == copy.name),
        hasLength(1),
      );
    });
  });

  group('Staff detail', () {
    testWidgets('no overflow at any target width', (tester) async {
      for (final width in _widths) {
        await pumpAt(tester, Size(width, 900), '/staff/stf-04');
        expect(
          tester.takeException(),
          isNull,
          reason: 'staff detail broke at ${width}px',
        );
      }
    });

    testWidgets('performance block follows the role\'s POS permission', (
      tester,
    ) async {
      // stf-04 is a Cashier — has till access.
      var container = await pumpAt(
        tester,
        const Size(1440, 900),
        '/staff/stf-04',
      );
      expect(container.read(staffPerformanceProvider('stf-04')).applies, isTrue);
      // SummaryMetricCard uppercases its label.
      expect(find.text('ORDERS TODAY'), findsOneWidget);

      // stf-08 is a Stock controller — no till access, so no block at all.
      container = await pumpAt(tester, const Size(1440, 900), '/staff/stf-08');
      expect(
        container.read(staffPerformanceProvider('stf-08')).applies,
        isFalse,
      );
      expect(find.text('ORDERS TODAY'), findsNothing);
    });

    testWidgets('a pending invite shows no invented activity', (tester) async {
      await pumpAt(tester, const Size(1440, 900), '/staff/stf-09');

      expect(
        find.textContaining('has not been accepted'),
        findsOneWidget,
        reason: 'an account never signed into cannot have a history',
      );
    });
  });
}
