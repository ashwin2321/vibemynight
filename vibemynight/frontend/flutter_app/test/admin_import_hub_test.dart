import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vibemynight/core/network/api_client.dart';
import 'package:vibemynight/core/network/api_exception.dart';
import 'package:vibemynight/core/providers/staged_event_providers.dart';
import 'package:vibemynight/features/admin/import_hub/admin_import_hub_screen.dart';
import 'package:vibemynight/features/admin/import_hub/dialogs/import_confirmation_dialog.dart';
import 'package:vibemynight/features/admin/import_hub/dialogs/import_result_dialog.dart';
import 'package:vibemynight/features/admin/import_hub/dialogs/staged_event_detail_dialog.dart';
import 'package:vibemynight/features/admin/import_hub/dialogs/staged_event_edit_dialog.dart';
import 'package:vibemynight/features/admin/import_hub/widgets/staged_event_card.dart';
import 'package:vibemynight/features/admin/import_hub/widgets/staged_stats_row.dart';
import 'package:vibemynight/models/staged_event_models.dart';
import 'package:vibemynight/services/staging_service.dart';

void main() {
  group('Phase 3 Staged Event Models & Enum Tests', () {
    test('StagedStatus enum mappings', () {
      expect(StagedStatus.fromString('PENDING_REVIEW'), StagedStatus.pendingReview);
      expect(StagedStatus.fromString('APPROVED'), StagedStatus.approved);
      expect(StagedStatus.fromString('IMPORTED'), StagedStatus.imported);
      expect(StagedStatus.fromString('REJECTED'), StagedStatus.rejected);
      expect(StagedStatus.fromString('CONFLICT'), StagedStatus.conflict);
      expect(StagedStatus.fromString('unknown_val'), StagedStatus.pendingReview);
      expect(StagedStatus.fromString(null), StagedStatus.pendingReview);

      expect(StagedStatus.pendingReview.toApiString(), 'PENDING_REVIEW');
      expect(StagedStatus.approved.toApiString(), 'APPROVED');
      expect(StagedStatus.imported.toApiString(), 'IMPORTED');
      expect(StagedStatus.rejected.toApiString(), 'REJECTED');
      expect(StagedStatus.conflict.toApiString(), 'CONFLICT');

      expect(StagedStatus.pendingReview.displayName, 'Pending Review');
      expect(StagedStatus.imported.displayName, 'Imported');
    });

    test('StagedEvent JSON deserialization and serialization', () {
      final json = {
        'id': 101,
        'source': 'showmates',
        'source_event_id': 'sm-999',
        'source_url': 'https://showmates.in/events/999',
        'title': 'Original Navratri Garba 2026',
        'description': 'Original description text',
        'enhanced_title': '🔥 Grand Surat Navratri Mahotsav 2026',
        'catchy_description': 'Experience the grandest dandiya celebration in Surat!',
        'highlights': ['AC Dome', 'Free Parking', 'Live Orchestra'],
        'genre_tags': ['Garba', 'Dandiya', 'Live Music'],
        'seo_keywords': ['surat garba', 'navratri pass 2026'],
        'whatsapp_teaser': '🔥 Surat\'s biggest Garba is here! Book now 👇',
        'poster_url': 'https://images.example.com/poster.jpg',
        'banner_url': 'https://images.example.com/banner.jpg',
        'event_start_date': '2026-10-15',
        'event_end_date': '2026-10-24',
        'start_time': '19:00',
        'end_time': '23:30',
        'venue_name': 'Surat Dome Ground',
        'venue_address': 'VIP Road, Vesu',
        'city': 'Surat',
        'state': 'Gujarat',
        'min_ticket_price': 499.0,
        'max_ticket_price': 1499.0,
        'currency': 'INR',
        'status': 'PENDING_REVIEW',
        'duplicate_of': null,
        'ai_processed': true,
        'ai_provider': 'google_gemini',
        'ai_model': 'gemini-1.5-flash',
      };

      final event = StagedEvent.fromJson(json);

      expect(event.id, 101);
      expect(event.source, 'showmates');
      expect(event.sourceEventId, 'sm-999');
      expect(event.displayTitle, '🔥 Grand Surat Navratri Mahotsav 2026');
      expect(event.displayDescription,
          'Experience the grandest dandiya celebration in Surat!');
      expect(event.highlights.length, 3);
      expect(event.genreTags.length, 3);
      expect(event.priceDisplay, '₹499 - ₹1499');
      expect(event.aiProcessed, true);
      expect(event.status, StagedStatus.pendingReview);

      final outJson = event.toJson();
      expect(outJson['id'], 101);
      expect(outJson['title'], 'Original Navratri Garba 2026');
      expect(outJson['status'], 'PENDING_REVIEW');
    });

    test('StagedEvent priceDisplay handles single and null prices', () {
      const eSingle = StagedEvent(
        id: 1,
        source: 'test',
        sourceEventId: '1',
        title: 'Single Price Event',
        minTicketPrice: 499.0,
        maxTicketPrice: 499.0,
      );
      expect(eSingle.priceDisplay, '₹499');

      const eTba = StagedEvent(
        id: 2,
        source: 'test',
        sourceEventId: '2',
        title: 'TBA Price Event',
      );
      expect(eTba.priceDisplay, 'Price TBA');
    });

    test('StagedEventListResponse and Stats deserialization', () {
      final listJson = {
        'items': [
          {
            'id': 1,
            'source': 'showmates',
            'source_event_id': 'sm-1',
            'title': 'Event 1',
            'status': 'PENDING_REVIEW',
            'ai_processed': false,
          },
          {
            'id': 2,
            'source': 'showmates',
            'source_event_id': 'sm-2',
            'title': 'Event 2',
            'status': 'IMPORTED',
            'ai_processed': true,
          }
        ],
        'total': 2,
        'page': 1,
        'page_size': 20,
        'total_pages': 1,
      };

      final response = StagedEventListResponse.fromJson(listJson);
      expect(response.total, 2);
      expect(response.items.length, 2);
      expect(response.items.first.title, 'Event 1');

      final statsJson = {
        'total': 50,
        'pending': 35,
        'imported': 10,
        'conflicts': 3,
        'rejected': 2,
      };
      final stats = StagedEventStats.fromJson(statsJson);
      expect(stats.total, 50);
      expect(stats.pending, 35);
      expect(stats.imported, 10);
      expect(stats.conflicts, 3);
      expect(stats.rejected, 2);
    });

    test('StagedImportBatchResult deserialization and item helper properties', () {
      final batchJson = {
        'totalRequested': 3,
        'imported': 2,
        'alreadyImported': 0,
        'conflicts': 1,
        'failed': 0,
        'results': [
          {
            'stagedEventId': 101,
            'status': 'SUCCESS',
            'productionEventId': 42,
            'eventName': 'Surat Garba Night',
            'slug': 'surat-garba-night',
          },
          {
            'stagedEventId': 102,
            'status': 'CONFLICT',
            'productionEventId': 43,
            'eventName': 'Surat Garba Night 2',
            'slug': 'surat-garba-night-2',
            'reason': 'Slug conflict resolved with suffix',
          },
          {
            'stagedEventId': 103,
            'status': 'ALREADY_IMPORTED',
            'eventName': 'Surat Garba Night 3',
            'slug': 'surat-garba-night-3',
            'reason': 'Event was already imported into production',
          },
        ],
      };

      final batchResult = StagedImportBatchResult.fromJson(batchJson);
      expect(batchResult.totalRequested, 3);
      expect(batchResult.imported, 2);
      expect(batchResult.conflicts, 1);
      expect(batchResult.results.length, 3);

      expect(batchResult.results[0].isSuccess, true);
      expect(batchResult.results[0].productionEventId, 42);
      expect(batchResult.results[1].isConflict, true);
      expect(batchResult.results[2].isAlreadyImported, true);
      expect(batchResult.results[2].isFailed, false);
    });
  });

  group('Phase 3 StagingService Unit Tests', () {
    test('fetchStagedEvents calls staging API and parses response', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'items': [
                    {
                      'id': 101,
                      'source': 'showmates',
                      'source_event_id': 'sm-101',
                      'title': 'Test Staged Event',
                      'city': 'Surat',
                      'status': 'PENDING_REVIEW',
                      'ai_processed': true,
                      'enhanced_title': 'Enhanced Test Staged Event',
                    }
                  ],
                  'total': 1,
                  'page': 1,
                  'page_size': 20,
                  'total_pages': 1,
                },
              ),
            );
          },
        ),
      );

      final adminDio = Dio();
      final adminClient = ApiClient.withDio(adminDio);
      final stagingService = StagingService(adminClient, stagingDio: dio);

      final response = await stagingService.fetchStagedEvents(
        status: StagedStatus.pendingReview,
        city: 'Surat',
        search: 'Test',
      );

      expect(response.total, 1);
      expect(response.items.first.id, 101);
      expect(response.items.first.displayTitle, 'Enhanced Test Staged Event');
    });

    test('updateStagedEvent calls PUT /sync/events/:id', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'PUT');
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 101,
                  'source': 'showmates',
                  'source_event_id': 'sm-101',
                  'title': 'Updated Title',
                  'status': 'APPROVED',
                  'ai_processed': true,
                },
              ),
            );
          },
        ),
      );

      final adminClient = ApiClient.withDio(Dio());
      final stagingService = StagingService(adminClient, stagingDio: dio);

      final updated = await stagingService.updateStagedEvent(101, {
        'title': 'Updated Title',
      });

      expect(updated.title, 'Updated Title');
      expect(updated.status, StagedStatus.approved);
    });

    test('importStagedEvents calls Spring Boot POST /api/v1/admin/events/import-staged', () async {
      final adminDio = Dio();
      adminDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'POST');
            expect(options.path, '/admin/events/import-staged');
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'totalRequested': 2,
                    'imported': 2,
                    'alreadyImported': 0,
                    'conflicts': 0,
                    'failed': 0,
                    'results': [
                      {
                        'stagedEventId': 101,
                        'status': 'SUCCESS',
                        'productionEventId': 1,
                        'eventName': 'Event 1',
                        'slug': 'event-1',
                      },
                      {
                        'stagedEventId': 102,
                        'status': 'SUCCESS',
                        'productionEventId': 2,
                        'eventName': 'Event 2',
                        'slug': 'event-2',
                      },
                    ],
                  },
                },
              ),
            );
          },
        ),
      );

      final adminClient = ApiClient.withDio(adminDio);
      final stagingService = StagingService(adminClient, stagingDio: Dio());

      final result = await stagingService.importStagedEvents([101, 102]);

      expect(result.totalRequested, 2);
      expect(result.imported, 2);
      expect(result.results.length, 2);
      expect(result.results.first.isSuccess, true);
    });
  });

  group('Phase 3 Widget & Dialog Tests', () {
    testWidgets('StagedStatsRow renders count cards and triggers callback', (tester) async {
      const stats = StagedEventStats(
        total: 25,
        pending: 15,
        imported: 8,
        conflicts: 1,
        rejected: 1,
      );

      StagedStatus? tappedStatus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StagedStatsRow(
              stats: stats,
              selectedStatus: StagedStatus.pendingReview,
              onStatusSelected: (s) => tappedStatus = s,
            ),
          ),
        ),
      );

      expect(find.text('Total Staged'), findsOneWidget);
      expect(find.text('Pending Review'), findsOneWidget);
      expect(find.text('Imported Live'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);

      await tester.tap(find.text('Imported Live'));
      await tester.pump();

      expect(tappedStatus, StagedStatus.imported);
    });

    testWidgets('StagedEventCard renders and triggers callbacks', (tester) async {
      const event = StagedEvent(
        id: 101,
        source: 'showmates',
        sourceEventId: 'sm-101',
        title: 'Original Title',
        enhancedTitle: '✨ AI Enhanced Title',
        city: 'Surat',
        venueName: 'Surat Arena',
        minTicketPrice: 499.0,
        maxTicketPrice: 999.0,
        aiProcessed: true,
        status: StagedStatus.pendingReview,
      );

      bool selected = false;
      bool previewTriggered = false;
      bool editTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              height: 450,
              child: StagedEventCard(
                event: event,
                isSelected: false,
                onSelectChanged: (val) => selected = val ?? false,
                onPreview: () => previewTriggered = true,
                onEdit: () => editTriggered = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('✨ AI Enhanced Title'), findsOneWidget);
      expect(find.text('Gemini Enriched'), findsOneWidget);
      expect(find.text('₹499 - ₹999'), findsOneWidget);
      expect(find.text('Surat Arena'), findsOneWidget);

      // Tap preview
      await tester.tap(find.text('Preview'));
      await tester.pump();
      expect(previewTriggered, true);

      // Tap edit
      await tester.tap(find.text('Edit'));
      await tester.pump();
      expect(editTriggered, true);

      // Tap checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(selected, true);
    });

    testWidgets('StagedEventDetailDialog displays full details and AI copy', (tester) async {
      const event = StagedEvent(
        id: 101,
        source: 'showmates',
        sourceEventId: 'sm-101',
        title: 'Original Title',
        enhancedTitle: '✨ AI Enhanced Garba 2026',
        catchyDescription: 'Surat\'s biggest festival celebration!',
        whatsAppTeaser: '🔥 Book now for the best passes!',
        highlights: ['AC Dome', 'VIP Lounge'],
        genreTags: ['Garba', 'DJ Night'],
        city: 'Surat',
        venueName: 'Surat Arena',
      );

      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StagedEventDetailDialog(
              event: event,
              onEdit: () {},
            ),
          ),
        ),
      );

      expect(find.text('Staged Event #101 Details'), findsOneWidget);
      expect(find.text('✨ AI Enhanced Garba 2026'), findsOneWidget);
      expect(find.text('🔥 Book now for the best passes!'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('AC Dome'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('AC Dome'), findsOneWidget);
      expect(find.text('Garba'), findsOneWidget);
    });

    testWidgets('StagedEventEditDialog renders and submits updated fields', (tester) async {
      const event = StagedEvent(
        id: 101,
        source: 'showmates',
        sourceEventId: 'sm-101',
        title: 'Original Title',
        city: 'Surat',
      );

      Map<String, dynamic>? savedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StagedEventEditDialog(
              event: event,
              onSave: (data) async {
                savedData = data;
              },
            ),
          ),
        ),
      );

      expect(find.text('Quick Edit Staged Event'), findsOneWidget);
      expect(find.text('Save Staged Changes'), findsOneWidget);

      await tester.tap(find.text('Save Staged Changes'));
      await tester.pumpAndSettle();

      expect(savedData, isNotNull);
      expect(savedData!['title'], 'Original Title');
    });

    testWidgets('ImportConfirmationDialog shows selected count and confirms', (tester) async {
      const event1 = StagedEvent(
        id: 101,
        source: 'showmates',
        sourceEventId: 'sm-1',
        title: 'Event One',
      );
      const event2 = StagedEvent(
        id: 102,
        source: 'showmates',
        sourceEventId: 'sm-2',
        title: 'Event Two',
      );

      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportConfirmationDialog(
              selectedEvents: const [event1, event2],
              onConfirm: () => confirmed = true,
            ),
          ),
        ),
      );

      expect(find.text('Confirm Live Production Import'), findsOneWidget);
      expect(find.text('Event One'), findsOneWidget);
      expect(find.text('Event Two'), findsOneWidget);
      expect(find.text('Import 2 Events Now'), findsOneWidget);

      await tester.tap(find.text('Import 2 Events Now'));
      await tester.pump();

      expect(confirmed, true);
    });

    testWidgets('ImportResultDialog renders results summary and items', (tester) async {
      const result = StagedImportBatchResult(
        totalRequested: 2,
        imported: 1,
        alreadyImported: 0,
        conflicts: 1,
        failed: 0,
        results: [
          StagedEventImportResultItem(
            stagedEventId: 101,
            status: 'SUCCESS',
            productionEventId: 42,
            eventName: 'Success Event',
            slug: 'success-event',
          ),
          StagedEventImportResultItem(
            stagedEventId: 102,
            status: 'CONFLICT',
            productionEventId: 43,
            eventName: 'Conflict Event',
            slug: 'conflict-event-1',
            reason: 'Slug adjusted',
          ),
        ],
      );

      bool viewed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportResultDialog(
              result: result,
              onViewProductionEvents: () => viewed = true,
            ),
          ),
        ),
      );

      expect(find.text('Import Execution Report'), findsOneWidget);
      expect(find.text('Success Event'), findsOneWidget);
      expect(find.text('Conflict Event'), findsOneWidget);
      expect(find.text('Slug adjusted'), findsOneWidget);

      await tester.tap(find.text('View in Production Events'));
      await tester.pump();

      expect(viewed, true);
    });

    testWidgets('AdminImportHubScreen renders header and empty state cleanly', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            stagedEventsListProvider.overrideWith((ref) async {
              return const StagedEventListResponse(
                items: [],
                total: 0,
                page: 1,
                pageSize: 20,
                totalPages: 1,
              );
            }),
            stagedStatsProvider.overrideWith((ref) async {
              return const StagedEventStats();
            }),
          ],
          child: const MaterialApp(
            home: AdminImportHubScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Railway Staging & Gemini AI Pipeline'), findsOneWidget);
      expect(find.text('No Staged Events Found'), findsOneWidget);
    });

    testWidgets('AdminImportHubScreen renders loaded grid and allows selection', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const sampleEvent = StagedEvent(
        id: 101,
        source: 'showmates',
        sourceEventId: 'sm-101',
        title: 'Surat Navratri Mahotsav',
        enhancedTitle: '✨ Surat Navratri Mahotsav',
        city: 'Surat',
        status: StagedStatus.pendingReview,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            stagedEventsListProvider.overrideWith((ref) async {
              return const StagedEventListResponse(
                items: [sampleEvent],
                total: 1,
                page: 1,
                pageSize: 20,
                totalPages: 1,
              );
            }),
            stagedStatsProvider.overrideWith((ref) async {
              return const StagedEventStats(total: 1, pending: 1);
            }),
          ],
          child: const MaterialApp(
            home: AdminImportHubScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('✨ Surat Navratri Mahotsav'), findsOneWidget);
      expect(find.text('0 of 1 events selected'), findsOneWidget);

      // Select event card
      await tester.tap(find.text('✨ Surat Navratri Mahotsav'));
      await tester.pumpAndSettle();

      expect(find.text('1 of 1 events selected'), findsOneWidget);
      expect(find.text('Approve & Import Selected (1)'), findsOneWidget);
    });

    test('StagedEventFilterParams copyWith and equality tests', () {
      const p1 = StagedEventFilterParams(
        status: StagedStatus.pendingReview,
        city: 'Surat',
        search: 'Garba',
        page: 1,
        pageSize: 20,
      );

      final p2 = p1.copyWith(city: 'Ahmedabad');
      expect(p2.city, 'Ahmedabad');
      expect(p2.status, StagedStatus.pendingReview);
      expect(p2.search, 'Garba');

      final p3 = p1.copyWith(clearStatus: true, clearSearch: true);
      expect(p3.status, isNull);
      expect(p3.search, isNull);
      expect(p3.city, 'Surat');
    });

    test('StagingService handles 401, 403, 409, 500 error responses gracefully', () async {
      for (final statusCode in [401, 403, 404, 409, 500]) {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: statusCode,
                    data: {'detail': 'HTTP error $statusCode'},
                  ),
                ),
              );
            },
          ),
        );

        final client = ApiClient.withDio(Dio());
        final service = StagingService(client, stagingDio: dio);

        expect(
          () => service.fetchStagedEvents(),
          throwsA(predicate((e) => e is ApiException && e.statusCode == statusCode)),
        );
      }
    });
  });
}


