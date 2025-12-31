import 'package:flutter/material.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/core/ui/app_colors.dart';

class OptionGroupWidget extends StatefulWidget {
  final OptionGroupEntity group;
  final Map<String, int> selected; // optionCode -> quantity
  final ValueChanged<Map<String, int>> onChanged;
  final VoidCallback? onMaxReached; // 当尝试超过最大可选时触发
  final void Function(OptionGroupEntity group, Map<String, int> selected)? onSendGroup;
  const OptionGroupWidget({super.key, required this.group, required this.selected, required this.onChanged, this.onMaxReached, this.onSendGroup});
  @override
  State<OptionGroupWidget> createState() => _OptionGroupWidgetState();
}

class _OptionGroupWidgetState extends State<OptionGroupWidget> {
  late Map<String, int> _local;
  @override
  void initState() {
    super.initState();
    _local = Map<String, int>.from(widget.selected);
  }

  int _currentTotal() => _local.values.fold(0, (p, e) => p + e);

  bool _canAddAnother() {
    if (!widget.group.multiple) return false;
    final max = widget.group.maxSelect;
    if (max == null) return true;
    return _currentTotal() < max;
  }

  void _toggleSingle(String code) {
    if (_local.containsKey(code)) {
      _local.clear();
    } else {
      _local.clear();
      _local[code] = 1;
    }
    _notify();
  }

  void _toggleMulti(String code) {
    if (_local.containsKey(code)) {
      _local.remove(code);
    } else {
      if (!_canAddAnother()) {
        widget.onMaxReached?.call();
        return;
      }
      _local[code] = 1;
    }
    _notify();
  }

  void _incQty(String code) {
    if (!_canAddAnother()) {
      widget.onMaxReached?.call();
      return;
    }
    _local.update(code, (v) => v + 1, ifAbsent: () => 1);
    _notify();
  }

  void _decQty(String code) {
    if (!_local.containsKey(code)) return;
    final v = _local[code]! - 1;
    if (v <= 0) {
      _local.remove(code);
    } else {
      _local[code] = v;
    }
    _notify();
  }

  void _notify() {
    setState(() {});
    widget.onChanged(Map<String, int>.from(_local));
  }

  String? _subtitle(OptionGroupEntity g, int total) {
    final parts = <String>[];
    parts.add(g.multiple ? '可多选 当前$total' : '单选');
    if (g.minSelect > 0) parts.add('最少${g.minSelect}');
    if (g.maxSelect != null) parts.add('最多${g.maxSelect}');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final total = _currentTotal();
    final sub = _subtitle(g, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 4),
          child: Row(
            children: [
              Expanded(child: Text(g.groupName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17))),
              if (sub != null) Text(sub, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              if (widget.onSendGroup != null)
                IconButton(
                  icon: const Icon(Icons.send_rounded, size: 18),
                  color: AppColors.amberPrimary,
                  tooltip: '发送此分组给顾客',
                  onPressed: () => widget.onSendGroup!(g, Map<String, int>.from(_local)),
                ),
            ],
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final opt in g.options)
              OptionChoiceTile(
                option: opt,
                group: g,
                quantity: _local[opt.code] ?? 0,
                selected: _local.containsKey(opt.code),
                canAddMore: _canAddAnother(),
                isLastSlotSingle: g.multiple && !_local.containsKey(opt.code) && !_canAddAnother(),
                onTap: () {
                  if (!g.multiple) {
                    _toggleSingle(opt.code);
                  } else {
                    _toggleMulti(opt.code);
                  }
                },
                onInc: () => _incQty(opt.code),
                onDec: () => _decQty(opt.code),
              ),
          ],
        ),
      ],
    );
  }
}

class OptionChoiceTile extends StatelessWidget {
  final OptionChoiceEntity option;
  final OptionGroupEntity group;
  final int quantity;
  final bool selected;
  final bool canAddMore;
  final bool isLastSlotSingle;
  final VoidCallback onTap;
  final VoidCallback onInc;
  final VoidCallback onDec;
  const OptionChoiceTile({super.key,
    required this.option,
    required this.group,
    required this.quantity,
    required this.selected,
    required this.canAddMore,
    required this.isLastSlotSingle,
    required this.onTap,
    required this.onInc,
    required this.onDec,
  });
  @override
  Widget build(BuildContext context) {
    final hasExtra = option.extraPrice > 0;
    final gradient = selected
        ? const LinearGradient(
            colors: [AppColors.amberPrimaryHover, AppColors.amberPrimary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.72)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final borderColor = selected ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.06);
    final textColor = selected ? Colors.white : Colors.black87;
    final showQtyControls = group.multiple && selected && (!isLastSlotSingle);

    return SizedBox(
      width: 150,
      height: 150,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.name,
                style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w800),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Spacer(),
              if (showQtyControls)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _QtyButton(icon: Icons.remove, enabled: quantity > 0, onPressed: quantity > 0 ? onDec : null, fg: textColor),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('$quantity', style: TextStyle(fontSize: 20, color: textColor, fontWeight: FontWeight.w800)),
                    ),
                    _QtyButton(icon: Icons.add, enabled: canAddMore, onPressed: canAddMore ? onInc : null, fg: textColor),
                  ],
                ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 18, color: selected ? Colors.white : AppColors.amberPrimary),

                  if (hasExtra)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '+¥${(option.extraPrice * (quantity > 0 ? quantity : 1)).toStringAsFixed(0)}',
                      style: TextStyle(color: selected ? Colors.white : AppColors.amberPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                  // if (quantity > 0)
                  //   Padding(
                  //     padding: const EdgeInsets.only(left: 6.0),
                  //     child: Container(
                  //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  //       decoration: BoxDecoration(
                  //         color: selected ? Colors.white.withOpacity(0.18) : Colors.black.withOpacity(0.05),
                  //         borderRadius: BorderRadius.circular(12),
                  //       ),
                  //       child: Text('x$quantity', style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 12)),
                  //     ),
                  //   ),
                  
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon; final bool enabled; final VoidCallback? onPressed; final Color fg;
  const _QtyButton({required this.icon, required this.enabled, required this.onPressed, required this.fg});
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        //borderRadius: BorderRadius.circular(12),
        child: Container(
          // width: 26,
          // height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? fg.withAlpha(38) : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Icon(icon, size: 36, color: fg),
        ),
      ),
    );
  }
}
