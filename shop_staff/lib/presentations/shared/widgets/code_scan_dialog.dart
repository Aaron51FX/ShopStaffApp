import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CodeScanDialog extends StatefulWidget {
  const CodeScanDialog({
    super.key,
    required this.title,
    required this.cameraHint,
    required this.cameraUnavailableHint,
    required this.inputHint,
    required this.cancelLabel,
    required this.submitLabel,
    this.hardwareInputEnabled = false,
  });

  final String title;
  final String cameraHint;
  final String cameraUnavailableHint;
  final String inputHint;
  final String cancelLabel;
  final String submitLabel;
  final bool hardwareInputEnabled;

  @override
  State<CodeScanDialog> createState() => _CodeScanDialogState();
}

class _CodeScanDialogState extends State<CodeScanDialog> {
  TextEditingController? _textController;
  FocusNode? _focusNode;
  MobileScannerController? _cameraController;
  bool _completed = false;

  bool get _supportsCamera {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      _ => false,
    };
  }

  @override
  void initState() {
    super.initState();
    if (widget.hardwareInputEnabled) {
      _textController = TextEditingController();
      _focusNode = _ScanHardwareFocusNode();
    }
    if (_supportsCamera) {
      _cameraController = MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode?.requestFocus();
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textController?.dispose();
    _focusNode?.dispose();
    super.dispose();
  }

  void _complete(String? rawValue) {
    final value = rawValue?.trim() ?? '';
    if (_completed || value.isEmpty) return;
    _completed = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (_supportsCamera) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 300,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _cameraController,
                          onDetect: (capture) {
                            for (final barcode in capture.barcodes) {
                              final value = barcode.rawValue;
                              if (value != null && value.trim().isNotEmpty) {
                                _complete(value);
                                break;
                              }
                            }
                          },
                        ),
                        Center(
                          child: IgnorePointer(
                            child: Container(
                              width: 210,
                              height: 210,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.cameraHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 18),
              ] else ...[
                Container(
                  height: 220,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.no_photography_outlined,
                        size: 56,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          widget.cameraUnavailableHint,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              if (widget.hardwareInputEnabled)
                TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  autofocus: !_supportsCamera,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: widget.inputHint,
                    prefixIcon: const Icon(Icons.keyboard_rounded),
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: _complete,
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(widget.cancelLabel),
                  ),
                  if (widget.hardwareInputEnabled) ...[
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () => _complete(_textController?.text),
                      child: Text(widget.submitLabel),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanHardwareFocusNode extends FocusNode {
  @override
  bool consumeKeyboardToken() => false;
}
