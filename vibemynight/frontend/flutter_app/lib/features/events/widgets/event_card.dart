import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/network_image_box.dart';
import '../../../models/event_summary.dart';

/// BookMyShow & Luxury Nightlife inspired 3:4 Vertical Poster Event Card:
/// - High-fidelity poster visual with rounded corners and glassmorphic border
/// - Floating category and featured status badges
/// - Emerald date & timing badge
/// - 2-line high-contrast title with drop shadow
/// - Venue details with location icon
/// - Starting price & "Book Passes →" neon CTA.
class EventCard extends StatelessWidget {
  final EventSummary event;

  const EventCard({
    super.key,
    required this.event,
  });

  static const List<String> _curatedPosters = [
    'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&fit=crop&auto=format',
    'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800&fit=crop&auto=format',
    'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800&fit=crop&auto=format',
    'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=800&fit=crop&auto=format',
    'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=800&fit=crop&auto=format',
    'https://images.unsplash.com/photo-1571266028243-3716f02d2d2e?w=800&fit=crop&auto=format',
  ];

  String _detectCategory(EventSummary event) {
    final name = event.name.toLowerCase();
    final slug = event.slug.toLowerCase();
    if (name.contains('garba') || name.contains('navratri') || name.contains('dandiya') || slug.contains('garba')) {
      return 'GARBA & DANDIYA';
    }
    if (name.contains('edm') || name.contains('dj') || name.contains('club') || slug.contains('edm') || slug.contains('dj')) {
      return 'EDM & NIGHTLIFE';
    }
    if (name.contains('concert') || name.contains('live') || (event.featuredArtistName != null && event.featuredArtistName!.isNotEmpty)) {
      return 'LIVE CONCERT';
    }
    return 'NIGHTLIFE PASS';
  }

  IconData _detectCategoryIcon(String category) {
    if (category.contains('GARBA')) return Icons.festival_rounded;
    if (category.contains('EDM')) return Icons.headphones_rounded;
    if (category.contains('CONCERT')) return Icons.mic_external_on_rounded;
    return Icons.local_activity_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final targetRoute = '/events/${event.slug.isNotEmpty ? event.slug : event.id}';
    final passesRoute = '/events/${event.slug.isNotEmpty ? event.slug : event.id}/passes';
    final hasStartDate = event.startDate.isNotEmpty;
    final isCompact = MediaQuery.of(context).size.width < 600;
    final fallbackUrl = _curatedPosters[event.id.abs() % _curatedPosters.length];
    final category = _detectCategory(event);
    final categoryIcon = _detectCategoryIcon(category);

    // Format display date line: e.g. "Sun, 11 Oct" or "11 Oct - 20 Oct"
    final dateDisplay = [
      if (hasStartDate) event.startDate,
      if (event.endDate.isNotEmpty && event.endDate != event.startDate) event.endDate,
    ].join(' - ');

    final dateWithTime = dateDisplay.isNotEmpty
        ? '$dateDisplay • 8:00 PM'
        : 'Dates Announced Soon';

    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: isCompact ? 14 : 18,
      onTap: () => context.push(targetRoute),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. POSTER IMAGE WITH FLOATING BADGES (3:4 Ratio)
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

              // Gradient Overlay at the bottom of the poster image
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
                        const Color(0xFF100B22).withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                ),
              ),

              // Top-Left: Category / Vibe Pill Badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 7 : 9,
                    vertical: isCompact ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.neonPurple.withValues(alpha: 0.7),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonPurple.withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(categoryIcon, color: const Color(0xFFC084FC), size: isCompact ? 10 : 12),
                      const SizedBox(width: 4),
                      Text(
                        category,
                        style: TextStyle(
                          color: const Color(0xFFE9D5FF),
                          fontSize: isCompact ? 8.5 : 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top-Right: Featured / Hot Badge
              if (event.featured)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _FeaturedBadge(isCompact: isCompact),
                ),
            ],
          ),

          // 2. LUXURY EVENT DETAILS BODY
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
                // Date & Time in High-Visibility Emerald Accent
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: isCompact ? 11 : 12,
                      color: const Color(0xFF4ADE80), // Emerald Green
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        dateWithTime,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF4ADE80),
                          fontSize: isCompact ? 10.5 : 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 5 : 6),

                // Event Name (Bold, 2 lines max, high contrast)
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

                // Location / Venue
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: isCompact ? 11 : 12,
                      color: Colors.white54,
                    ),
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
                          fontSize: isCompact ? 10.5 : 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 8 : 10),

                // Bottom Row: Starting Price & "Book Passes →"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        event.startingPrice != null
                            ? '₹${event.startingPrice!.toInt()} onwards'
                            : '₹499 onwards',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 12.5 : 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => context.push(passesRoute),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Passes',
                              style: TextStyle(
                                color: const Color(0xFFC084FC),
                                fontSize: isCompact ? 11 : 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: isCompact ? 12 : 13,
                              color: const Color(0xFFC084FC),
                            ),
                          ],
                        ),
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
            color: AppColors.neonPink.withValues(alpha: 0.45),
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
              fontSize: isCompact ? 8.5 : 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
