import 'package:flutter/material.dart';

/// Palette derived from the VibeMyNight logo (purple -> pink -> blue gradient
/// chevrons) and the "premium dark nightlife" brief - neon purple/pink/blue
/// accents on a near-black base, no childish colors.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0710);
  static const Color surface = Color(0xFF15101F);
  static const Color surfaceGlass = Color(0x1AFFFFFF);

  static const Color neonPurple = Color(0xFF7C3AED);
  static const Color neonPink = Color(0xFFE0339B);
  static const Color neonBlue = Color(0xFF3B82F6);

  static const List<Color> brandGradient = [neonBlue, neonPurple, neonPink];
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonPurple, neonPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color textPrimary = Color(0xFFF5F3FA);
  static const Color textSecondary = Color(0xFFAFA5C2);
  static const Color divider = Color(0x1FFFFFFF);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}
