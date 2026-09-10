import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_footer.dart';
import '../../core/widgets/app_navbar.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/fade_in.dart';
import '../../core/widgets/loading_view.dart';
import '../../models/event_summary.dart';
import 'widgets/event_card.dart';

enum _EventFilter { all, featured, upcoming }

/// Dynamic event listing (GET /events) matching Figma EventsPage.tsx.
/// Client-side search and filter tabs, responsive grid of EventCards, and AppFooter.
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _EventFilter _filter = _EventFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EventSummary> _apply(List<EventSummary> events) {
    var result = events;
    if (_filter == _EventFilter.featured) {
      result = result.where((e) => e.featured).toList();
    } else if (_filter == _EventFilter.upcoming) {
      final today = DateTime.now();
      result = result.where((e) {
        final start = DateTime.tryParse(e.startDate);
        return start == null || !start.isBefore(DateTime(today.year, today.month, today.day));
      }).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      result = result.where((e) {
        return e.name.toLowerCase().contains(q) ||
            (e.featuredArtistName?.toLowerCase().contains(q) ?? false) ||
            (e.location?.toLowerCase().contains(q) ?? false) ||
            (e.city?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(publishedEventsProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppNavbar(currentRoute: '/events'),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/events'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 12, vertical: isDesktop ? 32 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EXPLORE',
                        style: TextStyle(color: AppColors.neonPurple, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2),
                      ),
                      const SizedBox(height: 6),
                      const Text('All Events', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 6),
                      const Text('Find and book passes for upcoming events.', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: const InputDecoration(
                          hintText: 'Search event, artist or location...',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Category and Status Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _FilterChip(
                              label: '🔥 All Events',
                              selected: _filter == _EventFilter.all,
                              onSelected: () => setState(() => _filter = _EventFilter.all),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: '⭐ Featured',
                              selected: _filter == _EventFilter.featured,
                              onSelected: () => setState(() => _filter = _EventFilter.featured),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: '📅 Upcoming',
                              selected: _filter == _EventFilter.upcoming,
                              onSelected: () => setState(() => _filter = _EventFilter.upcoming),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      eventsAsync.when(
                        loading: () => const ShimmerCardGrid(count: 6, cardHeight: 380),
                        error: (err, _) => ErrorView(
                          message: err.toString(),
                          onRetry: () => ref.invalidate(publishedEventsProvider),
                        ),
                        data: (events) {
                          if (events.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFA855F7).withValues(alpha: 0.12),
                                    const Color(0xFFEC4899).withValues(alpha: 0.06),
                                    Colors.white.withValues(alpha: 0.02),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.25)),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.4)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.local_fire_department, size: 16, color: Color(0xFFF59E0B)),
                                        SizedBox(width: 6),
                                        Text(
                                          'SEASON 2026 LINEUPS DROPPING SOON',
                                          style: TextStyle(
                                            color: Color(0xFFF59E0B),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Exclusive Passes & VIP Tables Releasing Shortly!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 580),
                                    child: const Text(
                                      'We are curating the biggest AC Dome Garba nights, EDM concerts, and celebrity lineups for 2026. Connect on WhatsApp for early-bird booking alerts and VIP reservations.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                                    label: const Text(
                                      'WhatsApp Pass Inquiries',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF25D366),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () {
                                      final uri = Uri.parse(
                                        'https://wa.me/917041615131?text=Hi%20VibeMyNight!%20I%20want%20to%20inquire%20about%20upcoming%20passes%20and%20VIP%20tables.',
                                      );
                                      launchUrl(uri, mode: LaunchMode.externalApplication);
                                    },
                                  ),
                                ],
                              ),
                            );
                          }
                          final filtered = _apply(events);
                          if (filtered.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(48),
                                child: Text('No events match your search filters.', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                            );
                          }
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final isDesktopGrid = width >= 950;
                              final isTabletGrid = width >= 600 && width < 950;
                              final cols = isDesktopGrid ? 3 : (isTabletGrid ? 3 : 2);
                              final spacing = isDesktopGrid ? 20.0 : 10.0;
                              final itemWidth = (constraints.maxWidth - (cols - 1) * spacing) / cols;

                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing + 6,
                                children: List.generate(filtered.length, (index) {
                                  return SizedBox(
                                    width: itemWidth,
                                    child: FadeIn(
                                      delay: Duration(milliseconds: index * 30),
                                      child: EventCard(
                                        event: filtered[index],
                                        imageHeight: isDesktopGrid ? 220 : 165,
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.neonPurple,
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.white70,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
      ),
    );
  }
}
