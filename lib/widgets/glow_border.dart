import 'package:flutter/material.dart';
import 'package:curiosity/theme/colors.dart';

class GlowBorder extends StatefulWidget {
  final bool active;
  final Widget child;

  const GlowBorder({super.key, required this.active, required this.child});

  @override
  State<GlowBorder> createState() => _GlowBorderState();
}

class _GlowBorderState extends State<GlowBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(GlowBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: Padding(padding: const EdgeInsets.all(16), child: widget.child),
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.active
                  ? AppColors.submitButton.withValues(alpha: 0.4 + 0.4 * t)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: widget.active
                ? [
                    BoxShadow(
                      color: AppColors.submitButton.withValues(alpha: 0.25 * t),
                      blurRadius: 12 + 8 * t,
                      spreadRadius: 2,
                    ),
                  ]
                : const [],
          ),
          child: child,
        );
      },
    );
  }
}