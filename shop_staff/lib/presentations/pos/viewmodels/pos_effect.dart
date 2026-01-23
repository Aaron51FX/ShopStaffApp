import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pos_viewmodel.dart';

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

final posEffectsProvider = StreamProvider.autoDispose<PosEffect>((ref) {
  final vm = ref.watch(posViewModelProvider.notifier);
  return vm.effects;
});
