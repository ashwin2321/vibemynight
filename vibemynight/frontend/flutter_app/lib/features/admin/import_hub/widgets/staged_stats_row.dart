import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/staged_event_models.dart';

class StagedStatsRow extends StatelessWidget {
  final StagedEventStats stats;
  final StagedStatus? selectedStatus;
  final ValueChanged<StagedStatus?>? onStatusSelected;

  const StagedStatsRow({
    super.key,
    required this.stats,
    this.selectedStatus,
    this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        final cardItems = [
          _StatData(
            label: 'Total Staged',
            count: stats.total,
            icon: Icons.inventory_2_rounded,
            color: AppColors.neonBlue,
            status: null,
          ),
          _StatData(
            label: 'Pending Review',
            count: stats.pending,
            icon: Icons.hourglass_top_rounded,
            color: AppColors.warning,
            status: StagedStatus.pendingReview,
          ),
          _StatData(
            label: 'Imported Live',
            count: stats.imported,
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
            status: StagedStatus.imported,
          ),
          _StatData(
            label: 'Conflicts',
            count: stats.conflicts,
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFFF7A00),
            status: StagedStatus.conflict,
          ),
          _StatData(
            label: 'Rejected',
            count: stats.rejected,
            icon: Icons.cancel_outlined,
            color: AppColors.textMuted,
            status: StagedStatus.rejected,
          ),
        ];

        if (isNarrow) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: cardItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 140,
                    child: _buildCard(item),
                  ),
                );
              }).toList(),
            ),
          );
        }

        return Row(
          children: cardItems.map((item) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _buildCard(item),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCard(_StatData item) {
    final isSelected = selectedStatus == item.status;
    return InkWell(
      onTap: onStatusSelected != null ? () => onStatusSelected!(item.status) : null,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? item.color.withValues(alpha: 0.18)
              : AppColors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? item.color.withValues(alpha: 0.7)
                : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: item.color.withValues(alpha: 0.25),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(item.icon, color: item.color, size: 20),
                Text(
                  '${item.count}',
                  style: TextStyle(
                    color: item.color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatData {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final StagedStatus? status;

  const _StatData({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.status,
  });
}
