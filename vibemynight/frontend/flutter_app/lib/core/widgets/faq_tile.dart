import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Simple expandable FAQ row. FAQ copy is generic marketing content (not
/// event/artist/price data), so it's fine as static text per the "no
/// hardcoded business data" rule, which is about production event data.
class FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const FaqTile({super.key, required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        collapsedIconColor: AppColors.textSecondary,
        iconColor: AppColors.neonPink,
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
        childrenPadding: const EdgeInsets.only(bottom: 12),
        expandedAlignment: Alignment.topLeft,
        children: [
          Text(answer, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
