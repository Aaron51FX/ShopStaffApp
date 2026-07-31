import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/data/datasources/local/cash_register_closure_local_data_source.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/entities/cash_register_closure.dart';
import 'package:shop_staff/domain/repositories/cash_register_closure_repository.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/cash_register_closure/pages/cash_register_closure_page.dart';

void main() {
  testWidgets('email dialog is not dismissed by tapping the barrier', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cashRegisterClosureRepositoryProvider.overrideWithValue(
            _FakeCashRegisterClosureRepository(),
          ),
          cashRegisterClosureLocalDataSourceProvider.overrideWithValue(
            _FakeCashRegisterClosureLocalDataSource(),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: CashRegisterClosurePage(
            machineCode: 'MACHINE-1',
            shopName: 'Test Shop',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('获取最新收银结算'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('选择邮箱'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('选择邮箱'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('选择邮箱'), findsNothing);
  });
}

class _FakeCashRegisterClosureRepository
    implements CashRegisterClosureRepository {
  @override
  Future<List<CashRegisterClosureMailAccount>> fetchMailList({
    required String machineCode,
  }) async {
    return const [
      CashRegisterClosureMailAccount(
        verifyEmail: 'staff@example.com',
        verifyUserName: 'Staff',
      ),
    ];
  }

  @override
  Future<void> sendAdminVerify({
    required String machineCode,
    required String verifyEmail,
    required String verifyUserName,
  }) async {}

  @override
  Future<CashRegisterClosureSummary> fetchStaffRejishime(
    CashRegisterClosureVerifyInput input,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> confirm(CashRegisterClosureVerifyInput input) {
    throw UnimplementedError();
  }
}

class _FakeCashRegisterClosureLocalDataSource
    extends CashRegisterClosureLocalDataSource {
  @override
  Future<List<CashRegisterClosureHistoryRecord>> loadRecent({
    required Duration maxAge,
  }) async {
    return const [];
  }
}
