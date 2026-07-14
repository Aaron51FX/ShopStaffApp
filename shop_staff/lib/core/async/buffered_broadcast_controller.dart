import 'dart:async';

/// Broadcast controller that preserves events emitted while no listener is
/// attached. Buffered events are delivered to the next listener before live
/// events continue.
class BufferedBroadcastController<T> {
  BufferedBroadcastController() {
    _stream = Stream<T>.multi(_attach, isBroadcast: true);
  }

  final StreamController<T> _liveController = StreamController<T>.broadcast();
  final List<T> _pending = <T>[];
  late final Stream<T> _stream;
  int _listenerCount = 0;

  Stream<T> get stream => _stream;
  bool get isClosed => _liveController.isClosed;

  void add(T event) {
    if (isClosed) {
      throw StateError('Cannot add event after closing the controller');
    }
    if (_listenerCount == 0) {
      _pending.add(event);
      return;
    }
    _liveController.add(event);
  }

  Future<void> close() => _liveController.close();

  void _attach(MultiStreamController<T> target) {
    _listenerCount += 1;
    final buffered = _listenerCount == 1 ? List<T>.from(_pending) : <T>[];
    if (_listenerCount == 1) {
      _pending.clear();
    }

    final subscription = _liveController.stream.listen(
      target.addSync,
      onError: target.addErrorSync,
      onDone: target.closeSync,
    );
    for (final event in buffered) {
      target.addSync(event);
    }

    target.onCancel = () async {
      _listenerCount -= 1;
      await subscription.cancel();
    };
  }
}
