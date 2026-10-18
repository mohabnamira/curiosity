import 'package:flutter/material.dart';

class GlowBorder extends StatefulWidget {
  final bool active;
  final Widget child;

  const GlowBorder({super.key, required this.active, required this.child});

  @override
  State<GlowBorder> createState() => _GlowBorderState();
}

class _GlowBorderState extends State<GlowBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(GlowBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.active) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: widget.active
              ? [
                  BoxShadow(
                    color: Colors.white
                        .withValues(alpha: 0.05 + 0.15 * _c.value),
                    blurRadius: 6 + 10 * _c.value,
                    spreadRadius: 1,
                  ),
                ]
              : const [],
        ),
        child: child,
      ),
    );
  }
}