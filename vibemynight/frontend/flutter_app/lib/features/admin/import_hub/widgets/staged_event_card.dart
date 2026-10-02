import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/staged_event_models.dart';

class StagedEventCard extends StatelessWidget {
  final StagedEvent event;
  final bool isSelected;
  final ValueChanged<bool?> onSelectChanged;
  final VoidCallback onPreview;
  final VoidCallback onEdit;
  final VoidCallback? onOpenSource;

  const StagedEventCard({
    super.key,
    required this.event,
    required this.isSelected,
    required this.onSelectChanged,
    required this.onPreview,
    required this.onEdit,
    this.onOpenSource,
  });

  Color _getStatusColor(StagedStatus status) {
    switch (status) {
      case StagedStatus.approved:
        return AppColors.neonBlue;
      case StagedStatus.imported:
        return AppColors.success;
      case StagedStatus.rejected:
        return AppColors.textMuted;
      case StagedStatus.conflict:
        return const Color(0xFFFF7A00);
      case StagedStatus.pendingReview:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(event.status);

    return InkWell(
      onTap: () => onSelectChanged(!isSelected),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.neonPurple.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.neonPink
                : AppColors.neonPurple.withValues(alpha: 0.25),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.neonPink.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.4),
              blurRadius: isSelected ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top image container with overlay & badges
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Stack(
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    color: const Color(0xFF1E1730),
                    child: (event.posterUrl != null && event.posterUrl!.isNotEmpty)
                        ? Image.network(
                            event.posterUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder(),
                  ),
                  // Gradient dark overlay on bottom of image
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.black.withValues(alpha: 0.75),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Checkbox top-left
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Checkbox(
                        value: isSelected,
                        activeColor: AppColors.neonPink,
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: onSelectChanged,
                      ),
                    ),
                  ),
                  // Status badge top-right
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        event.status.displayName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // AI tag bottom-left of image
                  if (event.aiProcessed)
                    Positioned(
                      bottom: 8,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Gemini Enriched',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Source tag bottom-right of image
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.source.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Title
                    Text(
                      event.displayTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Date & Venue metadata
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: AppColors.neonPink,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            event.eventStartDate ?? 'Date TBA',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: AppColors.neonBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.city ?? 'Gujarat',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Venue & Pricing
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            event.venueName ?? 'Venue TBA',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.neonPurple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.neonPurple.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            event.priceDisplay,
                            style: const TextStyle(
                              color: AppColors.neonPink,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Duplicate Warning
                    if (event.duplicateOf != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7A00).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFFF7A00).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.copy_rounded,
                              size: 12,
                              color: Color(0xFFFF7A00),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Duplicate of #${event.duplicateOf}',
                                style: const TextStyle(
                                  color: Color(0xFFFF7A00),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Spacer(),
                    const Divider(color: AppColors.divider, height: 16),

                    // Action buttons bar
                    Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.divider),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.visibility_rounded, size: 14),
                          label: const Text('Preview', style: TextStyle(fontSize: 11.5)),
                          onPressed: onPreview,
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.neonBlue,
                            side: BorderSide(
                              color: AppColors.neonBlue.withValues(alpha: 0.4),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.edit_rounded, size: 14),
                          label: const Text('Edit', style: TextStyle(fontSize: 11.5)),
                          onPressed: onEdit,
                        ),
                        const Spacer(),
                        if (event.sourceUrl != null && event.sourceUrl!.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            tooltip: 'Source URL',
                            onPressed: onOpenSource,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.celebration_rounded, color: AppColors.neonPurple, size: 36),
          SizedBox(height: 6),
          Text(
            'VibeMyNight Event',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
