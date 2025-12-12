import 'package:flutter/material.dart';

Future<double?> showDiscountInputDialog(
  BuildContext context, {
  double initialValue = 0,
}) {
  return showDialog<double>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _DiscountInputDialog(initialValue: initialValue),
  );
}

class _DiscountInputDialog extends StatefulWidget {
  const _DiscountInputDialog({required this.initialValue});

  final double initialValue;

  @override
  State<_DiscountInputDialog> createState() => _DiscountInputDialogState();
}

class _DiscountInputDialogState extends State<_DiscountInputDialog> {
  late String _input;

  static const List<String> _digitKeys = <String>[
    '7', '8', '9',
    '4', '5', '6',
    '1', '2', '3',
    '清空', '0', '删除',
  ];

  static const List<int> _presetValues = <int>[100, 200, 500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    _input = widget.initialValue > 0 ? widget.initialValue.toStringAsFixed(0) : '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = _currentValue();
    final canConfirm = value > 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '输入折扣金额',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _AmountDisplay(value: value),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildDigitPad(theme)),
                  const SizedBox(width: 16),
                  _PresetColumn(onSelect: _applyPreset),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canConfirm ? () => Navigator.pop(context, value) : null,
                  child: const Text('确定'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDigitPad(ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: _digitKeys.length,
      itemBuilder: (_, index) {
        final label = _digitKeys[index];
        final isAction = label == '删除' || label == '清空';
        return _KeyButton(
          label: label,
          color: isAction ? theme.colorScheme.secondary : theme.colorScheme.primary,
          onTap: () => _handleKey(label),
        );
      },
    );
  }

  void _handleKey(String label) {
    setState(() {
      if (label == '删除') {
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
      } else if (label == '清空') {
        _input = '';
      } else {
        if (_input.length >= 8) return;
        if (_input == '0') {
          _input = label;
        } else {
          _input += label;
        }
      }
    });
  }

  void _applyPreset(int value) {
    setState(() {
      _input = value.toString();
    });
  }

  double _currentValue() {
    if (_input.isEmpty) return 0;
    return double.tryParse(_input) ?? 0;
  }
}

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
      ),
      child: Text(
        value == 0 ? '0' : value.toStringAsFixed(0),
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PresetColumn extends StatelessWidget {
  const _PresetColumn({required this.onSelect});

  final ValueChanged<int> onSelect;

  static const List<int> _values = _DiscountInputDialogState._presetValues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: _values
          .map(
            (value) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: 110,
                child: OutlinedButton(
                  onPressed: () => onSelect(value),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: theme.colorScheme.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  child: Text('¥$value'),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
