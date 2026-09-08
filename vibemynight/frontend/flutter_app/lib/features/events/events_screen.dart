import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppNavbar(currentRoute: '/events'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                      Row(
                        children: [
                          _FilterChip(
                            label: 'All Events',
                            selected: _filter == _EventFilter.all,
                            onSelected: () => setState(() => _filter = _EventFilter.all),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Featured',
                            selected: _filter == _EventFilter.featured,
                            onSelected: () => setState(() => _filter = _EventFilter.featured),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Upcoming',
                            selected: _filter == _EventFilter.upcoming,
                            onSelected: () => setState(() => _filter = _EventFilter.upcoming),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      eventsAsync.when(
                        loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: LoadingView())),
                        error: (err, _) => ErrorView(
                          message: err.toString(),
                          onRetry: () => ref.invalidate(publishedEventsProvider),
                        ),
                        data: (events) {
                          final filtered = _apply(events);
                          if (filtered.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(48),
                                child: Text('No events match your search.', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                            );
                          }
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final crossAxisCount = width > 900 ? 3 : (width > 550 ? 2 : 1);
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 20,
                                  crossAxisSpacing: 20,
                                  childAspectRatio: 0.72,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) => FadeIn(
                                  delay: Duration(milliseconds: index * 40),
                                  child: EventCard(event: filtered[index]),
                                ),
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
      backgroundColor: AppColors.surfaceGlass,
      labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textSecondary),
    );
  }
}
