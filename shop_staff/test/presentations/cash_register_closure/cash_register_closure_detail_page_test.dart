import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/domain/entities/cash_register_closure.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/cash_register_closure/pages/cash_register_closure_detail_page.dart';

void main() {
  testWidgets('unconfirmed detail does not show the print action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        CashRegisterClosureDetailPage(
          machineCode: 'MACHINE-1',
          shopName: 'Test Shop',
          summary: _summary,
          input: _input,
          isHistory: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.print_rounded), findsNothing);
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
  });

  testWidgets('confirmed history detail shows the print action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        CashRegisterClosureDetailPage(
          machineCode: 'MACHINE-1',
          shopName: 'Test Shop',
          summary: _summary,
          isHistory: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.print_rounded), findsOneWidget);
    expect(find.byIcon(Icons.verified_rounded), findsNothing);
  });
}

Widget _testApp(Widget home) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    ),
  );
}

final _summary = CashRegisterClosureSummary.fromJson({
  'machineCode': 'MACHINE-1',
  'shopCode': 'SHOP-1',
  'shopName': 'Test Shop',
  'startTime': '2026-07-31 09:00',
  'endTime': '2026-07-31 18:00',
  'total': 1000,
  'cashTotal': 1000,
});

const _input = CashRegisterClosureVerifyInput(
  machineCode: 'MACHINE-1',
  verifyCode: '123456',
  verifyEmail: 'staff@example.com',
  verifyUserName: 'Staff',
);
