import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/l10n/app_localizations.dart';
import 'package:shop_staff/presentations/entry/widgets/entry_option_button.dart';
import 'package:shop_staff/presentations/entry/widgets/entry_option_grid.dart';

void main() {
  testWidgets('keeps one and two item widths and shrinks three items', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<List<double>> pumpGrid({
      required bool dineIn,
      required bool takeout,
      required bool settlement,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 960,
                child: EntryOptionGrid(
                  onDineIn: () {},
                  onTakeout: () {},
                  onSettlement: () {},
                  showDineIn: dineIn,
                  showTakeout: takeout,
                  showSettlement: settlement,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return tester
          .widgetList<EntryOptionButton>(find.byType(EntryOptionButton))
          .map((widget) => tester.getSize(find.byWidget(widget)).width)
          .toList();
    }

    final oneItemWidths = await pumpGrid(
      dineIn: true,
      takeout: false,
      settlement: false,
    );
    final twoItemWidths = await pumpGrid(
      dineIn: true,
      takeout: true,
      settlement: false,
    );
    final threeItemWidths = await pumpGrid(
      dineIn: true,
      takeout: true,
      settlement: true,
    );

    expect(oneItemWidths, everyElement(closeTo(468, 0.01)));
    expect(twoItemWidths, everyElement(closeTo(468, 0.01)));
    expect(threeItemWidths, everyElement(closeTo(304, 0.01)));
  });
}
