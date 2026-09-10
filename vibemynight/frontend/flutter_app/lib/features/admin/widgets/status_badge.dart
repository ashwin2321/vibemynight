import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Small aesthetic colored pill for event/artist/facility/inquiry status values.
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
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
