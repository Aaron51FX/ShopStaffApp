import 'package:flutter/material.dart';

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;
  final double height;
  final double pressedScale; // 缩放比例
  final Duration animationDuration;
  const PrimaryButton({super.key,
    required this.label,
    required this.onTap,
    required this.color,
    required this.textColor,
    this.height = 44,
    this.pressedScale = 0.94,
    this.animationDuration = const Duration(milliseconds: 90),
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (widget.onTap == null) return; // 禁用状态不缩放
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? widget.pressedScale : 1.0;
    return Opacity(
      opacity: widget.onTap == null ? 0.5 : 1,
      child: AnimatedScale(
        scale: scale,
        duration: widget.animationDuration,
        curve: Curves.easeOutCubic,
        child: InkWell(
          onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapCancel: () => _setPressed(false),
            onTapUp: (_) => _setPressed(false),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: widget.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (widget.onTap != null)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
              ],
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
