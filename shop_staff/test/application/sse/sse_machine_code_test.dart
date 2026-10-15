import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_staff/application/sse/sse_runtime.dart';
import 'package:shop_staff/data/providers.dart';
import 'package:shop_staff/domain/settings/app_settings_models.dart';

void main() {
  test(
    'SSE uses activation machine code even when basic settings have none',
    () {
      final container = ProviderContainer(
        overrides: [machineCodeProvider.overrideWithValue(' activated ')],
      );
      addTearDown(container.dispose);
      expect(container.read(sseMachineCodeProvider), 'activated');
    },
  );
  test(
    'SSE falls back to basic settings when activation code is unavailable',
    () {
      final container = ProviderContainer(
        overrides: [
          appSettingsSnapshotProvider.overrideWith(
            (_) => const AppSettingsSnapshot(
              basic: BasicSettings(machineCode: 'basic'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(sseMachineCodeProvider), 'basic');
    },
  );
}
