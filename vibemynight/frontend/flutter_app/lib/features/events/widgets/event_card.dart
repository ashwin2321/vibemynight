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

    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 18,
      onTap: () => context.push(targetRoute),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. POSTER IMAGE WITH OVERLAYS
          Stack(
            children: [
              Hero(
                tag: 'event-image-${event.id}',
                child: NetworkImageBox(
                  url: event.thumbnail ?? event.mainImage,
                  height: imageHeight,
                  width: double.infinity,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
              ),
              // Gradient bottom shadow on image for readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 60,
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
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xE607070E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month, color: Color(0xFFC084FC), size: 12),
                        const SizedBox(width: 5),
                        Text(
                          event.startDate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Top-right: Featured / Selling Fast tag
              if (event.featured)
                const Positioned(
                  top: 10,
                  right: 10,
                  child: _FeaturedBadge(),
                ),
            ],
          ),

          // 2. EVENT DETAILS BODY
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Name (Bold, 2 lines max)
                Text(
                  event.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),

                // Location / Venue
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Color(0xFF60A5FA), size: 14),
                    const SizedBox(width: 4),
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
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                // Featured Artist
                if (event.featuredArtistName != null && event.featuredArtistName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.mic_none, color: Color(0xFFA855F7), size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.featuredArtistName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0x1FFFFFFF)),
                const SizedBox(height: 10),

                // Bottom Price & Action Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'from',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                        Text(
                          event.startingPrice != null
                              ? '₹${event.startingPrice!.toInt()}'
                              : '₹499',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFA855F7),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Get Pass',
                            style: TextStyle(
                              color: Color(0xFFC084FC),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(Icons.arrow_forward, color: Color(0xFFC084FC), size: 12),
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
  const _FeaturedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: Colors.white, size: 11),
          SizedBox(width: 3),
          Text(
            'FEATURED',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
