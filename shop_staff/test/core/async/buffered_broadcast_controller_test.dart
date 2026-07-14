import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/core/async/buffered_broadcast_controller.dart';

void main() {
  test('replays events emitted before the first listener', () async {
    final controller = BufferedBroadcastController<int>();
    controller.add(1);
    controller.add(2);

    final values = await controller.stream.take(2).toList();
    await controller.close();

    expect(values, [1, 2]);
  });

  test('closing before listen preserves pending events and done', () async {
    final controller = BufferedBroadcastController<int>();
    controller.add(7);
    final closeFuture = controller.close();

    expect(await controller.stream.toList(), [7]);
    await closeFuture;
  });
}
