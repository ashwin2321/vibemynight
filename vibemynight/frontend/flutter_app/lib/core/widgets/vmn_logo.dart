import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// VibeMyNight logo component matching Figma VmnLogo.tsx:
/// Displays high-DPI vmn.png mark and gradient VibeMyNight brand text.
class VmnLogo extends StatelessWidget {
  final double size;
  final bool withText;
  final double? fontSize;

  const VmnLogo({
    super.key,
    this.size = 36,
    this.withText = true,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/vmn.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.nightlife, color: Colors.white, size: size * 0.55),
          ),
        ),
        if (withText) ...[
          const SizedBox(width: 10),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              'VibeMyNight',
              style: TextStyle(
                fontSize: fontSize ?? (size >= 48 ? 22 : size <= 28 ? 16 : 18),
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
