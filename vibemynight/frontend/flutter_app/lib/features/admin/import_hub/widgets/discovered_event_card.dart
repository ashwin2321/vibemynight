import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/staged_event_models.dart';

class DiscoveredEventCard extends StatelessWidget {
  final DiscoveredEventItem item;
  final bool isSelected;
  final ValueChanged<bool?> onSelectChanged;
  final VoidCallback onDeepScrapeSingle;

  const DiscoveredEventCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onSelectChanged,
    required this.onDeepScrapeSingle,
  });

  Color _getSourceColor(String src) {
    switch (src.toLowerCase()) {
      case 'bookmyshow':
      case 'bms':
        return const Color(0xFFE51837); // BMS Crimson Red
      case 'district':
      case 'zomato':
        return const Color(0xFFCB202D); // District / Zomato Red
      case 'showmates':
      default:
        return AppColors.neonPurple; // Showmates Purple
    }
  }

  String _getSourceLabel(String src) {
    switch (src.toLowerCase()) {
      case 'bookmyshow':
      case 'bms':
        return 'BOOKMYSHOW';
      case 'district':
      case 'zomato':
        return 'DISTRICT (ZOMATO)';
      case 'showmates':
      default:
        return 'SHOWMATES';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourceColor = _getSourceColor(item.source);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.neonPink : AppColors.divider,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.neonPink.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Poster & Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  color: const Color(0xFF1E1730),
                  child: item.posterUrl != null && item.posterUrl!.isNotEmpty
                      ? Image.network(
                          item.posterUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
              ),

              // Source Badge
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sourceColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 4,
                      )
                    ],
                  ),
                  child: Text(
                    _getSourceLabel(item.source),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // Selection Checkbox
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Checkbox(
                    value: isSelected,
                    activeColor: AppColors.neonPink,
                    checkColor: Colors.white,
                    onChanged: onSelectChanged,
                  ),
                ),
              ),

              // Staged Tag
              if (item.isAlreadyStaged)
                Positioned(
                  bottom: 8,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 10),
                        SizedBox(width: 4),
                        Text(
                          'ALREADY STAGED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Content Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // City & Venue
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 13, color: AppColors.neonBlue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${item.city ?? 'Gujarat'} • ${item.venueName ?? 'Venue TBA'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Dates
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        item.eventStartDate ?? 'Date TBA',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                      if (item.eventEndDate != null && item.eventEndDate != item.eventStartDate) ...[
                        const Text(' - ', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                        Text(
                          item.eventEndDate!,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const Spacer(),

                  // Pricing & Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'STARTING AT',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            item.priceDisplay,
                            style: const TextStyle(
                              color: AppColors.neonPink,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.download_for_offline_rounded, size: 14),
                        label: const Text('Scrape', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: onDeepScrapeSingle,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF161026),
      alignment: Alignment.center,
      child: const Icon(Icons.nightlife_rounded, color: AppColors.textMuted, size: 36),
    );
  }
}
