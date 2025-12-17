import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_printer_plus/flutter_printer_plus.dart' as printerPlus;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_image_generate_tool/print_image_generate_tool.dart';
import 'package:shop_staff/core/config/print_info.dart';
import 'package:shop_staff/l10n/app_localizations.dart';

import '../../../core/router/app_router.dart';
import '../../pos/viewmodels/pos_viewmodel.dart';
import '../viewmodels/entry_viewmodels.dart';
import '../../cash_machine/widgets/cash_machine_check_dialog.dart';

final _clockProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

class EntryPage extends ConsumerStatefulWidget {
  const EntryPage({super.key});

  @override
  ConsumerState<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends ConsumerState<EntryPage> {

  final printerController = printerPlus.PrinterJobController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(cashMachineCheckControllerProvider.notifier)
          .maybePromptOnEntry();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final now = ref
        .watch(_clockProvider)
        .maybeWhen(data: (value) => value, orElse: DateTime.now);
    final timeText = _formatTime(now);
    final dateText = _formatDate(now);

    return CashMachineDialogPortal(
      child: PrintImageGenerateWidget(
        onPictureGenerated: _onPictureGenerated,
        contentBuilder: (context) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      _buildTopBar(context, ref, timeText, dateText),
                      const SizedBox(height: 40),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 960),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  t.entryTitle,
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  t.entrySubtitle,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.72),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 36),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isNarrow = constraints.maxWidth < 720;
                                    final options = [
                                      _EntryOptionButton(
                                        title: t.entryDineInTitle,
                                        subtitle: t.entryDineInSubtitle,
                                        icon: Icons.restaurant_menu_rounded,
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF22D3EE),
                                            Color(0xFF6366F1),
                                          ],
                                        ),
                                        onTap: () =>
                                            _startOrder(ref, 'dine_in'),
                                      ),
                                      _EntryOptionButton(
                                        title: t.entryTakeoutTitle,
                                        subtitle: t.entryTakeoutSubtitle,
                                        icon: Icons.shopping_bag_rounded,
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFF97316),
                                            Color(0xFFF43F5E),
                                          ],
                                        ),
                                        onTap: () =>
                                            _startOrder(ref, 'take_out'),
                                      ),
                                    ];
                                    if (isNarrow) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          options[0],
                                          const SizedBox(height: 20),
                                          options[1],
                                        ],
                                      );
                                    }
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Expanded(child: options[0]),
                                        const SizedBox(width: 24),
                                        Expanded(child: options[1]),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    
  }

      //打印图层生成成功
  Future<void> _onPictureGenerated(PicGenerateResult imgData) async {
    //final imageBytes = imgdata.data;
      final printTask = imgData.taskItem;

    //指定的打印机
      final printerInfo = printTask.params as PrinterInfo;
      //print('printerInfo: $printerInfo');
      //打印票据类型（标签、小票）
      final printTypeEnum = printTask.printTypeEnum;

      final imageBytes =
          await imgData.convertUint8List(imageByteFormat: ImageByteFormat.rawRgba);
      //也可以使用 ImageByteFormat.png
      final argbWidth = imgData.imageWidth;
      final argbHeight = imgData.imageHeight;
      if (imageBytes == null) {
        return;
      }

      var printData = await printerPlus.PrinterCommandTool.generatePrintCmd(
        imgData: imageBytes,
        printType: printTypeEnum,
        argbWidthPx: argbWidth,
        argbHeightPx: argbHeight,
      );

      if (printerInfo.isUsbPrinter) {
        // usb 打印
        final conn = printerPlus.UsbConn(printerInfo.usbDevice!);
        conn.writeMultiBytes(printData, 1024 * 8);
      } else if (printerInfo.isNetPrinter) {
        // 网络 打印
        // final conn = printerPlus.NetConn(printerInfo.ip!);
        // conn.writeMultiBytes(printData);
        debugPrint('开始网络打印，IP：${printerInfo.ip}');

        try {
          await printerController.enqueue(printerInfo.ip!, printData, timeout: Duration(seconds: 12));
          // final conn = printerPlus.NetConn(printerInfo.ip!);
          // conn.writeMultiBytes(printData);
        } catch (e) {
          debugPrint('打印失败: $e');
          throw Exception('打印失败: $e');
        }
      }

      // // 网络 打印
      // final conn = printerPlus.NetConn(printerInfo.ip!);
      // conn.writeMultiBytes(printData);
    }

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    String timeText,
    String dateText,
  ) {
    final router = ref.read(appRouterProvider);
    final t = AppLocalizations.of(context);
    return Row(
      children: [
        FilledButton.icon(
          onPressed: () => router.push('/pos/suspended'),
          icon: const Icon(Icons.assignment_returned_outlined),
          label: Text(t.entryPickup),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dateText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => router.push('/settings'),
          icon: const Icon(Icons.settings_rounded),
          tooltip: t.entrySettingsTooltip,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }
}

class _EntryOptionButton extends StatelessWidget {
  const _EntryOptionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(26, 28, 26, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(height: 26),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              // Text(
              //   subtitle,
              //   style: theme.textTheme.bodyMedium?.copyWith(
              //     color: Colors.white.withValues(alpha: 0.82),
              //   ),
              // ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context).entryStartOrder,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _startOrder(WidgetRef ref, String mode) {
  ref.read(orderModeSelectionProvider.notifier).state = mode;
  ref.invalidate(posViewModelProvider);
  ref.read(appRouterProvider).push('/pos');
}

String _formatTime(DateTime now) {
  final h = now.hour.toString().padLeft(2, '0');
  final m = now.minute.toString().padLeft(2, '0');
  final s = now.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

String _formatDate(DateTime now) {
  final weekday = _weekdayLabel(now.weekday);
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}年$month月$day日 · $weekday';
}

String _weekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return '星期一';
    case DateTime.tuesday:
      return '星期二';
    case DateTime.wednesday:
      return '星期三';
    case DateTime.thursday:
      return '星期四';
    case DateTime.friday:
      return '星期五';
    case DateTime.saturday:
      return '星期六';
    case DateTime.sunday:
    default:
      return '星期日';
  }
}
