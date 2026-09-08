import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/network_image_box.dart';
import '../../../models/artist.dart';

class ArtistCard extends StatelessWidget {
  final Artist artist;

  const ArtistCard({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/artists/${artist.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'artist-image-${artist.id}',
            child: NetworkImageBox(
              url: artist.photoUrl,
              height: 130,
              width: double.infinity,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(artist.type, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
