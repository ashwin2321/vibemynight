import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'gradient_button.dart';

/// Sticky bottom "GET YOUR PASS" CTA for mobile event-detail screens, per
/// the spec's "Mobile Customer Bottom CTA" requirement.
class StickyCtaBar extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const StickyCtaBar({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Center(child: GradientButton(label: label, onPressed: onPressed)),
      ),
    );
  }
}
