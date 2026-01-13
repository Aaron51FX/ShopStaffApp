import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_staff/core/dialog/dialog_service.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/domain/entities/cart_item.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/presentations/pos/widgets/option_dialog_widgets.dart';
import 'package:shop_staff/presentations/pos/widgets/primary_button.dart';

typedef OptionSelectionMap = Map<String, Map<String, int>>;

typedef BuildSelectedOptions = List<SelectedOption> Function(OptionSelectionMap selected);

typedef ValidateMissingGroups = List<String> Function(OptionSelectionMap selected);

typedef SendAllOptions = FutureOr<void> Function(List<SelectedOption> options);

typedef SendGroupOptions = FutureOr<void> Function(OptionGroupEntity group, Map<String, int> selected);

Future<void> showProductOptionDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Product product,
  required CartItem? existing,
  required bool peerLinkEnabled,
  required OptionSelectionMap initialSelected,
  required BuildSelectedOptions buildSelectedOptions,
  required ValidateMissingGroups validateMissingGroups,
  required void Function(List<SelectedOption> options) onConfirmed,
  SendAllOptions? onSendAll,
  SendGroupOptions? onSendGroup,
}) async {
  final OptionSelectionMap selected = {
    for (final entry in initialSelected.entries) entry.key: Map<String, int>.from(entry.value),
  };

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'options',
    barrierColor: Colors.black.withAlpha(115),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: Center(
            child: StatefulBuilder(
              builder: (ctx, setState) {
                final size = MediaQuery.of(ctx).size;
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: size.width * 0.8,
                    maxHeight: size.height * 0.9,
                  ),
                  child: Material(
                    color: Colors.white,
                    elevation: 12,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.amberPrimary,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (peerLinkEnabled && onSendAll != null)
                                IconButton(
                                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                                  onPressed: () {
                                    final options = buildSelectedOptions(selected);
                                    onSendAll(options);
                                  },
                                  tooltip: '发送当前选项到顾客端',
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                            ],
                          ),
                        ),
                        // Body
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            children: [
                              for (final group in product.optionGroups) ...[
                                OptionGroupWidget(
                                  group: group,
                                  selected: selected[group.groupCode] ?? const {},
                                  onChanged: (map) {
                                    setState(() {
                                      if (map.isEmpty) {
                                        selected.remove(group.groupCode);
                                      } else {
                                        selected[group.groupCode] = map;
                                      }
                                    });
                                  },
                                  onMaxReached: () {
                                    ref.read(dialogControllerProvider.notifier).confirm(
                                          title: '已达到最大可选',
                                          message: '${group.groupName} 已达到最多可选数量',
                                          okText: '知道了',
                                          cancelText: '关闭',
                                        );
                                  },
                                  onSendGroup: (peerLinkEnabled && onSendGroup != null)
                                      ? (g, selections) {
                                          onSendGroup(g, selections);
                                        }
                                      : null,
                                ),
                                const Divider(height: 28),
                              ],
                            ],
                          ),
                        ),
                        // Footer
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          decoration: const BoxDecoration(
                            color: AppColors.stone100,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: PrimaryButton(
                                  label: existing == null ? '确认添加' : '更新',
                                  onTap: () {
                                    final missing = validateMissingGroups(selected);
                                    if (missing.isNotEmpty) {
                                      ref.read(dialogControllerProvider.notifier).confirm(
                                            title: '缺少必选项',
                                            message: missing.join('\n'),
                                            okText: '好的',
                                            cancelText: '关闭',
                                          );
                                      return;
                                    }
                                    final options = buildSelectedOptions(selected);
                                    onConfirmed(options);
                                    Navigator.of(ctx).pop();
                                  },
                                  color: AppColors.amberPrimary,
                                  textColor: Colors.white,
                                  height: 48,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}
