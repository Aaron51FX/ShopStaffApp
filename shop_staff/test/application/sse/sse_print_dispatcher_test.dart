import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:print_image_generate_tool/print_image_generate_tool.dart';
import 'package:shop_staff/application/sse/sse_print_dispatcher.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/domain/services/receipt_renderer.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

class _Ticket extends StatelessWidget with ATempWidget {
  const _Ticket();
  @override
  int get pixelPagerWidth => 300;
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _Renderer implements ReceiptRenderer {
  final documents = <PrintInfoDocument>[];
  @override
  List<ATempWidget> buildLabels({
    required PrintInfoDocument document,
    required PrinterSettings printer,
    required bool rotate,
  }) {
    documents.add(document);
    return [const _Ticket()];
  }

  @override
  ATempWidget? buildLabelHead({
    required PrintInfoDocument document,
    required PrinterSettings printer,
    required bool rotate,
  }) => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => const _Ticket();
}

void main() {
  Map<String, dynamic> payload() => {
    'uuid': 'test',
    'order_type': 'Shop_In',
    'order_sn_code': 'A1',
    'orderLinesMap': {
      '10': [
        {'name': 'tea', 'qty': 2},
      ],
      '12': [
        {'name': 'coffee', 'qty': 1},
      ],
    },
  };
  const printers = [
    PrinterSettings(
      name: 'one',
      type: 10,
      receipt: false,
      labelSize: '300x225',
      printIp: '192.168.1.10',
      isOn: true,
    ),
    PrinterSettings(
      name: 'two',
      type: 12,
      receipt: false,
      labelSize: '450x300',
      printIp: '192.168.1.12',
      isOn: true,
    ),
  ];

  test('label documents contain only the target printer lines', () {
    final renderer = _Renderer();
    final tasks = SsePrintDispatcher(
      renderer,
    ).prepare('message', payload(), printers);
    expect(tasks.map((e) => e.printer.type), [10, 12]);
    expect(renderer.documents[0].printInfo!.orderLinesMap.keys, ['10']);
    expect(renderer.documents[1].printInfo!.orderLinesMap.keys, ['12']);
    expect(renderer.documents[0].printInfo!.orderLines.single.qty, 2);
  });

  test('missing route and missing label size fail before server claim', () {
    final dispatcher = SsePrintDispatcher(_Renderer());
    expect(
      () => dispatcher.prepare('message', payload(), printers.take(1).toList()),
      throwsStateError,
    );
    expect(
      () => dispatcher.prepare('message', payload(), [
        printers[0].copyWith(labelSize: ''),
        printers[1],
      ]),
      throwsStateError,
    );
  });

  test('seat option gates printing; expiry requires label mode', () {
    final dispatcher = SsePrintDispatcher(_Renderer());
    expect(
      dispatcher.prepare('print', {'uuid': 'x'}, [], seat: false),
      isEmpty,
    );
    expect(
      () => dispatcher.prepare('print', {'uuid': 'x'}, [], seat: true),
      throwsStateError,
    );
    expect(
      () => dispatcher.prepare(
        'expiryPrint',
        {'uuid': 'x'},
        [printers.first.copyWith(receipt: true)],
      ),
      throwsStateError,
    );
    final tasks = dispatcher.prepare('expiryPrint', {
      'uuid': 'x',
      'name': 'bread',
    }, printers);
    expect(tasks.single.type, PrintTypeEnum.label);
    expect(tasks.single.widget.pixelPagerWidth, 300);
    expect(tasks.single.widget.pixelPagerHeight, 225);
  });

  test('unsupported events cannot accidentally become orders', () {
    expect(
      () => SsePrintDispatcher(
        _Renderer(),
      ).prepare('payment_Completed', payload(), printers),
      throwsUnsupportedError,
    );
  });
}
