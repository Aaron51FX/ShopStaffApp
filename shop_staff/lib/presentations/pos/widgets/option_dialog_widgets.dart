import 'package:flutter/material.dart';
import 'package:shop_staff/domain/entities/product.dart';
import 'package:shop_staff/core/ui/app_colors.dart';

class OptionGroupWidget extends StatefulWidget {
  final OptionGroupEntity group;
  final Map<String, int> selected; // optionCode -> quantity
  final ValueChanged<Map<String, int>> onChanged;
  final VoidCallback? onMaxReached; // 当尝试超过最大可选时触发
  const OptionGroupWidget({super.key, required this.group, required this.selected, required this.onChanged, this.onMaxReached});
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
    if (g.minSelect > 0) parts.add('最少${g.minSelect}');
    if (g.maxSelect != null) parts.add('最多${g.maxSelect}');
    parts.add(g.multiple ? '可多选 当前$total' : '单选');
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
              Expanded(child: Text(g.groupName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
              if (sub != null) Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
  // 显示数量操作区域条件: 多选 + 有附加价 + 已选中 + 不是“最后一个 slot 未选”场景 + (可继续增加 或 当前数量>1 可减少)
  final showQtyControls = hasExtra && selected && (!isLastSlotSingle) && (canAddMore || quantity > 1);
    final bg = selected ? AppColors.amberPrimary : AppColors.stone100;
    final fg = selected ? Colors.white : AppColors.stone600;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: selected ? AppColors.amberPrimary : AppColors.stone300),
                ),
                child: 
                    // 上部：标签区域 (保持原样式)
                    Text(
                      hasExtra ? '${option.name} +${option.extraPrice.toStringAsFixed(0)}' : option.name,
                      style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  
              ),
            
        ),
        if (showQtyControls) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: bg, // 稍微淡一点的背景条
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QtyButton(icon: Icons.remove, enabled: quantity > 0, onPressed: quantity > 0 ? onDec : null, fg: fg),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text('$quantity', style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    _QtyButton(icon: Icons.add, enabled: canAddMore, onPressed: canAddMore ? onInc : null, fg: fg),
                  ],
                ),
              ),
            ],
      ],
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? fg.withAlpha(38) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 14, color: fg),
        ),
      ),
    );
  }
}
