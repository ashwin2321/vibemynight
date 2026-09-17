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

enum _DateFilter { all, tonight, weekend, thisWeek, navratri2026 }
enum _VibeFilter { all, featured, garba, edm, concert }

/// Dynamic event listing (GET /events) with Smart City & Date-Range Filter Bar.
/// Client-side search and filter chips, responsive grid of EventCards, and AppFooter.
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedCity = 'All';
  _DateFilter _dateFilter = _DateFilter.all;
  _VibeFilter _vibeFilter = _VibeFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _query = '';
      _selectedCity = 'All';
      _dateFilter = _DateFilter.all;
      _vibeFilter = _VibeFilter.all;
    });
  }

  bool get _hasActiveFilters =>
      _query.isNotEmpty ||
      _selectedCity != 'All' ||
      _dateFilter != _DateFilter.all ||
      _vibeFilter != _VibeFilter.all;

  List<EventSummary> _apply(List<EventSummary> events) {
    var result = events;

    // 1. City Filter
    if (_selectedCity != 'All') {
      final cityLower = _selectedCity.toLowerCase();
      result = result.where((e) {
        final c = e.city?.toLowerCase() ?? '';
        final loc = e.location?.toLowerCase() ?? '';
        return c.contains(cityLower) || loc.contains(cityLower);
      }).toList();
    }

    // 2. Date Filter
    if (_dateFilter != _DateFilter.all) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      result = result.where((e) {
        final start = DateTime.tryParse(e.startDate);
        if (start == null) return true;
        final eventDate = DateTime(start.year, start.month, start.day);

        switch (_dateFilter) {
          case _DateFilter.tonight:
            return eventDate.isAtSameMomentAs(today);
          case _DateFilter.weekend:
            // Calculate upcoming Friday to Sunday
            final daysUntilFriday = (DateTime.friday - now.weekday) % 7;
            final friday = today.add(Duration(days: daysUntilFriday));
            final sunday = friday.add(const Duration(days: 2));
            return !eventDate.isBefore(friday) && !eventDate.isAfter(sunday);
          case _DateFilter.thisWeek:
            final endOfWeek = today.add(const Duration(days: 7));
            return !eventDate.isBefore(today) && !eventDate.isAfter(endOfWeek);
          case _DateFilter.navratri2026:
            final isNavratriMonth = start.year == 2026 && (start.month == 9 || start.month == 10 || start.month == 11);
            final nameLower = e.name.toLowerCase();
            return isNavratriMonth || nameLower.contains('garba') || nameLower.contains('navratri') || nameLower.contains('dandiya');
          case _DateFilter.all:
            return true;
        }
      }).toList();
    }

    // 3. Vibe / Category Filter
    if (_vibeFilter != _VibeFilter.all) {
      result = result.where((e) {
        final name = e.name.toLowerCase();
        final artist = e.featuredArtistName?.toLowerCase() ?? '';
        final slug = e.slug.toLowerCase();
        final loc = e.location?.toLowerCase() ?? '';

        switch (_vibeFilter) {
          case _VibeFilter.featured:
            return e.featured;
          case _VibeFilter.garba:
            return name.contains('garba') || name.contains('navratri') || name.contains('dandiya') || slug.contains('garba') || loc.contains('garba');
          case _VibeFilter.edm:
            return name.contains('edm') || name.contains('dj') || name.contains('club') || name.contains('nightlife') || slug.contains('edm') || slug.contains('dj');
          case _VibeFilter.concert:
            return name.contains('concert') || name.contains('live') || artist.isNotEmpty || slug.contains('concert') || slug.contains('live');
          case _VibeFilter.all:
            return true;
        }
      }).toList();
    }

    // 4. Search Query Filter
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

  Set<String> _extractCities(List<EventSummary> events) {
    final cities = <String>{'All', 'Ahmedabad', 'Surat', 'Vadodara', 'Mumbai'};
    for (final e in events) {
      if (e.city != null && e.city!.trim().isNotEmpty) {
        cities.add(e.city!.trim());
      }
    }
    return cities;
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
                      // Smart Filter Bar Container
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. City Chips Row
                            eventsAsync.maybeWhen(
                              data: (events) {
                                final cities = _extractCities(events).toList();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 14, color: AppColors.neonPurple),
                                        SizedBox(width: 4),
                                        Text('CITY / REGION', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      child: Row(
                                        children: cities.map((city) {
                                          final isSelected = _selectedCity == city;
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 6),
                                            child: _FilterChip(
                                              label: city == 'All' ? '🌐 All Cities' : '📍 $city',
                                              selected: isSelected,
                                              onSelected: () => setState(() => _selectedCity = city),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(color: AppColors.divider, height: 1),
                                    const SizedBox(height: 12),
                                  ],
                                );
                              },
                              orElse: () => const SizedBox.shrink(),
                            ),

                            // 2. Date-Range & Vibe Pills
                            const Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.neonBlue),
                                SizedBox(width: 4),
                                Text('TIMING & DATES', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _FilterChip(
                                    label: '🗓️ All Dates',
                                    selected: _dateFilter == _DateFilter.all,
                                    onSelected: () => setState(() => _dateFilter = _DateFilter.all),
                                  ),
                                  const SizedBox(width: 6),
                                  _FilterChip(
                                    label: '🔥 Tonight',
                                    selected: _dateFilter == _DateFilter.tonight,
                                    onSelected: () => setState(() => _dateFilter = _DateFilter.tonight),
                                  ),
                                  const SizedBox(width: 6),
                                  _FilterChip(
                                    label: '🎉 This Weekend',
                                    selected: _dateFilter == _DateFilter.weekend,
                                    onSelected: () => setState(() => _dateFilter = _DateFilter.weekend),
                                  ),
                                  const SizedBox(width: 6),
                                  _FilterChip(
                                    label: '📅 This Week',
                                    selected: _dateFilter == _DateFilter.thisWeek,
                                    onSelected: () => setState(() => _dateFilter = _DateFilter.thisWeek),
                                  ),
                                  const SizedBox(width: 6),
                                  _FilterChip(
                                    label: '💃 Navratri 2026',
                                    selected: _dateFilter == _DateFilter.navratri2026,
                                    onSelected: () => setState(() => _dateFilter = _DateFilter.navratri2026),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: AppColors.divider, height: 1),
                            const SizedBox(height: 12),

                            // 3. Vibe / Category Filter
                            const Row(
                              children: [
                                Icon(Icons.music_note_outlined, size: 14, color: AppColors.neonPink),
                                SizedBox(width: 4),
                                Text('VIBE & CATEGORY', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _FilterChip(
                                    label: '⚡ All Vibes',
                                    selected: _vibeFilter == _VibeFilter.all,
                                    onSelected: () => setState(() => _vibeFilter = _VibeFilter.all),
                                  ),
                                  const SizedBox(width: 6),
                                  _FilterChip(
                                    label: '⭐ Featured',
                                    selected: _vibeFilter == _VibeFilter.featured,
                                    onSelected: () => setState(() => _vibeFilter = _VibeFilter.featured),
                                  ),
                                  const SizedBox(width: 6),
                                  _FilterChip(
                                    label: '💃 Garba & Dandiya',
                                    selected: _vibeFilter == _VibeFilter.garba,
                                    onSelected: () => setState(() => _vibeFilter = _VibeFilter.garba),
                                  ),
                                  const SizedBox(width: 6),
                                  _FilterChip(
                                    label: '🎧 EDM & Club',
                                    selected: _vibeFilter == _VibeFilter.edm,
                                    onSelected: () => setState(() => _vibeFilter = _VibeFilter.edm),
                                  ),
                                  const SizedBox(width: 6),
                                  _FilterChip(
                                    label: '🎤 Live Concert',
                                    selected: _vibeFilter == _VibeFilter.concert,
                                    onSelected: () => setState(() => _vibeFilter = _VibeFilter.concert),
                                  ),
                                ],
                              ),
                            ),

                            // 4. Live Active Filters summary & Reset button
                            if (_hasActiveFilters) ...[
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Filters applied',
                                    style: TextStyle(color: AppColors.neonPurple, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.restart_alt_rounded, size: 14),
                                    label: const Text('Reset All', style: TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: _resetFilters,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
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
                              final isLargeDesktop = width >= 1150;
                              final isDesktopGrid = width >= 850 && width < 1150;
                              final isTabletGrid = width >= 600 && width < 850;
                              final cols = isLargeDesktop ? 4 : (isDesktopGrid ? 3 : (isTabletGrid ? 3 : 2));
                              final spacing = (isLargeDesktop || isDesktopGrid) ? 18.0 : 10.0;
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
