import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shop_staff/core/ui/app_colors.dart';
import 'package:shop_staff/core/router/app_router.dart';

/// SimpleToast: lightweight, dependency-free toast shown at screen center.
/// Usage:
///   SimpleToast.success(context, '保存成功');
///   SimpleToast.error(context, '保存失败');
/// Or via extension:
///   context.toastSuccess('OK');
///   context.toastError('Oops');
class SimpleToast {
	static OverlayEntry? _entry;
	static Timer? _timer;

	static void success(BuildContext context, String message, {Duration duration = const Duration(milliseconds: 1500)}) {
		_show(context, message: message, color: AppColors.emerald600, icon: Icons.check_rounded, duration: duration);
	}

	static void error(BuildContext context, String message, {Duration duration = const Duration(milliseconds: 1800)}) {
		_show(context, message: message, color: Colors.red.shade600, icon: Icons.close_rounded, duration: duration);
	}

		// Global variants: no BuildContext required. Uses rootNavigatorKey overlay.
		static void successGlobal(String message, {Duration duration = const Duration(milliseconds: 1500)}) {
			final overlay = rootNavigatorKey.currentState?.overlay;
			if (overlay == null) return;
			_showWithOverlay(overlay, message: message, color: AppColors.emerald600, icon: Icons.check_circle_outline, duration: duration);
		}

		static void errorGlobal(String message, {Duration duration = const Duration(milliseconds: 1800)}) {
			final overlay = rootNavigatorKey.currentState?.overlay;
			if (overlay == null) return;
			_showWithOverlay(overlay, message: message, color: Colors.red.shade600, icon: Icons.close_rounded, duration: duration);
		}

	static void _show(
		BuildContext context, {
		required String message,
		required Color? color,
		required IconData icon,
		required Duration duration,
	}) {
		// Remove any existing toast
		_timer?.cancel();
		_timer = null;
		_entry?.remove();
		_entry = null;

			final overlay = Overlay.of(context, rootOverlay: true);
			_showWithOverlay(overlay, message: message, color: color, icon: icon, duration: duration);
	}

		static void _showWithOverlay(
			OverlayState overlay, {
			required String message,
			required Color? color,
			required IconData icon,
			required Duration duration,
		}) {
			late OverlayEntry entry;
			entry = OverlayEntry(
				builder: (ctx) => _ToastWidget(
					message: message,
					color: (color ?? Colors.black87),
					icon: icon,
					duration: duration,
					onDismissed: () {
						entry.remove();
						if (_entry == entry) _entry = null;
					},
				),
			);
			_entry = entry;
			overlay.insert(entry);
		}
}

class _ToastWidget extends StatefulWidget {
	final String message;
	final Color color;
	final IconData icon;
	final Duration duration;
	final VoidCallback onDismissed;
	const _ToastWidget({
		required this.message,
		required this.color,
		required this.icon,
		required this.duration,
		required this.onDismissed,
	});

	@override
	State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
	late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
	late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
	late final Animation<double> _scale = Tween<double>(begin: 0.96, end: 1).animate(_opacity);

	@override
	void initState() {
		super.initState();
		_controller.forward();
		Future<void>.delayed(widget.duration, () async {
			if (!mounted) return;
			await _controller.reverse();
			if (mounted) widget.onDismissed();
		});
	}

	@override
	void dispose() {
		_controller.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return IgnorePointer(
			child: Material(
				type: MaterialType.transparency,
				child: Center(
					child: FadeTransition(
						opacity: _opacity,
						child: ScaleTransition(
							scale: _scale,
							child: ConstrainedBox(
								constraints: const BoxConstraints(maxWidth: 320),
								child: DecoratedBox(
									decoration: BoxDecoration(
										color: Colors.white,
										borderRadius: BorderRadius.circular(12),
										boxShadow: [
											BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 6)),
										],
									),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Container(
                          //   width: 36,
                          //   height: 36,
                          //   decoration: BoxDecoration(color: widget.color.withValues(alpha: 30), shape: BoxShape.circle),
                          //   alignment: Alignment.center,
                          //   child: Icon(widget.icon, color: widget.color, size: 22),
                          // ),
                          Icon(widget.icon, color: widget.color, size: 32),
                          const SizedBox(height: 10),
                          Text(
                            widget.message,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
								),
							),
						),
					),
				),
			),
		);
	}
}

extension SimpleToastX on BuildContext {
	void toastSuccess(String message, {Duration duration = const Duration(milliseconds: 1500)}) => SimpleToast.success(this, message, duration: duration);
	void toastError(String message, {Duration duration = const Duration(milliseconds: 1800)}) => SimpleToast.error(this, message, duration: duration);
}

