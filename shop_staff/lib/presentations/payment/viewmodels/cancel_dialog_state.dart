
enum CancelDialogStatus { hidden, loading, success, failure }

class CancelDialogState {
  const CancelDialogState._(this.status, this.message);

  final CancelDialogStatus status;
  final String? message;

  bool get isVisible => status != CancelDialogStatus.hidden;
  bool get isTerminal =>
      status == CancelDialogStatus.success || status == CancelDialogStatus.failure;

  const CancelDialogState.hidden() : this._(CancelDialogStatus.hidden, null);

  factory CancelDialogState.loading(String? message) {
    return CancelDialogState._(CancelDialogStatus.loading, message);
  }

  factory CancelDialogState.success(String? message) {
    return CancelDialogState._(CancelDialogStatus.success, message);
  }

  factory CancelDialogState.failure(String? message) {
    return CancelDialogState._(CancelDialogStatus.failure, message);
  }
}