import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/network_image_box.dart';
import '../../../models/event_summary.dart';

/// Showmates-inspired 3:4 Vertical Poster Event Card with luxury dark neon styling:
/// - High-fidelity poster visual with rounded corners
/// - Floating date & time pill
/// - Featured / Selling Fast status badge
/// - 2-line title, venue details with icons, starting price & CTA chip.
class EventCard extends StatelessWidget {
  final EventSummary event;
  final double imageHeight;

  const EventCard({
    super.key,
    required this.event,
    this.imageHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    final targetRoute = '/events/${event.slug.isNotEmpty ? event.slug : event.id}';
    final hasStartDate = event.startDate.isNotEmpty;
    final isCompact = MediaQuery.of(context).size.width < 600;

    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: isCompact ? 14 : 18,
      onTap: () => context.push(targetRoute),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. POSTER IMAGE WITH OVERLAYS (3:4 Ratio)
          Stack(
            children: [
              Hero(
                tag: 'event-image-${event.id}',
                child: NetworkImageBox(
                  url: event.thumbnail ?? event.mainImage,
                  height: isCompact ? 165 : imageHeight,
                  width: double.infinity,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(isCompact ? 14 : 18)),
                ),
              ),
              // Gradient bottom shadow on image for readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF100D22).withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),
              // Top-left: Date & Time pill
              if (hasStartDate)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 7 : 10,
                      vertical: isCompact ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xE607070E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month, color: const Color(0xFFC084FC), size: isCompact ? 10 : 12),
                        const SizedBox(width: 4),
                        Text(
                          event.startDate,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isCompact ? 9.5 : 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Top-right: Featured / Selling Fast tag
              if (event.featured)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _FeaturedBadge(isCompact: isCompact),
                ),
            ],
          ),

          // 2. EVENT DETAILS BODY
          Padding(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 10 : 14,
              isCompact ? 8 : 12,
              isCompact ? 10 : 14,
              isCompact ? 10 : 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Name (Bold, 2 lines max)
                Text(
                  event.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isCompact ? 13 : 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: isCompact ? 4 : 6),

                // Location / Venue
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: const Color(0xFF60A5FA), size: isCompact ? 12 : 14),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        [
                          if (event.location != null && event.location!.isNotEmpty) event.location!,
                          if (event.city != null && event.city!.isNotEmpty) event.city!,
                        ].where((s) => s.isNotEmpty).join(', ').ifEmpty('Venue To Be Announced'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: isCompact ? 10.5 : 12,
                        ),
                      ),
                    ),
                  ],
                ),

                // Featured Artist
                if (event.featuredArtistName != null && event.featuredArtistName!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.mic_none, color: const Color(0xFFA855F7), size: isCompact ? 12 : 14),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          event.featuredArtistName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: isCompact ? 10.5 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                SizedBox(height: isCompact ? 8 : 12),
                const Divider(height: 1, color: Color(0x1FFFFFFF)),
                SizedBox(height: isCompact ? 6 : 10),

                // Bottom Price & Action Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'from',
                          style: TextStyle(
                            fontSize: isCompact ? 9 : 10,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                        Text(
                          event.startingPrice != null
                              ? '₹${event.startingPrice!.toInt()}'
                              : '₹499',
                          style: TextStyle(
                            fontSize: isCompact ? 13 : 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFA855F7),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 8 : 12,
                        vertical: isCompact ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isCompact ? 'Passes' : 'Get Pass',
                            style: TextStyle(
                              color: const Color(0xFFC084FC),
                              fontSize: isCompact ? 9.5 : 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_forward, color: const Color(0xFFC084FC), size: isCompact ? 10 : 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}

class _FeaturedBadge extends StatelessWidget {
  final bool isCompact;

  const _FeaturedBadge({this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2.5 : 4,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.brandGradient),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonPink.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: Colors.white, size: isCompact ? 9 : 11),
          const SizedBox(width: 3),
          Text(
            'FEATURED',
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 8.5 : 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
