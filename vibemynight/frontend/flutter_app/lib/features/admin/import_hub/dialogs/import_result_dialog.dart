import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/staged_event_models.dart';

class ImportResultDialog extends StatelessWidget {
  final StagedImportBatchResult result;
  final VoidCallback onViewProductionEvents;

  const ImportResultDialog({
    super.key,
    required this.result,
    required this.onViewProductionEvents,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0B1E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.neonPurple.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.task_alt_rounded,
                      color: AppColors.success,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import Execution Report',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Batch Import Results to Live Production',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Summary Pills
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildStatPill('Requested', result.totalRequested, AppColors.neonBlue),
                  const SizedBox(width: 8),
                  _buildStatPill('Imported', result.imported, AppColors.success),
                  const SizedBox(width: 8),
                  _buildStatPill('Already In', result.alreadyImported, AppColors.textMuted),
                  const SizedBox(width: 8),
                  _buildStatPill('Conflicts', result.conflicts, const Color(0xFFFF7A00)),
                  const SizedBox(width: 8),
                  _buildStatPill('Failed', result.failed, AppColors.error),
                ],
              ),
            ),

            const Divider(color: AppColors.divider, height: 1),

            // Item-by-item Results List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: result.results.length,
                itemBuilder: (context, index) {
                  final item = result.results[index];
                  return _buildResultItemCard(item);
                },
              ),
            ),

            // Modal Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0B1E),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(
                  top: BorderSide(
                    color: AppColors.neonPurple.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.divider),
                    ),
                    child: const Text('Dismiss'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.celebration_rounded, size: 16),
                    label: const Text('View in Production Events'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onViewProductionEvents();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.85),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItemCard(StagedEventImportResultItem item) {
    Color statusColor;
    IconData statusIcon;

    if (item.isSuccess) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_rounded;
    } else if (item.isConflict) {
      statusColor = const Color(0xFFFF7A00);
      statusIcon = Icons.warning_amber_rounded;
    } else if (item.isAlreadyImported) {
      statusColor = AppColors.neonBlue;
      statusIcon = Icons.info_outline_rounded;
    } else {
      statusColor = AppColors.error;
      statusIcon = Icons.error_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161026),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.eventName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (item.slug.isNotEmpty || item.productionEventId != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (item.productionEventId != null) ...[
                  Text(
                    'Prod ID: #${item.productionEventId}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (item.slug.isNotEmpty)
                  Expanded(
                    child: Text(
                      'Slug: ${item.slug}',
                      style: const TextStyle(
                        color: AppColors.neonPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
          if (item.reason != null && item.reason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.reason!,
              style: TextStyle(
                color: statusColor.withValues(alpha: 0.9),
                fontSize: 11.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
