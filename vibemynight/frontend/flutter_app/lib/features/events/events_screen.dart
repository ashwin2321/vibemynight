import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_footer.dart';
import '../../core/widgets/app_navbar.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/fade_in.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/loading_view.dart';
import '../../models/event_summary.dart';
import 'widgets/event_card.dart';

enum _DateFilter {
  all('All Dates', '🗓️'),
  tonight('Tonight', '🔥'),
  weekend('This Weekend', '🎉'),
  thisWeek('This Week', '📅'),
  navratri2026('Season 2026', '💃');

  final String label;
  final String icon;
  const _DateFilter(this.label, this.icon);
}

enum _VibeFilter {
  all('All Vibes', '⚡'),
  featured('Featured Only', '⭐'),
  garba('Garba & Dandiya', '💃'),
  edm('EDM & Club', '🎧'),
  concert('Live Concerts', '🎤');

  final String label;
  final String icon;
  const _VibeFilter(this.label, this.icon);
}

enum _PriceFilter {
  all('All Prices'),
  under500('Under ₹500'),
  from500to1500('₹500 - ₹1500'),
  above1500('₹1500+');

  final String label;
  const _PriceFilter(this.label);
}

/// BookMyShow & Luxury Nightlife inspired Events discovery screen.
/// - Desktop (>= 880px): Left Sticky Filter Sidebar + Top Quick Category Bar + Clean Grid.
/// - Mobile (< 880px): Single-Row Action Bar + Glassmorphic Bottom Sheet Filter Modal + 2-Col Grid.
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
  _PriceFilter _priceFilter = _PriceFilter.all;

  // Sidebar accordion expansion states
  bool _expandCategories = true;
  bool _expandDates = true;
  bool _expandCities = true;
  bool _expandPrice = false;

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
      _priceFilter = _PriceFilter.all;
    });
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCity != 'All') count++;
    if (_dateFilter != _DateFilter.all) count++;
    if (_vibeFilter != _VibeFilter.all) count++;
    if (_priceFilter != _PriceFilter.all) count++;
    if (_query.trim().isNotEmpty) count++;
    return count;
  }

  bool get _hasActiveFilters => _activeFilterCount > 0;

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
            final daysUntilFriday = (DateTime.friday - now.weekday) % 7;
            final friday = today.add(Duration(days: daysUntilFriday));
            final sunday = friday.add(const Duration(days: 2));
            return !eventDate.isBefore(friday) && !eventDate.isAfter(sunday);
          case _DateFilter.thisWeek:
            final endOfWeek = today.add(const Duration(days: 7));
            return !eventDate.isBefore(today) && !eventDate.isAfter(endOfWeek);
          case _DateFilter.navratri2026:
            final isNavratriMonth =
                start.year == 2026 && (start.month == 9 || start.month == 10 || start.month == 11);
            final nameLower = e.name.toLowerCase();
            return isNavratriMonth ||
                nameLower.contains('garba') ||
                nameLower.contains('navratri') ||
                nameLower.contains('dandiya');
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
            return name.contains('garba') ||
                name.contains('navratri') ||
                name.contains('dandiya') ||
                slug.contains('garba') ||
                loc.contains('garba');
          case _VibeFilter.edm:
            return name.contains('edm') ||
                name.contains('dj') ||
                name.contains('club') ||
                name.contains('nightlife') ||
                slug.contains('edm') ||
                slug.contains('dj');
          case _VibeFilter.concert:
            return name.contains('concert') ||
                name.contains('live') ||
                artist.isNotEmpty ||
                slug.contains('concert') ||
                slug.contains('live');
          case _VibeFilter.all:
            return true;
        }
      }).toList();
    }

    // 4. Price Filter
    if (_priceFilter != _PriceFilter.all) {
      result = result.where((e) {
        final price = e.startingPrice ?? 499.0;
        switch (_priceFilter) {
          case _PriceFilter.under500:
            return price <= 500;
          case _PriceFilter.from500to1500:
            return price > 500 && price <= 1500;
          case _PriceFilter.above1500:
            return price > 1500;
          case _PriceFilter.all:
            return true;
        }
      }).toList();
    }

    // 5. Search Query Filter
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

  void _showMobileFilterModal(BuildContext context, List<EventSummary> allEvents) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final tempFiltered = _apply(allEvents);
          final cities = _extractCities(allEvents).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Color(0xFF100B22),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Color(0xFF2A1E4A), width: 1.5)),
            ),
            child: Column(
              children: [
                // Modal Handle & Header
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded, color: AppColors.neonPurple, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Filter Events',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          if (_hasActiveFilters) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.neonPurple,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$_activeFilterCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_hasActiveFilters)
                        TextButton(
                          onPressed: () {
                            _resetFilters();
                            setSheetState(() {});
                            setState(() {});
                          },
                          child: const Text('Reset All', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF1F163D), height: 1),

                // Scrollable Filter Sections
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      // 1. Categories
                      _buildModalSectionTitle('CATEGORIES & VIBES', Icons.music_note_outlined),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _VibeFilter.values.map((v) {
                          final selected = _vibeFilter == v;
                          return _FilterChip(
                            label: '${v.icon} ${v.label}',
                            selected: selected,
                            onSelected: () {
                              setSheetState(() => _vibeFilter = v);
                              setState(() => _vibeFilter = v);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // 2. Dates
                      _buildModalSectionTitle('TIMING & DATES', Icons.calendar_today_outlined),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _DateFilter.values.map((d) {
                          final selected = _dateFilter == d;
                          return _FilterChip(
                            label: '${d.icon} ${d.label}',
                            selected: selected,
                            onSelected: () {
                              setSheetState(() => _dateFilter = d);
                              setState(() => _dateFilter = d);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // 3. Cities
                      _buildModalSectionTitle('CITY / REGION', Icons.location_on_outlined),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: cities.map((c) {
                          final selected = _selectedCity == c;
                          return _FilterChip(
                            label: c == 'All' ? '🌐 All Cities' : '📍 $c',
                            selected: selected,
                            onSelected: () {
                              setSheetState(() => _selectedCity = c);
                              setState(() => _selectedCity = c);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // 4. Price Tier
                      _buildModalSectionTitle('PRICE RANGE', Icons.currency_rupee_rounded),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _PriceFilter.values.map((p) {
                          final selected = _priceFilter == p;
                          return _FilterChip(
                            label: p.label,
                            selected: selected,
                            onSelected: () {
                              setSheetState(() => _priceFilter = p);
                              setState(() => _priceFilter = p);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Bottom Sticky Apply Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF130D2B),
                    border: Border(top: BorderSide(color: Color(0xFF1F163D), width: 1)),
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        label: 'Show ${tempFiltered.length} Events',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModalSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.neonPurple),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFC084FC),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(publishedEventsProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 880;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppNavbar(currentRoute: '/events'),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/events'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 28 : 16,
                vertical: isDesktop ? 32 : 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: eventsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: LoadingView(),
                      ),
                    ),
                    error: (err, _) => ErrorView(
                      message: err.toString(),
                      onRetry: () => ref.invalidate(publishedEventsProvider),
                    ),
                    data: (allEvents) {
                      final filteredEvents = _apply(allEvents);
                      final cities = _extractCities(allEvents).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Header: Title, Live Count & Search
                          _buildTopHeader(isDesktop, filteredEvents.length),
                          const SizedBox(height: 18),

                          // Mobile Top Action Bar (< 880px)
                          if (!isDesktop) ...[
                            _buildMobileActionBar(allEvents, cities),
                            const SizedBox(height: 16),
                          ],

                          // Main Layout: Desktop Two-Column vs Mobile Grid
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Sticky Filters Sidebar (BookMyShow Style)
                                SizedBox(
                                  width: 250,
                                  child: _buildDesktopSidebar(cities, allEvents),
                                ),
                                const SizedBox(width: 28),

                                // Right Main Grid Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Quick Category Tabs (BookMyShow Ribbon)
                                      _buildQuickCategoryRibbon(),
                                      const SizedBox(height: 20),

                                      // Events Grid
                                      _buildEventsGrid(filteredEvents, isDesktop),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else
                            // Mobile View Grid
                            _buildEventsGrid(filteredEvents, isDesktop),
                        ],
                      );
                    },
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

  // 1. Top Header Banner
  Widget _buildTopHeader(bool isDesktop, int count) {
    final cityName = _selectedCity == 'All' ? 'Ahmedabad & Gujarat' : _selectedCity;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neonPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.35)),
                ),
                child: const Text(
                  'EXPLORE NIGHTLIFE',
                  style: TextStyle(
                    color: Color(0xFFC084FC),
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Events in $cityName',
                style: TextStyle(
                  fontSize: isDesktop ? 32 : 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count ${count == 1 ? 'event' : 'events'} available • Verified passes & entry',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        if (isDesktop)
          SizedBox(
            width: 320,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search artist, event or venue...',
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFFC084FC)),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                fillColor: const Color(0xFF130D2B),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.neonPurple, width: 1.5),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 2. Mobile Quick Action Bar (< 880px)
  Widget _buildMobileActionBar(List<EventSummary> allEvents, List<String> cities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mobile Search Bar
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search artist, event or venue...',
            prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFFC084FC)),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16, color: Colors.white54),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            fillColor: const Color(0xFF130D2B),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal Action Bar Buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // Primary "Filters" button (BookMyShow / Zomato style)
              InkWell(
                onTap: () => _showMobileFilterModal(context, allEvents),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _hasActiveFilters
                        ? AppColors.neonPurple.withValues(alpha: 0.25)
                        : const Color(0xFF181135),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _hasActiveFilters ? AppColors.neonPurple : const Color(0xFF2E2254),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: _hasActiveFilters ? const Color(0xFFE9D5FF) : Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Filters',
                        style: TextStyle(
                          color: _hasActiveFilters ? Colors.white : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_hasActiveFilters) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: const BoxDecoration(
                            color: AppColors.neonPurple,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$_activeFilterCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // City Quick Picker Pill
              _buildDropdownPill(
                icon: Icons.location_on_outlined,
                label: _selectedCity == 'All' ? 'City' : _selectedCity,
                isActive: _selectedCity != 'All',
                onTap: () => _showCityPickerSheet(context, cities),
              ),
              const SizedBox(width: 8),

              // Date Quick Picker Pill
              _buildDropdownPill(
                icon: Icons.calendar_today_outlined,
                label: _dateFilter == _DateFilter.all ? 'Date' : _dateFilter.label,
                isActive: _dateFilter != _DateFilter.all,
                onTap: () => _showDatePickerSheet(context),
              ),
              const SizedBox(width: 8),

              // Fast Vibe category shortcuts
              ..._VibeFilter.values.where((v) => v != _VibeFilter.all).map((v) {
                final selected = _vibeFilter == v;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: '${v.icon} ${v.label}',
                    selected: selected,
                    onSelected: () {
                      setState(() {
                        _vibeFilter = selected ? _VibeFilter.all : v;
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownPill({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.neonPurple.withValues(alpha: 0.2) : const Color(0xFF181135),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.neonPurple : const Color(0xFF2E2254),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: isActive ? const Color(0xFFC084FC) : Colors.white70),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: isActive ? const Color(0xFFC084FC) : Colors.white54),
          ],
        ),
      ),
    );
  }

  void _showCityPickerSheet(BuildContext context, List<String> cities) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF120C28),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Select City / Region', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const Divider(color: Color(0xFF1F163D)),
            ...cities.map((city) {
              final isSelected = _selectedCity == city;
              return ListTile(
                leading: Icon(
                  city == 'All' ? Icons.public_rounded : Icons.location_on_rounded,
                  color: isSelected ? AppColors.neonPurple : Colors.white54,
                  size: 20,
                ),
                title: Text(
                  city == 'All' ? 'All Cities' : city,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.neonPurple, size: 18) : null,
                onTap: () {
                  setState(() => _selectedCity = city);
                  Navigator.of(ctx).pop();
                },
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showDatePickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF120C28),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Select Date & Timing', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const Divider(color: Color(0xFF1F163D)),
            ..._DateFilter.values.map((d) {
              final isSelected = _dateFilter == d;
              return ListTile(
                leading: Text(d.icon, style: const TextStyle(fontSize: 18)),
                title: Text(
                  d.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.neonPurple, size: 18) : null,
                onTap: () {
                  setState(() => _dateFilter = d);
                  Navigator.of(ctx).pop();
                },
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // 3. Desktop Left Sidebar (BookMyShow Style)
  Widget _buildDesktopSidebar(List<String> cities, List<EventSummary> allEvents) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF100B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF221742), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune_rounded, size: 16, color: AppColors.neonPurple),
                  SizedBox(width: 8),
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (_hasActiveFilters)
                TextButton(
                  onPressed: _resetFilters,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF1D1438), height: 1),
          const SizedBox(height: 14),

          // Accordion 1: Categories
          _buildSidebarAccordionHeader(
            title: 'Categories & Vibes',
            icon: Icons.music_note_outlined,
            isExpanded: _expandCategories,
            onToggle: () => setState(() => _expandCategories = !_expandCategories),
            isFiltered: _vibeFilter != _VibeFilter.all,
            onClear: () => setState(() => _vibeFilter = _VibeFilter.all),
          ),
          if (_expandCategories) ...[
            const SizedBox(height: 8),
            ..._VibeFilter.values.map((v) {
              final isSelected = _vibeFilter == v;
              return _buildSidebarOption(
                label: '${v.icon} ${v.label}',
                isSelected: isSelected,
                onTap: () => setState(() => _vibeFilter = v),
              );
            }),
            const SizedBox(height: 12),
          ],
          const Divider(color: Color(0xFF1D1438), height: 1),
          const SizedBox(height: 14),

          // Accordion 2: Dates
          _buildSidebarAccordionHeader(
            title: 'Date & Timing',
            icon: Icons.calendar_today_outlined,
            isExpanded: _expandDates,
            onToggle: () => setState(() => _expandDates = !_expandDates),
            isFiltered: _dateFilter != _DateFilter.all,
            onClear: () => setState(() => _dateFilter = _DateFilter.all),
          ),
          if (_expandDates) ...[
            const SizedBox(height: 8),
            ..._DateFilter.values.map((d) {
              final isSelected = _dateFilter == d;
              return _buildSidebarOption(
                label: '${d.icon} ${d.label}',
                isSelected: isSelected,
                onTap: () => setState(() => _dateFilter = d),
              );
            }),
            const SizedBox(height: 12),
          ],
          const Divider(color: Color(0xFF1D1438), height: 1),
          const SizedBox(height: 14),

          // Accordion 3: Cities
          _buildSidebarAccordionHeader(
            title: 'City / Region',
            icon: Icons.location_on_outlined,
            isExpanded: _expandCities,
            onToggle: () => setState(() => _expandCities = !_expandCities),
            isFiltered: _selectedCity != 'All',
            onClear: () => setState(() => _selectedCity = 'All'),
          ),
          if (_expandCities) ...[
            const SizedBox(height: 8),
            ...cities.map((c) {
              final isSelected = _selectedCity == c;
              return _buildSidebarOption(
                label: c == 'All' ? '🌐 All Cities' : '📍 $c',
                isSelected: isSelected,
                onTap: () => setState(() => _selectedCity = c),
              );
            }),
            const SizedBox(height: 12),
          ],
          const Divider(color: Color(0xFF1D1438), height: 1),
          const SizedBox(height: 14),

          // Accordion 4: Price
          _buildSidebarAccordionHeader(
            title: 'Price Range',
            icon: Icons.currency_rupee_rounded,
            isExpanded: _expandPrice,
            onToggle: () => setState(() => _expandPrice = !_expandPrice),
            isFiltered: _priceFilter != _PriceFilter.all,
            onClear: () => setState(() => _priceFilter = _PriceFilter.all),
          ),
          if (_expandPrice) ...[
            const SizedBox(height: 8),
            ..._PriceFilter.values.map((p) {
              final isSelected = _priceFilter == p;
              return _buildSidebarOption(
                label: p.label,
                isSelected: isSelected,
                onTap: () => setState(() => _priceFilter = p),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarAccordionHeader({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required bool isFiltered,
    required VoidCallback onClear,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: isFiltered ? AppColors.neonPurple : const Color(0xFFC084FC)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: isFiltered ? Colors.white : Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (isFiltered)
                  InkWell(
                    onTap: onClear,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text('Clear', style: TextStyle(color: Color(0xFFEC4899), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Colors.white54,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.neonPurple.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.neonPurple.withValues(alpha: 0.6) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.neonPurple : Colors.white30,
                  width: isSelected ? 4.5 : 1.2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Desktop Quick Category Tabs (BookMyShow Ribbon)
  Widget _buildQuickCategoryRibbon() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _FilterChip(
            label: '⚡ All Events',
            selected: _vibeFilter == _VibeFilter.all && _dateFilter == _DateFilter.all,
            onSelected: () {
              setState(() {
                _vibeFilter = _VibeFilter.all;
                _dateFilter = _DateFilter.all;
              });
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '⭐ Featured',
            selected: _vibeFilter == _VibeFilter.featured,
            onSelected: () => setState(() => _vibeFilter = _vibeFilter == _VibeFilter.featured ? _VibeFilter.all : _VibeFilter.featured),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '💃 Garba & Dandiya',
            selected: _vibeFilter == _VibeFilter.garba,
            onSelected: () => setState(() => _vibeFilter = _vibeFilter == _VibeFilter.garba ? _VibeFilter.all : _VibeFilter.garba),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '🎧 EDM & Clubs',
            selected: _vibeFilter == _VibeFilter.edm,
            onSelected: () => setState(() => _vibeFilter = _vibeFilter == _VibeFilter.edm ? _VibeFilter.all : _VibeFilter.edm),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '🎤 Live Concerts',
            selected: _vibeFilter == _VibeFilter.concert,
            onSelected: () => setState(() => _vibeFilter = _vibeFilter == _VibeFilter.concert ? _VibeFilter.all : _VibeFilter.concert),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '🔥 Tonight',
            selected: _dateFilter == _DateFilter.tonight,
            onSelected: () => setState(() => _dateFilter = _dateFilter == _DateFilter.tonight ? _DateFilter.all : _DateFilter.tonight),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '🎉 This Weekend',
            selected: _dateFilter == _DateFilter.weekend,
            onSelected: () => setState(() => _dateFilter = _dateFilter == _DateFilter.weekend ? _DateFilter.all : _DateFilter.weekend),
          ),
        ],
      ),
    );
  }

  // 5. Events Responsive Grid
  Widget _buildEventsGrid(List<EventSummary> events, bool isDesktop) {
    if (events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF100B22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF221742)),
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
                  Icon(Icons.search_off_rounded, size: 16, color: Color(0xFFC084FC)),
                  SizedBox(width: 6),
                  Text(
                    'NO EVENTS FOUND',
                    style: TextStyle(
                      color: Color(0xFFC084FC),
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
              'No events match your active filters',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your city, date range or category filters to see more upcoming events.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Reset All Filters'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = isDesktop ? (width >= 960 ? 3 : 2) : 2;
        final spacing = isDesktop ? 18.0 : 12.0;
        final itemWidth = (constraints.maxWidth - (cols - 1) * spacing) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing + 6,
          children: List.generate(events.length, (index) {
            return SizedBox(
              width: itemWidth,
              child: FadeIn(
                delay: Duration(milliseconds: index * 30),
                child: EventCard(
                  event: events[index],
                ),
              ),
            );
          }),
        );
      },
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
      backgroundColor: const Color(0xFF160E30),
      side: BorderSide(
        color: selected ? AppColors.neonPurple : const Color(0xFF2B1F52),
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.8),
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12.5,
      ),
    );
  }
}
