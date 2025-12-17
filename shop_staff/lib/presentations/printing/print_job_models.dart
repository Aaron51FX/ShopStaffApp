import 'package:shop_staff/domain/settings/app_settings_models.dart';
import 'package:shop_staff/data/models/print_info.dart';

class PrintJobRequest {
  const PrintJobRequest({
    required this.machineCode,
    required this.printers,
    this.orderId,
    this.payAmount,
    this.printType,
    this.document,
  });

  final String machineCode;
  final List<PrinterSettings> printers;
  final String? orderId;
  final String? payAmount;
  final String? printType;
  final PrintInfoDocument? document;

  bool get hasDocument => document != null;
}

class PrintJobStateItem {
  const PrintJobStateItem({required this.name, this.status = PrintJobStatus.pending, this.error});

  final String name;
  final PrintJobStatus status;
  final String? error;

  PrintJobStateItem copyWith({PrintJobStatus? status, String? error}) {
    return PrintJobStateItem(
      name: name,
      status: status ?? this.status,
      error: error,
    );
  }
}

enum PrintJobStatus { pending, running, success, failure }

class PrintProgressState {
  const PrintProgressState({
    this.stage = '准备打印…',
    this.jobs = const <PrintJobStateItem>[],
    this.error,
    this.completed = false,
  });

  final String stage;
  final List<PrintJobStateItem> jobs;
  final String? error;
  final bool completed;

  bool get hasFailure => jobs.any((j) => j.status == PrintJobStatus.failure);

  PrintProgressState copyWith({
    String? stage,
    List<PrintJobStateItem>? jobs,
    String? error,
    bool? completed,
  }) {
    return PrintProgressState(
      stage: stage ?? this.stage,
      jobs: jobs ?? this.jobs,
      error: error,
      completed: completed ?? this.completed,
    );
  }
}