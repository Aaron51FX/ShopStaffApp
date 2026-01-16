import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/data/datasources/local/local_order_local_data_source.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/entities/local_order_record.dart';
import 'package:shop_staff/domain/repositories/print_repository.dart';
import 'package:shop_staff/domain/services/print_service.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

final orderReprintUseCaseProvider = Provider<OrderReprintUseCase>((ref) {
  return OrderReprintUseCase(
    machineCode: () => ref.read(machineCodeProvider) ?? '',
    printers: () => ref.read(appSettingsSnapshotProvider)?.printers ?? const [],
    local: ref.read(localOrderLocalDataSourceProvider),
    repo: ref.read(printRepositoryProvider),
    service: ref.read(printServiceProvider),
    logger: Logger('OrderReprintUseCase'),
  );
});

typedef _MachineCodeGetter = String Function();
typedef _PrintersGetter = List<PrinterSettings> Function();

enum ReprintTarget {
  receipt,
  kitchenTickets,
}

class OrderReprintResult {
  const OrderReprintResult({
    required this.success,
    required this.message,
    this.jobs = const [],
  });

  final bool success;
  final String message;
  final List<PrintJobResult> jobs;

  List<String> get printerNames => jobs.map((e) => e.printer.name).where((e) => e.isNotEmpty).toList();
}

class OrderReprintUseCase {
  OrderReprintUseCase({
    required _MachineCodeGetter machineCode,
    required _PrintersGetter printers,
    required LocalOrderLocalDataSource local,
    required PrintRepository repo,
    required PrintService service,
    Logger? logger,
  })  : _machineCode = machineCode,
        _printers = printers,
        _local = local,
        _repo = repo,
        _service = service,
        _logger = logger ?? Logger('OrderReprintUseCase');

  final _MachineCodeGetter _machineCode;
  final _PrintersGetter _printers;
  final LocalOrderLocalDataSource _local;
  final PrintRepository _repo;
  final PrintService _service;
  final Logger _logger;

  Future<OrderReprintResult> reprintReceipt(LocalOrderRecord order) {
    return _reprint(order: order, target: ReprintTarget.receipt);
  }

  Future<OrderReprintResult> reprintKitchenTickets(LocalOrderRecord order) {
    return _reprint(order: order, target: ReprintTarget.kitchenTickets);
  }

  Future<OrderReprintResult> _reprint({
    required LocalOrderRecord order,
    required ReprintTarget target,
  }) async {
    final machineCode = _machineCode();
    final printers = _printers();

    if (machineCode.isEmpty) {
      return const OrderReprintResult(success: false, message: '缺少机号，无法打印');
    }
    if (printers.isEmpty) {
      return const OrderReprintResult(success: false, message: '未配置打印机');
    }

    final printType = _resolvePrintType(printers);

    try {
      _logger.fine('Reprint orderId=${order.orderId} target=$target');

      final doc = await _repo.printInfo(
        orderId: order.orderId,
        machineCode: machineCode,
        payAmount: order.clientTotal.toInt().toString(),
        printType: printType,
      );

      // Best-effort: refresh stored payment method from the resolved document.
      try {
        final method = _extractPayMethod(doc);
        if (method.isNotEmpty) {
          await _local.updatePayMethod(order.orderId, method, isPaid: method != '現金支払');
        }
      } catch (_) {
        // ignore
      }

      final jobs = await _enqueue(target: target, document: doc, printers: printers);
      if (jobs.isEmpty) {
        return const OrderReprintResult(success: false, message: '未生成打印任务');
      }

      final names = jobs.map((e) => e.printer.name).where((e) => e.isNotEmpty).join('、');
      return OrderReprintResult(success: true, message: '已发送打印任务: $names', jobs: jobs);
    } catch (e) {
      return OrderReprintResult(success: false, message: '打印失败: $e');
    }
  }

  Future<List<PrintJobResult>> _enqueue({
    required ReprintTarget target,
    required PrintInfoDocument document,
    required List<PrinterSettings> printers,
  }) {
    switch (target) {
      case ReprintTarget.receipt:
        return _service.enqueueReceiptJobs(document: document, printers: printers);
      case ReprintTarget.kitchenTickets:
        return _service.enqueueKitchenJobs(document: document, printers: printers);
    }
  }

  String _resolvePrintType(List<PrinterSettings> printers) {
    final labelPrinter = printers.firstWhere(
      (p) => p.type == 10 && p.isOn && (p.printIp?.isNotEmpty ?? false) && p.receipt == false,
      orElse: () => const PrinterSettings(name: '', type: -1),
    );
    return labelPrinter.type == 10 ? 'Label' : '';
  }

  String _extractPayMethod(PrintInfoDocument doc) {
    final payMethod = doc.payMethod.trim();
    if (payMethod.isNotEmpty) return payMethod;

    return '';
  }
}
