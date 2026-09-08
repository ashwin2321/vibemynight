import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Small colored pill for event/artist/facility/inquiry status values.
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status.toUpperCase()) {
      case 'PUBLISHED':
      case 'ACTIVE':
      case 'CONFIRMED':
      case 'COMPLETED':
        return AppColors.success;
      case 'NEW':
      case 'DRAFT':
        return AppColors.neonBlue;
      case 'CONTACTED':
      case 'UNPUBLISHED':
        return AppColors.warning;
      case 'CANCELLED':
      case 'INACTIVE':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
