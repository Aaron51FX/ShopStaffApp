
enum CancelDialogStatus { hidden, loading, success, failure }

class CancelDialogState {
  const CancelDialogState._(this.status, this.message, this.requiresRecovery);

  final CancelDialogStatus status;
  final String? message;
  final bool requiresRecovery;

  bool get isVisible => status != CancelDialogStatus.hidden;
  bool get isTerminal =>
      status == CancelDialogStatus.success || status == CancelDialogStatus.failure;

  const CancelDialogState.hidden() : this._(CancelDialogStatus.hidden, null, false);

  factory CancelDialogState.loading(String? message) {
    return CancelDialogState._(CancelDialogStatus.loading, message, false);
  }

  factory CancelDialogState.success(String? message) {
    return CancelDialogState._(CancelDialogStatus.success, message, false);
  }

  factory CancelDialogState.failure(String? message, {bool requiresRecovery = false}) {
    return CancelDialogState._(CancelDialogStatus.failure, message, requiresRecovery);
  }
}