import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/network_image_box.dart';
import '../../../models/event_summary.dart';

/// Showmates & Zomato District inspired 3:4 Vertical Poster Event Card with luxury dark neon styling:
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
    this.imageHeight = 280,
  });

  static const List<String> _curatedPosters = [
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
    final fallbackUrl = _curatedPosters[event.id.abs() % _curatedPosters.length];

    // Format display date line: e.g. "Sun 11 Oct - Tue 20 Oct | 8:00 PM"
    final dateDisplay = [
      if (hasStartDate) event.startDate,
      if (event.endDate.isNotEmpty && event.endDate != event.startDate) event.endDate,
    ].join(' - ');

    final dateWithTime = dateDisplay.isNotEmpty
        ? '$dateDisplay | 8:00 PM'
        : 'Dates Announced Soon';

    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: isCompact ? 14 : 18,
      onTap: () => context.push(targetRoute),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. POSTER IMAGE WITH OVERLAYS (Showmates 3:4 Vertical Poster Ratio)
          Stack(
            children: [
              Hero(
                tag: 'event-image-${event.id}',
                child: AspectRatio(
                  aspectRatio: 3 / 4,
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
              // Gradient bottom shadow on image for readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF0D0A1C).withValues(alpha: 0.6),
                      ],
                    ),
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

          // 2. SHOWMATES STYLE EVENT DETAILS BODY
          Padding(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 10 : 12,
              isCompact ? 8 : 10,
              isCompact ? 10 : 12,
              isCompact ? 10 : 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date & Time in Showmates Olive/Green accent
                Text(
                  dateWithTime,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF84CC16), // Olive/Lime accent as in Showmates screenshot
                    fontSize: isCompact ? 10.5 : 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: isCompact ? 4 : 5),

                // Event Name (Bold, 2 lines max, Gujarati/Hindi/English safe)
                Text(
                  event.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isCompact ? 13 : 14.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: isCompact ? 4 : 5),

                // Location / Venue (Subtle grey text)
                Text(
                  [
                    if (event.location != null && event.location!.isNotEmpty) event.location!,
                    if (event.city != null && event.city!.isNotEmpty) event.city!,
                  ].where((s) => s.isNotEmpty).join(', ').ifEmpty('Venue To Be Announced'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: isCompact ? 10.5 : 11.5,
                  ),
                ),
                SizedBox(height: isCompact ? 6 : 8),

                // Price Tag (e.g. ₹999 onwards)
                Text(
                  event.startingPrice != null
                      ? '₹${event.startingPrice!.toInt()} onwards'
                      : '₹499 onwards',
                  style: TextStyle(
                    fontSize: isCompact ? 12.5 : 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
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
