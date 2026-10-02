import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/staged_event_models.dart';

/// Service for communicating with both:
/// 1. Railway Staging & Sync FastAPI (for fetching, filtering, editing staged external events)
/// 2. VibeMyNight Spring Boot Production Backend (for executing Phase 2 secure batch import)
class StagingService {
  final ApiClient _adminClient;
  late final Dio _stagingDio;

  StagingService(this._adminClient, {Dio? stagingDio}) {
    _stagingDio = stagingDio ??
        Dio(
          BaseOptions(
            baseUrl: ApiConstants.stagingSyncBaseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            contentType: 'application/json',
          ),
        );
  }

  /// Fetches paginated staged events from the Staging & Sync API with optional filters.
  Future<StagedEventListResponse> fetchStagedEvents({
    StagedStatus? status,
    String? source,
    String? city,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (status != null) {
        queryParams['status'] = status.toApiString();
      }
      if (source != null && source.trim().isNotEmpty && source.toUpperCase() != 'ALL') {
        queryParams['source'] = source.trim().toLowerCase();
      }
      if (city != null && city.trim().isNotEmpty && city.toUpperCase() != 'ALL') {
        queryParams['city'] = city.trim();
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final response = await _stagingDio.get(
        ApiConstants.syncEvents,
        queryParameters: queryParams,
      );

      if (response.data is Map<String, dynamic>) {
        return StagedEventListResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ApiException('Invalid response format from Staging API');
    } on DioException catch (e) {
      String message = e.response?.data?['detail']?.toString() ??
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Failed to fetch staged events';

      if (e.type == DioExceptionType.connectionError ||
          message.contains('XMLHttpRequest') ||
          message.contains('Failed to fetch') ||
          message.contains('NetworkError')) {
        message =
            'Unable to reach Railway Staging Service at ${ApiConstants.stagingSyncBaseUrl}. Please ensure the Railway staging service is running and CORS is enabled.';
      }

      throw ApiException(
        message,
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Fetches a single staged event detail by ID.
  Future<StagedEvent> fetchStagedEventDetail(int id) async {
    try {
      final response = await _stagingDio.get(ApiConstants.syncEventById(id));
      if (response.data is Map<String, dynamic>) {
        return StagedEvent.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ApiException('Invalid staged event payload');
    } on DioException catch (e) {
      String message = e.response?.data?['detail']?.toString() ??
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Failed to fetch staged event details';
      if (e.type == DioExceptionType.connectionError ||
          message.contains('XMLHttpRequest') ||
          message.contains('Failed to fetch') ||
          message.contains('NetworkError')) {
        message =
            'Unable to reach Railway Staging Service at ${ApiConstants.stagingSyncBaseUrl}.';
      }
      throw ApiException(
        message,
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Updates a staged event before approving import.
  Future<StagedEvent> updateStagedEvent(int id, Map<String, dynamic> updateData) async {
    try {
      final response = await _stagingDio.put(
        ApiConstants.syncEventById(id),
        data: updateData,
      );
      if (response.data is Map<String, dynamic>) {
        return StagedEvent.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ApiException('Invalid update response from Staging API');
    } on DioException catch (e) {
      String message = e.response?.data?['detail']?.toString() ??
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Failed to update staged event';
      if (e.type == DioExceptionType.connectionError ||
          message.contains('XMLHttpRequest') ||
          message.contains('Failed to fetch') ||
          message.contains('NetworkError')) {
        message =
            'Unable to reach Railway Staging Service at ${ApiConstants.stagingSyncBaseUrl}.';
      }
      throw ApiException(
        message,
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Fetches staging status counts and stats.
  Future<StagedEventStats> fetchStats() async {
    try {
      final response = await _stagingDio.get(ApiConstants.syncStats);
      if (response.data is Map<String, dynamic>) {
        return StagedEventStats.fromJson(response.data as Map<String, dynamic>);
      }
      return const StagedEventStats();
    } on DioException {
      // Graceful fallback if stats endpoint has issue
      return const StagedEventStats();
    }
  }

  /// Triggers an immediate ingestion fetch from external sources (e.g. Showmates).
  Future<Map<String, dynamic>> triggerSyncFetch({String source = 'all'}) async {
    try {
      final response = await _stagingDio.post(
        ApiConstants.syncFetchNow,
        data: {'source': source},
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true, 'message': 'Sync completed'};
    } on DioException catch (e) {
      String message = e.response?.data?['detail']?.toString() ??
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Failed to trigger sync job';
      if (e.type == DioExceptionType.connectionError ||
          message.contains('XMLHttpRequest') ||
          message.contains('Failed to fetch') ||
          message.contains('NetworkError')) {
        message =
            'Unable to reach Railway Staging Service at ${ApiConstants.stagingSyncBaseUrl}. Please ensure the Railway service is deployed.';
      }
      throw ApiException(
        message,
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Clears non-imported staging events and re-fetches fresh multi-source events.
  Future<Map<String, dynamic>> resetAndFetchStagedEvents() async {
    try {
      final response = await _stagingDio.post('/sync/reset-and-fetch');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true, 'message': 'Reset & re-fetch completed'};
    } on DioException catch (e) {
      String message = e.response?.data?['detail']?.toString() ??
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Failed to reset and fetch events';
      throw ApiException(message, statusCode: e.response?.statusCode);
    }
  }

  /// Executes Phase 2 Secure Production Import Bridge via Spring Boot.
  /// Calls POST /api/v1/admin/events/import-staged.
  Future<StagedImportBatchResult> importStagedEvents(List<int> stagedEventIds) async {
    final response = await _adminClient.post(
      ApiConstants.adminStagedEventsImport,
      body: {'stagedEventIds': stagedEventIds},
    );
    if (response is Map<String, dynamic>) {
      return StagedImportBatchResult.fromJson(response);
    }
    throw const ApiException('Unexpected response from production import bridge');
  }

  /// Discovers live events from external sources without deep-scraping.
  Future<DiscoverEventsResponse> discoverEvents({
    String source = 'all',
    String? city,
    String? category,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'source': source.toLowerCase(),
        'page': page,
        'pageSize': pageSize,
      };
      if (city != null && city.trim().isNotEmpty && city.toUpperCase() != 'ALL') {
        queryParams['city'] = city.trim();
      }
      if (category != null && category.trim().isNotEmpty && category.toUpperCase() != 'ALL') {
        queryParams['category'] = category.trim();
      }

      final response = await _stagingDio.post(
        ApiConstants.syncDiscover,
        queryParameters: queryParams,
        data: {
          'source': source.toLowerCase(),
          'city': city,
          'category': category,
          'page': page,
          'pageSize': pageSize,
        },
      );

      if (response.data is Map<String, dynamic>) {
        return DiscoverEventsResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ApiException('Invalid discovery response format from Staging API');
    } on DioException catch (e) {
      String message = e.response?.data?['detail']?.toString() ??
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Failed to discover live events';
      if (e.type == DioExceptionType.connectionError ||
          message.contains('XMLHttpRequest') ||
          message.contains('Failed to fetch') ||
          message.contains('NetworkError')) {
        message =
            'Unable to reach Staging Service at ${ApiConstants.stagingSyncBaseUrl}.';
      }
      throw ApiException(message, statusCode: e.response?.statusCode);
    }
  }

  /// Deep scrapes selected discovered events and stages them for review.
  Future<DeepScrapeResponse> deepScrapeEvents({
    required List<DeepScrapeSelectedTarget> events,
    bool runAiEnrichment = true,
  }) async {
    try {
      final response = await _stagingDio.post(
        ApiConstants.syncDeepScrape,
        data: {
          'events': events.map((e) => e.toJson()).toList(),
          'run_ai_enrichment': runAiEnrichment,
        },
      );

      if (response.data is Map<String, dynamic>) {
        return DeepScrapeResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ApiException('Invalid deep scrape response format');
    } on DioException catch (e) {
      String message = e.response?.data?['detail']?.toString() ??
          e.response?.data?['message']?.toString() ??
          e.message ??
          'Failed to deep-scrape selected events';
      if (e.type == DioExceptionType.connectionError ||
          message.contains('XMLHttpRequest') ||
          message.contains('Failed to fetch') ||
          message.contains('NetworkError')) {
        message =
            'Unable to reach Staging Service at ${ApiConstants.stagingSyncBaseUrl}.';
      }
      throw ApiException(message, statusCode: e.response?.statusCode);
    }
  }
}

