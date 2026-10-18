import 'package:flutter/material.dart';

class SkeletonShimmer extends StatefulWidget {
  const SkeletonShimmer({super.key});

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
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
      builder: (context, _) {
        final shimmerValue = _controller.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShimmerLine(double.infinity, shimmerValue),
            const SizedBox(height: 10),
            _buildShimmerLine(double.infinity, shimmerValue),
            const SizedBox(height: 10),
            _buildShimmerLine(240, shimmerValue),
          ],
        );
      },
    );
  }

  Widget _buildShimmerLine(double width, double animValue) {
    return Container(
      width: width,
      height: 14,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + (animValue * 2), 0),
          end: Alignment(1.0 + (animValue * 2), 0),
          colors: const [
            Color(0xFF1E2129),
            Color(0xFF2E323D),
            Color(0xFF1E2129),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
