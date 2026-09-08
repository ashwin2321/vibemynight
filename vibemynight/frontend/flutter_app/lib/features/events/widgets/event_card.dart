import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/network_image_box.dart';
import '../../../models/event_summary.dart';

/// Event card used on both the Home (Featured/Upcoming) sections and the
/// Events listing screen, per the spec's shared "Event image cards" component.
class EventCard extends StatelessWidget {
  final EventSummary event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/events/${event.slug}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'event-image-${event.id}',
            child: NetworkImageBox(
              url: event.thumbnail ?? event.mainImage,
              height: 140,
              width: double.infinity,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (event.city != null) event.city! else if (event.location != null) event.location!,
                    '${event.dayCount} ${event.dayCount == 1 ? 'night' : 'nights'}',
                  ].where((s) => s.isNotEmpty).join(' · '),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                if (event.featuredArtistName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Featuring ${event.featuredArtistName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (event.startingPrice != null)
                      Text(
                        'From ₹${event.startingPrice!.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppColors.neonPink, fontWeight: FontWeight.w700),
                      )
                    else
                      const SizedBox.shrink(),
                    if (event.featured)
                      const _FeaturedBadge(),
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

class _FeaturedBadge extends StatelessWidget {
  const _FeaturedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.brandGradient),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text('FEATURED', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}
