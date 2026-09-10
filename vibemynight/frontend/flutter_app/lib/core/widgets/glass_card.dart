import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Reusable aesthetic glassmorphism card for customer and admin UI:
/// - Rounded corners with anti-aliasing clip
/// - Dark luxury frosted gradient
/// - Smooth hover scale and neon purple glow.
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? hoverBorderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius = 20,
    this.hoverBorderColor,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.hoverBorderColor ?? AppColors.neonPurple;

    return RepaintBoundary(
      child: MouseRegion(
        cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: widget.onTap != null && _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _isHovered
                  ? const Color(0xFF1B1634)
                  : const Color(0xFF100D22),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: _isHovered
                    ? borderColor.withValues(alpha: 0.75)
                    : Colors.white.withValues(alpha: 0.10),
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? borderColor.withValues(alpha: 0.28)
                      : Colors.black.withValues(alpha: 0.40),
                  blurRadius: _isHovered ? 26 : 14,
                  offset: _isHovered ? const Offset(0, 8) : const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                splashColor: AppColors.neonPurple.withValues(alpha: 0.18),
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: widget.padding,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
