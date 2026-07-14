import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class PosEffect {
  const PosEffect();
}

enum PosToastKey {
  peerSyncDisabled,
  peerNotConnected,
  pushedToCustomer,
  pushedConfigToCustomer,
  pushedOptionGroupToCustomer,
  cartEmptyCannotPush,
  cartSentToCustomer,
  clearedCustomerDisplay,
  localOrderSaveFailed,
  orderSubmitFailed,
  noPayableOrder,
}

class PosToastEffect extends PosEffect {
  const PosToastEffect({this.message, this.messageKey, this.isError = false});

  final String? message;
  final PosToastKey? messageKey;
  final bool isError;
}

class PosNavigateEffect extends PosEffect {
  const PosNavigateEffect({required this.location, this.extra});

  final String location;
  final Object? extra;
}

class PosPopToRootEffect extends PosEffect {
  const PosPopToRootEffect();
}

class PosRequestClearCartConfirmEffect extends PosEffect {
  const PosRequestClearCartConfirmEffect();
}

class PosRequestSuspendConfirmEffect extends PosEffect {
  const PosRequestSuspendConfirmEffect();
}

class PosEffectController {
  final StreamController<PosEffect> _controller =
      StreamController<PosEffect>.broadcast();

  Stream<PosEffect> get stream => _controller.stream;

  void emit(PosEffect effect) {
    if (!_controller.isClosed) _controller.add(effect);
  }

  void dispose() => _controller.close();
}

final posEffectControllerProvider = Provider<PosEffectController>((ref) {
  final controller = PosEffectController();
  ref.onDispose(controller.dispose);
  return controller;
});

final posEffectsProvider = StreamProvider.autoDispose<PosEffect>((ref) {
  return ref.watch(posEffectControllerProvider).stream;
});
