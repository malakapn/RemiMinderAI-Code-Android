import 'package:flutter/material.dart';

class LoadingShimmer extends StatefulWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  const LoadingShimmer({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 84,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  static const _teal = Color(0xFF4A7FB5);
  static const _cream = Color(0xFFF7F3EC);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => _buildShimmerCard(),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final color = Color.lerp(_cream, _teal.withOpacity(0.14), t)!;
        return Container(
          height: widget.itemHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _teal.withOpacity(0.24)),
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _line(width: 150, height: 14),
            const SizedBox(height: 10),
            _line(width: double.infinity, height: 10),
            const SizedBox(height: 8),
            _line(width: 220, height: 10),
          ],
        ),
      ),
    );
  }

  Widget _line({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _teal.withOpacity(0.22),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
