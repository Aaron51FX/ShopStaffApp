import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/data/models/shop_info_models.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/entities/settlement_order.dart';
import 'package:shop_staff/domain/repositories/settlement_order_repository.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/settlement/pages/settlement_order_page.dart';
import 'package:shop_staff/presentations/settlement/providers/settlement_order_providers.dart';
import 'package:shop_staff/presentations/shared/widgets/code_scan_dialog.dart';

void main() {
  testWidgets('hides hardware scanner input by default', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CodeScanDialog(
            title: 'Scan',
            cameraHint: 'Camera hint',
            cameraUnavailableHint: 'Camera unavailable',
            inputHint: 'Input',
            cancelLabel: 'Cancel',
            submitLabel: 'Submit',
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Submit'), findsNothing);
    expect(find.text('Camera unavailable'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('scans a link and renders wide and narrow order details', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      tester.binding.setSurfaceSize(null);
    });
    final repository = _PageSettlementOrderRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settlementOrderRepositoryProvider.overrideWithValue(repository),
          machineCodeProvider.overrideWithValue('machine-1'),
          shopLanguageProvider.overrideWithValue('JP'),
          shopInfoProvider.overrideWith(
            (_) => const ShopInfoModel(
              shopCode: 'shop-1',
              shopName: 'Shop',
              language: 'JP',
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettlementOrderPage(hardwareInputEnabled: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'https://sit-mobile.smartwe.jp/index?p=order-key',
    );
    await tester.tap(find.text('获取订单'));
    await tester.pumpAndSettle();

    expect(find.text('订单详情'), findsOneWidget);
    expect(find.text('お席番号：Ｄ１'), findsOneWidget);
    expect(find.text('甘蘭牛肉麺'), findsOneWidget);
    expect(find.text('セットメニュー · 牛串焼 ×1'), findsOneWidget);
    expect(find.text('¥3,147'), findsWidgets);
    expect(find.text('去支付'), findsOneWidget);
    expect(tester.takeException(), isNull);

    repository.confirmedTotal = 3000;
    await tester.tap(find.text('去支付'));
    await tester.pumpAndSettle();

    expect(repository.confirmCallCount, 1);
    expect(find.text('订单金额已更新，请重新扫码确认后再支付'), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(700, 900));
    await tester.pumpAndSettle();

    expect(find.text('订单详情'), findsOneWidget);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}

class _PageSettlementOrderRepository implements SettlementOrderRepository {
  int confirmedTotal = 3147;
  int confirmCallCount = 0;

  @override
  Future<int> confirmOrderTotal(String orderId) async {
    confirmCallCount++;
    return confirmedTotal;
  }

  @override
  Future<SettlementOrder> fetchOrder({
    required String orderKey,
    required String language,
    required String machineCode,
  }) async {
    return const SettlementOrder(
      orderId: '465512639757484032',
      totalPrice: 3147,
      discount: 0,
      voucherAmount: 0,
      payableAmount: 3147,
      tableNum: 'Ｄ１',
      tableNumText: 'お席番号：',
      orderQty: 1,
      tax1: 237,
      tax2: 40,
      lines: [
        SettlementOrderLine(
          categoryName: null,
          name: '甘蘭牛肉麺',
          initialPrice: null,
          price: 110,
          qty: 1,
          options: {
            'セットメニュー': [
              SettlementOrderOption(
                name: '牛串焼',
                price: 10,
                qty: 1,
                totalPrice: null,
              ),
            ],
          },
        ),
      ],
    );
  }
}
