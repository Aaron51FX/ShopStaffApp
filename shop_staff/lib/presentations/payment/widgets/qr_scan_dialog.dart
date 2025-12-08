
import 'package:flutter/material.dart';
import 'package:shop_staff/data/services/payment_channel_support.dart';

class QrScanDialog extends StatefulWidget {
  const QrScanDialog({required this.state, required this.onSubmitted, required this.onCancel});

  final QrScanUiState state;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCancel;

  @override
  State<QrScanDialog> createState() => _QrScanDialogState();
}

class _QrScanDialogState extends State<QrScanDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = _ScanHardwareFocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant QrScanDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.status == QrScanDialogStatus.waiting && oldWidget.state.status != QrScanDialogStatus.waiting) {
      _controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  void _handleSubmit(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {});
      return;
    }
    widget.onSubmitted(trimmed);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isError = widget.state.status == QrScanDialogStatus.error;
    final message = widget.state.message ?? (isError ? '扫码失败，请重试' : '请使用扫码枪对准提示区域');
    return AlertDialog(
      title: const Text('扫码支付'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(color: isError ? Colors.redAccent : Colors.black87),
          ),
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            autofocus: true,
            showCursor: false,
            controller: _controller,
            focusNode: _focusNode,
            decoration: const InputDecoration(
              hintText: '请扫码',
              border: InputBorder.none,
              isDense: true,
            ),
            style: const TextStyle(fontSize: 24),
            obscureText: false,
            onSubmitted: _handleSubmit,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('取消'),
        ),
      ],
    );
  }
}

class _ScanHardwareFocusNode extends FocusNode {
  @override
  bool consumeKeyboardToken() {
    // Prevent the soft keyboard while keeping hardware scanner input active.
    return false;
  }
}