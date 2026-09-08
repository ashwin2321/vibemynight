import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Premium gradient CTA button ("EXPLORE EVENTS", "GET YOUR PASS") - the
/// brief calls for "premium buttons" distinct from the plain ElevatedButton
/// used in admin/utility contexts.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;
  final bool isLoading;
  final Gradient? gradient;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.padding,
    this.height,
    this.width,
    this.isLoading = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: gradient ?? const LinearGradient(colors: AppColors.brandGradient),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonPurple.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: disabled ? null : onPressed,
            child: Padding(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 8)],
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
