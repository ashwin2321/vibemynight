import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/fade_in.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/network_image_box.dart';

/// "SELECTED DAY UI" - full day detail with artist, program, time, venue,
/// facilities and its passes (GET /event-days/{id}). Tapping a pass's
/// "SELECT PASS" goes to the inquiry form with day+pass pre-filled - price
/// shown here is always what the backend returned, never client-computed.
class EventDayScreen extends ConsumerWidget {
  final int dayId;

  const EventDayScreen({super.key, required this.dayId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayAsync = ref.watch(eventDayDetailProvider(dayId));

    return Scaffold(
      appBar: AppBar(title: const Text('Day details')),
      body: dayAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(eventDayDetailProvider(dayId)),
        ),
        data: (day) {
          final artist = day.primaryArtist;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('DAY ${day.dayNumber} · ${day.date}',
                  style: const TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              if (artist != null)
                FadeIn(
                  child: Row(
                    children: [
                      NetworkImageBox(
                        url: artist.photoUrl,
                        height: 72,
                        width: 72,
                        borderRadius: BorderRadius.circular(36),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(artist.name, style: Theme.of(context).textTheme.headlineSmall),
                            Text(artist.type, style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              if (day.programName != null)
                Text(day.programName!, style: Theme.of(context).textTheme.titleMedium),
              if (day.startTime != null && day.endTime != null)
                Text('${day.startTime} - ${day.endTime}',
                    style: const TextStyle(color: AppColors.textSecondary)),
              if (day.venue != null) Text(day.venue!),
              if (day.location != null) Text(day.location!, style: const TextStyle(color: AppColors.textSecondary)),
              if (day.googleMapsUrl != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        launchUrl(Uri.parse(day.googleMapsUrl!), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('GET DIRECTIONS'),
                  ),
                ),
              if (day.description != null) ...[
                const SizedBox(height: 8),
                Text(day.description!),
              ],
              const SizedBox(height: 24),
              if (day.facilities.isNotEmpty) ...[
                Text('Facilities', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: day.facilities.map((f) => Chip(label: Text(f.name))).toList(),
                ),
                const SizedBox(height: 24),
              ],
              Text('Available Passes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...day.passes.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FadeIn(
                      delay: Duration(milliseconds: entry.key * 60),
                      child: GlassCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.value.name, style: Theme.of(context).textTheme.titleMedium),
                                  Text('₹${entry.value.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          color: AppColors.neonPink, fontWeight: FontWeight.w700)),
                                  ...entry.value.benefits.take(3).map((b) => Text('✓ $b')),
                                  if (entry.value.soldOut)
                                    const Text('SOLD OUT', style: TextStyle(color: AppColors.error))
                                  else if (entry.value.lowStock)
                                    Text('Only ${entry.value.availableQuantity} passes left',
                                        style: const TextStyle(color: AppColors.warning)),
                                ],
                              ),
                            ),
                            GradientButton(
                              label: 'SELECT',
                              onPressed: entry.value.soldOut
                                  ? null
                                  : () => context.push(
                                        '/inquiry',
                                        extra: {'dayId': day.id, 'ticketCategoryId': entry.value.id},
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
