import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Premium animated shimmer effect for sleek, instant-feel skeleton loading.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                0.1,
                _controller.value.clamp(0.2, 0.8),
                0.9,
              ],
              colors: [
                Colors.white.withValues(alpha: 0.04),
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        );
      },
    );
  }
}

/// Shared loading indicator used while events/artists/passes/admin tables load.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonPurple.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: AppColors.neonPink,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Loading vibes...',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid of shimmer skeleton cards for lag-free loading states
class ShimmerCardGrid extends StatelessWidget {
  final int count;
  final double cardHeight;

  const ShimmerCardGrid({
    super.key,
    this.count = 3,
    this.cardHeight = 320,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktop = screenWidth >= 1000;
        final isTablet = screenWidth >= 600 && screenWidth < 1000;
        final cols = isDesktop ? 3 : (isTablet ? 2 : 1);
        final itemWidth = (screenWidth - (cols - 1) * 16) / cols;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(count, (index) {
            return SizedBox(
              width: itemWidth,
              height: cardHeight,
              child: const ShimmerBox(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 16,
              ),
            );
          }),
        );
      },
    );
  }
}

/// Shimmer skeleton row for the circular artist slider
class ShimmerArtistSlider extends StatelessWidget {
  final int count;

  const ShimmerArtistSlider({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: List.generate(count, (index) {
          return Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: const ClipOval(
                    child: ShimmerBox(width: 100, height: 100, borderRadius: 50),
                  ),
                ),
                const SizedBox(height: 12),
                const ShimmerBox(width: 80, height: 14, borderRadius: 6),
                const SizedBox(height: 6),
                const ShimmerBox(width: 60, height: 10, borderRadius: 4),
              ],
            ),
          );
        }),
      ),
    );
  }
}
