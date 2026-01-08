import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/domain/repositories/print_repository.dart';
import 'package:shop_staff/domain/services/print_service.dart';
import 'print_job_models.dart';

final printJobViewModelProvider = StateNotifierProvider.autoDispose
    .family<PrintJobViewModel, PrintProgressState, PrintJobRequest>((ref, req) {
  final link = ref.keepAlive();
  ref.onDispose(link.close);
  return PrintJobViewModel(
    ref: ref,
    request: req,
    repository: ref.read(printRepositoryProvider),
    service: ref.read(printServiceProvider),
  );
});

class PrintJobViewModel extends StateNotifier<PrintProgressState> {
  PrintJobViewModel({
    required this.ref,
    required this.request,
    required PrintRepository repository,
    required PrintService service,
  })  : _repository = repository,
        _service = service,
        _logger = Logger('PrintJobViewModel'),
        super(const PrintProgressState());

  final Ref ref;
  final PrintJobRequest request;
  final PrintRepository _repository;
  final PrintService _service;
  final Logger _logger;

  bool _running = false;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    final activePrinters = request.printers.where((p) => p.isOn).toList();
    if (mounted) {
      state = state.copyWith(stage: '获取打印内容…', jobs: const [], error: null, completed: false);
    }

    if (request.machineCode.isEmpty) {
      _logger.warning('Missing machine code');
      if (mounted) {
        state = state.copyWith(error: '缺少机号，无法打印', completed: true);
      }
      _running = false;
      return;
    }
    if (activePrinters.isEmpty) {
      _logger.info('No active printers');
      if (mounted) {
        state = state.copyWith(error: '未开启任何打印机', completed: true);
      }
      _running = false;
      return;
    }

    try {
      final doc = await _resolveDocument();
      if (!mounted) {
        _running = false;
        return;
      }
      state = state.copyWith(stage: '生成打印任务…');
      debugPrint('Generating print jobs for ${activePrinters.length} printers');
      _logger.info('Generating print jobs for ${activePrinters.length} printers');
      final results = await _service.enqueuePrintJobs(
        document: doc,
        printers: activePrinters,
      );
      final updatedJobs = results
          .map(
            (r) => PrintJobStateItem(
              name: r.printer.name,
              status: r.isSuccess ? PrintJobStatus.success : PrintJobStatus.failure,
              error: r.error,
            ),
          )
          .toList(growable: false);

      if (mounted) {
        state = state.copyWith(
          stage: updatedJobs.any((j) => j.status == PrintJobStatus.failure)
              ? '部分打印失败'
              : (updatedJobs.isEmpty ? '未生成打印任务' : '打印任务已发送'),
          jobs: updatedJobs,
          error: updatedJobs.isEmpty ? '未生成打印任务' : null,
          completed: true,
        );
      }
    } catch (e, stack) {
      debugPrint('Print failed: $e');
      _logger.warning('Print failed', e, stack);
      if (mounted) {
        state = state.copyWith(error: '打印失败: $e', completed: true);
      }
    } finally {
      _running = false;
    }
  }

  Future<void> retry() async {
    _running = false; // allow restart
    await start();
  }

  Future<PrintInfoDocument> _resolveDocument() async {
    if (request.document != null) return request.document!;
    if (request.orderId == null || request.payAmount == null || request.printType == null) {
      throw StateError('缺少打印参数');
    }
    return _repository.printInfo(
      orderId: request.orderId!,
      machineCode: request.machineCode,
      payAmount: request.payAmount!,
      printType: request.printType!,
    );
  }
}