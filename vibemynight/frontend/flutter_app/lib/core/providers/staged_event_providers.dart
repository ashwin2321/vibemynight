import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/staged_event_models.dart';
import 'data_providers.dart';
import 'service_providers.dart';

/// Filter parameters for querying staged events.
class StagedEventFilterParams {
  final StagedStatus? status;
  final String? source;
  final String? city;
  final String? search;
  final int page;
  final int pageSize;

  const StagedEventFilterParams({
    this.status,
    this.source,
    this.city,
    this.search,
    this.page = 1,
    this.pageSize = 20,
  });

  StagedEventFilterParams copyWith({
    StagedStatus? status,
    String? source,
    String? city,
    String? search,
    int? page,
    int? pageSize,
    bool clearStatus = false,
    bool clearSource = false,
    bool clearCity = false,
    bool clearSearch = false,
  }) {
    return StagedEventFilterParams(
      status: clearStatus ? null : (status ?? this.status),
      source: clearSource ? null : (source ?? this.source),
      city: clearCity ? null : (city ?? this.city),
      search: clearSearch ? null : (search ?? this.search),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StagedEventFilterParams &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          source == other.source &&
          city == other.city &&
          search == other.search &&
          page == other.page &&
          pageSize == other.pageSize;

  @override
  int get hashCode => Object.hash(status, source, city, search, page, pageSize);
}

/// Active filter state on the Admin Import Hub screen.
final stagedFilterStateProvider = StateProvider<StagedEventFilterParams>(
  (ref) => const StagedEventFilterParams(status: StagedStatus.pendingReview),
);

/// Paginated list of staged events based on current active filter.
final stagedEventsListProvider =
    FutureProvider.autoDispose<StagedEventListResponse>((ref) {
  ref.cacheFor(const Duration(seconds: 30));
  final filter = ref.watch(stagedFilterStateProvider);
  final service = ref.watch(stagingServiceProvider);
  return service.fetchStagedEvents(
    status: filter.status,
    source: filter.source,
    city: filter.city,
    search: filter.search,
    page: filter.page,
    pageSize: filter.pageSize,
  );
});

/// Overall stats for staged events (total, pending, imported, rejected, conflicts).
final stagedStatsProvider = FutureProvider.autoDispose<StagedEventStats>((ref) {
  ref.cacheFor(const Duration(seconds: 30));
  final service = ref.watch(stagingServiceProvider);
  return service.fetchStats();
});

/// Set of selected staged event IDs on the Import Hub.
final selectedStagedEventIdsProvider = StateProvider<Set<int>>((ref) => <int>{});

/// Active batch import result state (if an import just completed).
final lastImportBatchResultProvider =
    StateProvider<StagedImportBatchResult?>((ref) => null);

/// True when batch import is executing.
final isImportingStagedProvider = StateProvider<bool>((ref) => false);

/// True when sync fetch is executing.
final isSyncingStagedProvider = StateProvider<bool>((ref) => false);

// =========================================================================
// UNIVERSAL LIVE DISCOVERY & SELECTIVE DEEP SCRAPING STATE
// =========================================================================

/// Parameters for live catalog discovery.
class DiscoveryFilterParams extends Equatable {
  final String source;
  final String city;
  final String category;
  final int page;
  final int pageSize;

  const DiscoveryFilterParams({
    this.source = 'all',
    this.city = 'ALL',
    this.category = 'ALL',
    this.page = 1,
    this.pageSize = 20,
  });

  DiscoveryFilterParams copyWith({
    String? source,
    String? city,
    String? category,
    int? page,
    int? pageSize,
  }) {
    return DiscoveryFilterParams(
      source: source ?? this.source,
      city: city ?? this.city,
      category: category ?? this.category,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [source, city, category, page, pageSize];
}

/// Active discovery filter state.
final discoveryFilterProvider = StateProvider<DiscoveryFilterParams>(
  (ref) => const DiscoveryFilterParams(),
);

/// Discovered events list from live platforms.
final discoveredEventsListProvider =
    FutureProvider.autoDispose<DiscoverEventsResponse>((ref) {
  ref.cacheFor(const Duration(seconds: 30));
  final filter = ref.watch(discoveryFilterProvider);
  final service = ref.watch(stagingServiceProvider);
  return service.discoverEvents(
    source: filter.source,
    city: filter.city == 'ALL' ? null : filter.city,
    category: filter.category == 'ALL' ? null : filter.category,
    page: filter.page,
    pageSize: filter.pageSize,
  );
});

/// Set of selected discovered event IDs for deep-scraping.
final selectedDiscoveredItemIdsProvider = StateProvider<Set<String>>((ref) => <String>{});

/// True when deep-scraping is executing.
final isDeepScrapingProvider = StateProvider<bool>((ref) => false);

/// Active mode tab on the Import Hub (0: Live Discovery, 1: Staging Review Hub).
final activeImportHubTabProvider = StateProvider<int>((ref) => 0);
