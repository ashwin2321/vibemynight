import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/providers/staged_event_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../models/staged_event_models.dart';
import '../widgets/admin_shell.dart';
import 'dialogs/import_confirmation_dialog.dart';
import 'dialogs/import_result_dialog.dart';
import 'dialogs/staged_event_detail_dialog.dart';
import 'dialogs/staged_event_edit_dialog.dart';
import 'widgets/discovered_event_card.dart';
import 'widgets/staged_event_card.dart';
import 'widgets/staged_stats_row.dart';

class AdminImportHubScreen extends ConsumerStatefulWidget {
  const AdminImportHubScreen({super.key});

  @override
  ConsumerState<AdminImportHubScreen> createState() => _AdminImportHubScreenState();
}

class _AdminImportHubScreenState extends ConsumerState<AdminImportHubScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  static const List<String> _cities = [
    'ALL',
    'AHMEDABAD',
    'SURAT',
    'VADODARA',
    'RAJKOT',
    'GANDHINAGAR',
    'MUMBAI',
    'GOA',
    'PUNE',
    'DELHI',
  ];

  static const List<String> _sources = [
    'ALL',
    'SHOWMATES',
    'BOOKMYSHOW',
    'DISTRICT',
  ];

  static const List<String> _categories = [
    'ALL',
    'Garba / Navratri',
    'Nightlife / DJ',
    'Concerts / Music',
    'Comedy / Shows',
    'Food / Fest',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.trim();
      final currentFilter = ref.read(stagedFilterStateProvider);
      if (currentFilter.search != query) {
        ref.read(stagedFilterStateProvider.notifier).state = currentFilter.copyWith(
          search: query.isEmpty ? null : query,
          clearSearch: query.isEmpty,
          page: 1,
        );
      }
    });
  }

  Future<void> _refreshAll() async {
    ref.invalidate(stagedEventsListProvider);
    ref.invalidate(stagedStatsProvider);
    ref.invalidate(discoveredEventsListProvider);
  }

  // --- Discovery Actions ---

  void _toggleDiscoveredSelectAll(List<DiscoveredEventItem> items) {
    final selectedSet = ref.read(selectedDiscoveredItemIdsProvider);
    final allIds = items.map((e) => e.sourceEventId).toSet();
    if (selectedSet.containsAll(allIds)) {
      ref.read(selectedDiscoveredItemIdsProvider.notifier).state = {};
    } else {
      ref.read(selectedDiscoveredItemIdsProvider.notifier).state = {...allIds};
    }
  }

  void _toggleDiscoveredSingleSelect(String sid, bool selected) {
    final current = {...ref.read(selectedDiscoveredItemIdsProvider)};
    if (selected) {
      current.add(sid);
    } else {
      current.remove(sid);
    }
    ref.read(selectedDiscoveredItemIdsProvider.notifier).state = current;
  }

  Future<void> _handleDeepScrapeSelected(List<DiscoveredEventItem> allDiscovered) async {
    final selectedSids = ref.read(selectedDiscoveredItemIdsProvider);
    final selectedItems = allDiscovered.where((i) => selectedSids.contains(i.sourceEventId)).toList();

    if (selectedItems.isEmpty) return;

    ref.read(isDeepScrapingProvider.notifier).state = true;
    try {
      final service = ref.read(stagingServiceProvider);
      final targets = selectedItems.map((item) => DeepScrapeSelectedTarget(
        source: item.source,
        sourceEventId: item.sourceEventId,
        eventUrl: item.eventUrl,
        title: item.title,
        hintPayload: item.rawDiscoveryPayload,
      )).toList();

      final res = await service.deepScrapeEvents(events: targets, runAiEnrichment: true);

      // Clear discovery selection
      ref.read(selectedDiscoveredItemIdsProvider.notifier).state = {};
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Switch to Staged Review tab and refresh
      ref.read(activeImportHubTabProvider.notifier).state = 1;
      await _refreshAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deep Scrape Failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        ref.read(isDeepScrapingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _handleDeepScrapeSingle(DiscoveredEventItem item) async {
    ref.read(isDeepScrapingProvider.notifier).state = true;
    try {
      final service = ref.read(stagingServiceProvider);
      final targets = [
        DeepScrapeSelectedTarget(
          source: item.source,
          sourceEventId: item.sourceEventId,
          eventUrl: item.eventUrl,
          title: item.title,
          hintPayload: item.rawDiscoveryPayload,
        )
      ];

      final res = await service.deepScrapeEvents(events: targets, runAiEnrichment: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: AppColors.success,
          ),
        );
      }

      ref.read(activeImportHubTabProvider.notifier).state = 1;
      await _refreshAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deep Scrape Failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        ref.read(isDeepScrapingProvider.notifier).state = false;
      }
    }
  }

  // --- Staging Review Actions ---

  void _toggleSelectAll(List<StagedEvent> events) {
    final selectedSet = ref.read(selectedStagedEventIdsProvider);
    final allIds = events.map((e) => e.id).toSet();
    if (selectedSet.containsAll(allIds)) {
      ref.read(selectedStagedEventIdsProvider.notifier).state = {};
    } else {
      ref.read(selectedStagedEventIdsProvider.notifier).state = {...allIds};
    }
  }

  void _toggleSingleSelect(int id, bool selected) {
    final current = {...ref.read(selectedStagedEventIdsProvider)};
    if (selected) {
      current.add(id);
    } else {
      current.remove(id);
    }
    ref.read(selectedStagedEventIdsProvider.notifier).state = current;
  }

  void _openDetailDialog(StagedEvent event) {
    showDialog(
      context: context,
      builder: (ctx) => StagedEventDetailDialog(
        event: event,
        onEdit: () => _openEditDialog(event),
      ),
    );
  }

  void _openEditDialog(StagedEvent event) {
    showDialog(
      context: context,
      builder: (ctx) => StagedEventEditDialog(
        event: event,
        onSave: (data) async {
          final service = ref.read(stagingServiceProvider);
          await service.updateStagedEvent(event.id, data);
          await _refreshAll();
        },
      ),
    );
  }

  void _openConfirmationDialog(List<StagedEvent> allEvents) {
    final selectedIds = ref.read(selectedStagedEventIdsProvider);
    final selectedEvents = allEvents.where((e) => selectedIds.contains(e.id)).toList();

    if (selectedEvents.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => ImportConfirmationDialog(
        selectedEvents: selectedEvents,
        onConfirm: () => _executeBatchImport(selectedIds.toList()),
      ),
    );
  }

  Future<void> _executeBatchImport(List<int> ids) async {
    final isImporting = ref.read(isImportingStagedProvider);
    if (isImporting) return;

    ref.read(isImportingStagedProvider.notifier).state = true;

    try {
      final service = ref.read(stagingServiceProvider);
      final batchResult = await service.importStagedEvents(ids);

      ref.read(selectedStagedEventIdsProvider.notifier).state = {};
      ref.read(lastImportBatchResultProvider.notifier).state = batchResult;

      await _refreshAll();

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => ImportResultDialog(
            result: batchResult,
            onViewProductionEvents: () => context.go('/admin/events'),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import Failed: ${e.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during import: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        ref.read(isImportingStagedProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(activeImportHubTabProvider);
    final statsAsync = ref.watch(stagedStatsProvider);
    final isSyncing = ref.watch(isSyncingStagedProvider);
    final isDeepScraping = ref.watch(isDeepScrapingProvider);

    return AdminShell(
      title: 'Dynamic Scraping & Import Hub',
      currentPath: '/admin/import-hub',
      actions: [
        IconButton(
          tooltip: 'Refresh Catalogs',
          icon: const Icon(Icons.refresh_rounded, color: AppColors.neonBlue),
          onPressed: _refreshAll,
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        color: AppColors.neonPurple,
        backgroundColor: AppColors.surface,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Top Hero Banner
            _buildHeroBanner(isSyncing || isDeepScraping),
            const SizedBox(height: 16),

            // Mode Toggle Switch (Live Discovery vs Staged Review Hub)
            _buildModeToggle(activeTab),
            const SizedBox(height: 16),

            // Content based on active mode tab
            if (activeTab == 0) ...[
              _buildDiscoveryFilterBar(),
              const SizedBox(height: 16),
              _buildDiscoveryContent(),
            ] else ...[
              // Stats Row
              statsAsync.when(
                data: (stats) => StagedStatsRow(
                  stats: stats,
                  selectedStatus: ref.watch(stagedFilterStateProvider).status,
                  onStatusSelected: (status) {
                    final f = ref.read(stagedFilterStateProvider);
                    ref.read(stagedFilterStateProvider.notifier).state =
                        f.copyWith(status: status, clearStatus: status == null, page: 1);
                  },
                ),
                loading: () => const SizedBox(
                  height: 70,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonPurple),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              _buildStagedFilterBar(),
              const SizedBox(height: 16),
              _buildStagedEventsContent(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle(int activeTab) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF161026),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => ref.read(activeImportHubTabProvider.notifier).state = 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: activeTab == 0 ? AppColors.neonPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.travel_explore_rounded,
                      size: 16,
                      color: activeTab == 0 ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '1. Live Platform Discovery',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: activeTab == 0 ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => ref.read(activeImportHubTabProvider.notifier).state = 1,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: activeTab == 1 ? AppColors.neonPink : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_rounded,
                      size: 16,
                      color: activeTab == 1 ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '2. Staged Review & Production Import',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: activeTab == 1 ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.neonPurple.withValues(alpha: 0.22),
            AppColors.neonPink.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neonPurple.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.neonPurple, AppColors.neonPink],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.hub_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    const Text(
                      'Universal Dynamic Scraping Engine',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.neonPink.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.neonPink.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        'LIVE CATALOGS',
                        style: TextStyle(
                          color: AppColors.neonPink,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Explore live events on Showmates, BookMyShow, and District (Zomato). Selectively deep-scrape complete schedules, passes, and artist lineups into Staging DB.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- DISCOVERY TAB UI ---

  Widget _buildDiscoveryFilterBar() {
    final discFilter = ref.watch(discoveryFilterProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Source Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF161026),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: discFilter.source.toUpperCase(),
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: _sources.map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s == 'ALL'
                        ? 'All Platforms'
                        : s == 'SHOWMATES'
                            ? 'Showmates'
                            : s == 'BOOKMYSHOW'
                                ? 'BookMyShow'
                                : 'District (Zomato)'),
                  ),
                ).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(discoveryFilterProvider.notifier).state =
                        discFilter.copyWith(source: val.toLowerCase(), page: 1);
                  }
                },
              ),
            ),
          ),

          // City Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF161026),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: discFilter.city.toUpperCase(),
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: _cities.map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c == 'ALL' ? 'All Gujarat & Metro Cities' : c),
                  ),
                ).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(discoveryFilterProvider.notifier).state =
                        discFilter.copyWith(city: val, page: 1);
                  }
                },
              ),
            ),
          ),

          // Category Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF161026),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _categories.contains(discFilter.category) ? discFilter.category : 'ALL',
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: _categories.map(
                  (cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat == 'ALL' ? 'All Categories' : cat),
                  ),
                ).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(discoveryFilterProvider.notifier).state =
                        discFilter.copyWith(category: val, page: 1);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryContent() {
    final discAsync = ref.watch(discoveredEventsListProvider);
    final selectedDiscoveredSids = ref.watch(selectedDiscoveredItemIdsProvider);
    final isDeepScraping = ref.watch(isDeepScrapingProvider);

    return discAsync.when(
      data: (response) {
        final items = response.items;
        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Column(
              children: [
                Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 48),
                SizedBox(height: 12),
                Text(
                  'No Live Events Discovered',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  'Try selecting a different city or platform.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          );
        }

        final allSelected = items.isNotEmpty &&
            items.every((i) => selectedDiscoveredSids.contains(i.sourceEventId));
        final someSelected = selectedDiscoveredSids.isNotEmpty;

        return Column(
          children: [
            // Top Selection Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: someSelected
                    ? AppColors.neonPurple.withValues(alpha: 0.15)
                    : const Color(0xFF161026),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: someSelected
                      ? AppColors.neonPink.withValues(alpha: 0.5)
                      : AppColors.divider,
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: allSelected,
                        tristate: someSelected && !allSelected,
                        activeColor: AppColors.neonPink,
                        checkColor: Colors.white,
                        onChanged: (_) => _toggleDiscoveredSelectAll(items),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${selectedDiscoveredSids.length} of ${items.length} live events selected',
                        style: TextStyle(
                          color: someSelected ? Colors.white : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: someSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: isDeepScraping
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.bolt_rounded, size: 16),
                    label: Text(
                      isDeepScraping
                          ? 'Deep Scraping...'
                          : 'Deep Scrape Selected (${selectedDiscoveredSids.length})',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonPurple,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.surface,
                      disabledForegroundColor: AppColors.textMuted,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: (selectedDiscoveredSids.isEmpty || isDeepScraping)
                        ? null
                        : () => _handleDeepScrapeSelected(items),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Grid of Discovered Cards
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 1;
                if (constraints.maxWidth >= 1100) {
                  crossAxisCount = 3;
                } else if (constraints.maxWidth >= 700) {
                  crossAxisCount = 2;
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 320,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSel = selectedDiscoveredSids.contains(item.sourceEventId);
                    return DiscoveredEventCard(
                      item: item,
                      isSelected: isSel,
                      onSelectChanged: (val) =>
                          _toggleDiscoveredSingleSelect(item.sourceEventId, val ?? false),
                      onDeepScrapeSingle: () => _handleDeepScrapeSingle(item),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 350,
        child: LoadingView(message: 'Scanning live platform catalogs...'),
      ),
      error: (err, _) => SizedBox(
        height: 300,
        child: ErrorView(
          message: err.toString(),
          onRetry: _refreshAll,
        ),
      ),
    );
  }

  // --- STAGED EVENTS TAB UI ---

  Widget _buildStagedFilterBar() {
    final filter = ref.watch(stagedFilterStateProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;
        final searchField = TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: 'Search staged title, venue, city...',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textSecondary, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        color: AppColors.textMuted, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged();
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF161026),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.neonPurple, width: 1.5),
            ),
          ),
        );

        final statusDropdown = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF161026),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<StagedStatus?>(
              value: filter.status,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              hint: const Text('All Statuses',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Statuses'),
                ),
                ...StagedStatus.values.map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.displayName),
                  ),
                ),
              ],
              onChanged: (val) {
                ref.read(stagedFilterStateProvider.notifier).state =
                    filter.copyWith(status: val, clearStatus: val == null, page: 1);
              },
            ),
          ),
        );

        final sourceDropdown = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF161026),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: (filter.source != null && _sources.contains(filter.source!.toUpperCase()))
                  ? filter.source!.toUpperCase()
                  : 'ALL',
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              items: _sources.map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s == 'ALL'
                      ? 'All Sources'
                      : s == 'SHOWMATES'
                          ? 'Showmates'
                          : s == 'BOOKMYSHOW'
                              ? 'BookMyShow'
                              : 'District'),
                ),
              ).toList(),
              onChanged: (val) {
                final sourceVal = (val == null || val == 'ALL') ? null : val.toLowerCase();
                ref.read(stagedFilterStateProvider.notifier).state = filter.copyWith(
                  source: sourceVal,
                  clearSource: sourceVal == null,
                  page: 1,
                );
              },
            ),
          ),
        );

        final cityDropdown = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF161026),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: (filter.city != null && _cities.contains(filter.city!.toUpperCase()))
                  ? filter.city!.toUpperCase()
                  : 'ALL',
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              items: _cities.map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c == 'ALL' ? 'All Cities' : c),
                ),
              ).toList(),
              onChanged: (val) {
                final cityVal = (val == null || val == 'ALL') ? null : val;
                ref.read(stagedFilterStateProvider.notifier).state = filter.copyWith(
                  city: cityVal,
                  clearCity: cityVal == null,
                  page: 1,
                );
              },
            ),
          ),
        );

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchField,
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        statusDropdown,
                        sourceDropdown,
                        cityDropdown,
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 2, child: searchField),
                    const SizedBox(width: 10),
                    statusDropdown,
                    const SizedBox(width: 10),
                    sourceDropdown,
                    const SizedBox(width: 10),
                    cityDropdown,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildStagedEventsContent() {
    final stagedAsync = ref.watch(stagedEventsListProvider);
    final selectedIds = ref.watch(selectedStagedEventIdsProvider);
    final isImporting = ref.watch(isImportingStagedProvider);

    return stagedAsync.when(
      data: (response) {
        if (response.items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                const Icon(Icons.inbox_rounded, color: AppColors.textMuted, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'No Staged Events In Review',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Discover live events from platforms and deep-scrape them into this staging review hub.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.travel_explore_rounded, size: 16),
                  label: const Text('Go to Live Discovery'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonPurple),
                  onPressed: () => ref.read(activeImportHubTabProvider.notifier).state = 0,
                ),
              ],
            ),
          );
        }

        final allSelected = response.items.isNotEmpty &&
            response.items.every((e) => selectedIds.contains(e.id));
        final someSelected = selectedIds.isNotEmpty;

        return Column(
          children: [
            // Top Selection Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: someSelected
                    ? AppColors.neonPurple.withValues(alpha: 0.15)
                    : const Color(0xFF161026),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: someSelected
                      ? AppColors.neonPink.withValues(alpha: 0.5)
                      : AppColors.divider,
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: allSelected,
                        tristate: someSelected && !allSelected,
                        activeColor: AppColors.neonPink,
                        checkColor: Colors.white,
                        onChanged: (_) => _toggleSelectAll(response.items),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${selectedIds.length} of ${response.total} events selected',
                        style: TextStyle(
                          color: someSelected ? Colors.white : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: someSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                      if (someSelected) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            ref.read(selectedStagedEventIdsProvider.notifier).state = {};
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: isImporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.rocket_launch_rounded, size: 16),
                    label: Text(
                      isImporting
                          ? 'Importing...'
                          : 'Approve & Import Selected (${selectedIds.length})',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonPink,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.surface,
                      disabledForegroundColor: AppColors.textMuted,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: (selectedIds.isEmpty || isImporting)
                        ? null
                        : () => _openConfirmationDialog(response.items),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Grid
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 1;
                if (constraints.maxWidth >= 1100) {
                  crossAxisCount = 3;
                } else if (constraints.maxWidth >= 700) {
                  crossAxisCount = 2;
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 440,
                  ),
                  itemCount: response.items.length,
                  itemBuilder: (context, index) {
                    final event = response.items[index];
                    final isSelected = selectedIds.contains(event.id);
                    return StagedEventCard(
                      event: event,
                      isSelected: isSelected,
                      onSelectChanged: (val) =>
                          _toggleSingleSelect(event.id, val ?? false),
                      onPreview: () => _openDetailDialog(event),
                      onEdit: () => _openEditDialog(event),
                      onOpenSource: event.sourceUrl != null && event.sourceUrl!.isNotEmpty
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Source: ${event.sourceUrl}'),
                                  backgroundColor: AppColors.neonPurple,
                                ),
                              );
                            }
                          : null,
                    );
                  },
                );
              },
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 350,
        child: LoadingView(message: 'Loading staged events...'),
      ),
      error: (err, _) => SizedBox(
        height: 300,
        child: ErrorView(
          message: err.toString(),
          onRetry: _refreshAll,
        ),
      ),
    );
  }
}
