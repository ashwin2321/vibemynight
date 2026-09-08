import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Consistent section title used for every Home section (Featured Events,
/// Upcoming Events, Featured Artists, Why VibeMyNight, How It Works, FAQ...).
class SectionHeading extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeading({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!, style: const TextStyle(color: AppColors.neonPink)),
          ),
      ],
    );
  }
}
