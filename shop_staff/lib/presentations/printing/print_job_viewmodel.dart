import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/data/models/print_info.dart';
import 'package:shop_staff/domain/repositories/print_repository.dart';
import 'package:shop_staff/domain/services/print_service.dart';
import 'print_job_models.dart';

final printJobViewModelProvider = StateNotifierProvider.autoDispose
    .family<PrintJobViewModel, PrintProgressState, PrintJobRequest>((ref, req) {
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
    final jobs = activePrinters
        .map((p) => PrintJobStateItem(name: p.name))
        .toList(growable: true);
    state = state.copyWith(stage: '拉取打印内容…', jobs: jobs, error: null, completed: false);

    if (request.machineCode.isEmpty) {
      state = state.copyWith(error: '缺少机号，无法打印', completed: true);
      _running = false;
      return;
    }
    if (activePrinters.isEmpty) {
      state = state.copyWith(error: '未开启任何打印机', completed: true);
      _running = false;
      return;
    }

    try {
      final doc = await _resolveDocument();
      state = state.copyWith(stage: '生成打印任务…');
      final results = await _service.enqueuePrintJobs(
        document: doc,
        printers: activePrinters,
      );

      final updatedJobs = <PrintJobStateItem>[];
      for (var i = 0; i < jobs.length; i++) {
        final printer = activePrinters[i];
        final match = results.firstWhere(
          (r) => r.printer.name == printer.name,
          orElse: () => PrintJobResult(printer: printer, error: '未生成任务'),
        );
        updatedJobs.add(
          jobs[i].copyWith(
            status: match.isSuccess ? PrintJobStatus.success : PrintJobStatus.failure,
            error: match.error,
          ),
        );
      }

      state = state.copyWith(
        stage: updatedJobs.any((j) => j.status == PrintJobStatus.failure)
            ? '部分打印失败'
            : '打印任务已发送',
        jobs: updatedJobs,
        completed: true,
      );
    } catch (e, stack) {
      _logger.warning('Print failed', e, stack);
      state = state.copyWith(error: '打印失败: $e', completed: true);
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
    if (request.orderId == null || request.payAmount == null || request.rprintType == null) {
      throw StateError('缺少打印参数');
    }
    return _repository.printInfo(
      orderId: request.orderId!,
      machineCode: request.machineCode,
      payAmount: request.payAmount!,
      rprintType: request.rprintType!,
    );
  }
}