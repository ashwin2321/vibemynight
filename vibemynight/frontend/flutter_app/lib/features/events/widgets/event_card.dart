import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/network_image_box.dart';
import '../../../models/event_summary.dart';

/// EventCard - 16:9 Landscape Card with luxury dark neon styling:
/// - 16:9 Landscape Banner Image with safe fallback
/// - Floating date pill & Featured badge
/// - 2-line title, location pin with venue, artist tag
/// - Divider & bottom price with "Get Pass" gradient button
class EventCard extends StatelessWidget {
  final EventSummary event;
  final double imageHeight;

  const EventCard({
    super.key,
    required this.event,
    this.imageHeight = 200,
  });

  static const List<String> _curatedBanners = [
    'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&fit=crop&auto=format',
    'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800&fit=crop&auto=format',
    'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800&fit=crop&auto=format',
    'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=800&fit=crop&auto=format',
    'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=800&fit=crop&auto=format',
    'https://images.unsplash.com/photo-1571266028243-3716f02d2d2e?w=800&fit=crop&auto=format',
  ];

  @override
  Widget build(BuildContext context) {
    final targetRoute = '/events/${event.slug.isNotEmpty ? event.slug : event.id}';
    final hasStartDate = event.startDate.isNotEmpty;
    final isCompact = MediaQuery.of(context).size.width < 600;
    final fallbackUrl = _curatedBanners[event.id.abs() % _curatedBanners.length];

    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: isCompact ? 14 : 18,
      onTap: () => context.push(targetRoute),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. BANNER IMAGE WITH OVERLAYS (16:9 Landscape Banner Ratio)
          Stack(
            children: [
              Hero(
                tag: 'event-image-${event.id}',
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: NetworkImageBox(
                    url: event.mainImage ?? event.thumbnail,
                    fallbackUrl: fallbackUrl,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(isCompact ? 14 : 18)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Top-left: Date Pill
              if (hasStartDate)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 8 : 10,
                      vertical: isCompact ? 3.5 : 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                        width: 1,
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
                        Icon(Icons.calendar_month, color: const Color(0xFFC084FC), size: isCompact ? 11 : 13),
                        const SizedBox(width: 4),
                        Text(
                          event.startDate,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isCompact ? 10 : 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Top-right: Featured / Selling Fast tag
              if (event.featured)
                Positioned(
                  top: 10,
                  right: 10,
                  child: _FeaturedBadge(isCompact: isCompact),
                ),
            ],
          ),

          // 2. EVENT DETAILS BODY
          Padding(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 12 : 14,
              isCompact ? 10 : 12,
              isCompact ? 12 : 14,
              isCompact ? 12 : 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Event Name (Bold, 2 lines max)
                Text(
                  event.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isCompact ? 13.5 : 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: isCompact ? 4 : 6),

                // Location / Venue
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: const Color(0xFF60A5FA), size: isCompact ? 13 : 14),
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
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: isCompact ? 11 : 12,
                        ),
                      ),
                    ),
                  ],
                ),

                // Featured Artist (if any)
                if (event.featuredArtistName != null && event.featuredArtistName!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.mic_none, color: const Color(0xFFA855F7), size: isCompact ? 13 : 14),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          event.featuredArtistName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: isCompact ? 11 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                SizedBox(height: isCompact ? 8 : 10),
                const Divider(height: 1, color: Color(0x1AFFFFFF)),
                SizedBox(height: isCompact ? 8 : 10),

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
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          event.startingPrice != null
                              ? '₹${event.startingPrice!.toInt()}'
                              : '₹499',
                          style: TextStyle(
                            fontSize: isCompact ? 14 : 16,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFA855F7),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 10 : 12,
                        vertical: isCompact ? 5 : 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Get Pass',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
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
