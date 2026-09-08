import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Reusable glassmorphism card used throughout the customer UI (event cards,
/// pass cards, artist cards) per the "glass effect cards" requirement.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: AppColors.surfaceGlass,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
