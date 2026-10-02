import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/staged_event_models.dart';
import 'data_providers.dart';
import 'service_providers.dart';

/// Filter parameters for querying staged events.
class StagedEventFilterParams {
  final StagedStatus? status;
  final String? city;
  final String? search;
  final int page;
  final int pageSize;

  const StagedEventFilterParams({
    this.status,
    this.city,
    this.search,
    this.page = 1,
    this.pageSize = 20,
  });

  StagedEventFilterParams copyWith({
    StagedStatus? status,
    String? city,
    String? search,
    int? page,
    int? pageSize,
    bool clearStatus = false,
    bool clearCity = false,
    bool clearSearch = false,
  }) {
    return StagedEventFilterParams(
      status: clearStatus ? null : (status ?? this.status),
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
          city == other.city &&
          search == other.search &&
          page == other.page &&
          pageSize == other.pageSize;

  @override
  int get hashCode => Object.hash(status, city, search, page, pageSize);
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
