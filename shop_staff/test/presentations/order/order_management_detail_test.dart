import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shop_staff/domain/entities/managed_order.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/order/sections/order_management_detail.dart';

void main() {
  testWidgets('paid order shows four required actions', (tester) async {
    await tester.pumpWidget(_app(ManagedOrderStatus.paid));

    expect(find.text('Reorder'), findsOneWidget);
    expect(find.text('Print receipt'), findsOneWidget);
    expect(find.text('Print kitchen ticket'), findsOneWidget);
    expect(find.text('Cancel order'), findsOneWidget);
    expect(find.text('Change payment status'), findsNothing);
  });

  testWidgets('unpaid order shows kitchen, payment and cancel actions', (
    tester,
  ) async {
    await tester.pumpWidget(_app(ManagedOrderStatus.unpaid));

    expect(find.text('Print kitchen ticket'), findsOneWidget);
    expect(find.text('Change payment status'), findsOneWidget);
    expect(find.text('Cancel order'), findsOneWidget);
    expect(find.text('Reorder'), findsNothing);
    expect(find.text('Print receipt'), findsNothing);
  });

  testWidgets('canceled order shows kitchen and payment actions', (
    tester,
  ) async {
    await tester.pumpWidget(_app(ManagedOrderStatus.canceled));

    expect(find.text('Print kitchen ticket'), findsOneWidget);
    expect(find.text('Change payment status'), findsOneWidget);
    expect(find.text('Cancel order'), findsNothing);
    expect(find.text('Print receipt'), findsNothing);
  });
}

Widget _app(ManagedOrderStatus status) {
  final order = ManagedOrder(
    orderId: 'ORDER-1',
    status: status,
    createdAt: DateTime(2026, 8, 5, 12),
    price: 1200,
  );
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: OrderManagementDetail(
        detail: ManagedOrderDetail(order: order, lines: const []),
        loading: false,
        actionRunning: false,
        onClose: () {},
        onReorder: () {},
        onPrintReceipt: () {},
        onPrintKitchen: () {},
        onChangePayment: () {},
        onCancel: () {},
      ),
    ),
  );
}
