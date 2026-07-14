import 'package:flutter/foundation.dart';

enum CashMachineDialogStatus { hidden, checking, success, failure }

@immutable
class CashMachineDialogState {
  const CashMachineDialogState._(this.status, this.message);

  final CashMachineDialogStatus status;
  final String? message;

  const CashMachineDialogState.hidden()
    : this._(CashMachineDialogStatus.hidden, null);

  const CashMachineDialogState.checking([String? message])
    : this._(CashMachineDialogStatus.checking, message);

  const CashMachineDialogState.success([String? message])
    : this._(CashMachineDialogStatus.success, message);

  const CashMachineDialogState.failure([String? message])
    : this._(CashMachineDialogStatus.failure, message);

  @override
  bool operator ==(Object other) {
    return other is CashMachineDialogState &&
        other.status == status &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(status, message);
}

@immutable
class CashMachineCheckState {
  const CashMachineCheckState({
    this.isSupported = false,
    this.isEnabled = false,
    this.isChecking = false,
    this.dialog = const CashMachineDialogState.hidden(),
    this.lastError,
  });

  final bool isSupported;
  final bool isEnabled;
  final bool isChecking;
  final CashMachineDialogState dialog;
  final String? lastError;

  CashMachineCheckState copyWith({
    bool? isSupported,
    bool? isEnabled,
    bool? isChecking,
    CashMachineDialogState? dialog,
    String? lastError,
    bool clearError = false,
  }) {
    return CashMachineCheckState(
      isSupported: isSupported ?? this.isSupported,
      isEnabled: isEnabled ?? this.isEnabled,
      isChecking: isChecking ?? this.isChecking,
      dialog: dialog ?? this.dialog,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}
