import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vibemynight/core/network/api_client.dart';
import 'package:vibemynight/core/providers/staged_event_providers.dart';
import 'package:vibemynight/features/admin/import_hub/admin_import_hub_screen.dart';
import 'package:vibemynight/features/admin/import_hub/dialogs/staged_event_detail_dialog.dart';
import 'package:vibemynight/features/admin/import_hub/widgets/discovered_event_card.dart';
import 'package:vibemynight/features/admin/import_hub/widgets/staged_stats_row.dart';
import 'package:vibemynight/models/staged_event_models.dart';
import 'package:vibemynight/services/staging_service.dart';

void main() {
  group('Phase 3 Staged Event Models & Universal Hierarchy Tests', () {
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

    test('StagedEvent JSON deserialization and full hierarchy accessors', () {
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
        'raw_payload': {
          'passes': [
            {
              'name': 'Female Season Pass',
              'type': 'SEASON',
              'price': 499.0,
              'available_quantity': 2000,
              'max_per_customer': 4,
              'benefits': ['9 Nights Entry'],
            }
          ],
          'artists': [
            {
              'name': 'Aishwarya Majmudar',
              'role': 'Lead Singer',
              'imageUrl': 'https://example.com/artist.jpg',
              'bio': 'Voice of Gujarat',
            }
          ],
          'days': [
            {
              'day_number': 1,
              'date': '2026-10-15',
              'day_name': 'Opening Night',
              'start_time': '19:30',
            }
          ],
          'facilities': ['AC Dome', 'Food Court'],
          'rules': ['Traditional dress compulsory'],
        },
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

      // Verify Hierarchy Accessors
      expect(event.passes.length, 1);
      expect(event.passes.first.name, 'Female Season Pass');
      expect(event.passes.first.availableQuantity, 2000);

      expect(event.artists.length, 1);
      expect(event.artists.first.name, 'Aishwarya Majmudar');

      expect(event.days.length, 1);
      expect(event.days.first.dayName, 'Opening Night');

      expect(event.facilities.length, 2);
      expect(event.rules.length, 1);
    });

    test('DiscoveredEventItem and DiscoverEventsResponse parsing', () {
      final discJson = {
        'success': true,
        'source': 'bookmyshow',
        'city': 'Vadodara',
        'total_discovered': 1,
        'items': [
          {
            'source': 'bookmyshow',
            'source_event_id': 'bms-vdr-01',
            'title': 'United Way of Baroda Garba 2026',
            'event_url': 'https://in.bookmyshow.com/events/united-way',
            'poster_url': 'https://example.com/bms_poster.jpg',
            'city': 'Vadodara',
            'venue_name': 'Navlakhi Ground',
            'starting_price': 799.0,
            'is_already_staged': true,
          }
        ],
        'timestamp': '2026-10-03T00:00:00',
      };

      final resp = DiscoverEventsResponse.fromJson(discJson);
      expect(resp.success, true);
      expect(resp.totalDiscovered, 1);
      expect(resp.items.first.title, 'United Way of Baroda Garba 2026');
      expect(resp.items.first.priceDisplay, 'From ₹799');
      expect(resp.items.first.isAlreadyStaged, true);
    });
  });

  group('Phase 3 StagingService Unit Tests', () {
    test('discoverEvents calls /sync/discover and parses response', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, contains('/sync/discover'));
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'source': 'all',
                  'total_discovered': 2,
                  'items': [
                    {
                      'source': 'showmates',
                      'source_event_id': 'sm-01',
                      'title': 'Showmates Event 1',
                      'event_url': 'https://showmates.in/1',
                      'starting_price': 499.0,
                    },
                    {
                      'source': 'bookmyshow',
                      'source_event_id': 'bms-01',
                      'title': 'BookMyShow Event 1',
                      'event_url': 'https://bms.in/1',
                      'starting_price': 799.0,
                    }
                  ],
                  'timestamp': '2026-10-03',
                },
              ),
            );
          },
        ),
      );

      final stagingService = StagingService(ApiClient.withDio(Dio()), stagingDio: dio);
      final res = await stagingService.discoverEvents(city: 'Ahmedabad');

      expect(res.success, true);
      expect(res.totalDiscovered, 2);
      expect(res.items.length, 2);
      expect(res.items.first.title, 'Showmates Event 1');
    });

    test('deepScrapeEvents calls /sync/deep-scrape and parses response', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, contains('/sync/deep-scrape'));
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'total_requested': 1,
                  'total_staged': 1,
                  'total_duplicates': 0,
                  'total_failed': 0,
                  'results': [
                    {
                      'source': 'showmates',
                      'source_event_id': 'sm-01',
                      'staging_id': 105,
                      'title': 'Showmates Event 1',
                      'status': 'PENDING_REVIEW',
                      'validation_status': 'VALID',
                      'is_duplicate': false,
                    }
                  ],
                  'message': 'Deep scraping completed',
                },
              ),
            );
          },
        ),
      );

      final stagingService = StagingService(ApiClient.withDio(Dio()), stagingDio: dio);
      final res = await stagingService.deepScrapeEvents(
        events: const [
          DeepScrapeSelectedTarget(
            source: 'showmates',
            sourceEventId: 'sm-01',
            eventUrl: 'https://showmates.in/1',
          )
        ],
      );

      expect(res.success, true);
      expect(res.totalStaged, 1);
      expect(res.results.first.stagingId, 105);
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

    testWidgets('DiscoveredEventCard renders and triggers selection', (tester) async {
      const item = DiscoveredEventItem(
        source: 'bookmyshow',
        sourceEventId: 'bms-101',
        title: 'United Way of Baroda Garba 2026',
        eventUrl: 'https://in.bookmyshow.com/1',
        city: 'Vadodara',
        venueName: 'Navlakhi Ground',
        startingPrice: 799.0,
      );

      bool selected = false;
      bool scrapedSingle = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              height: 400,
              child: DiscoveredEventCard(
                item: item,
                isSelected: false,
                onSelectChanged: (val) => selected = val ?? false,
                onDeepScrapeSingle: () => scrapedSingle = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('United Way of Baroda Garba 2026'), findsOneWidget);
      expect(find.text('BOOKMYSHOW'), findsOneWidget);
      expect(find.text('From ₹799'), findsOneWidget);

      // Tap checkbox
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(selected, true);

      // Tap single scrape
      await tester.tap(find.text('Scrape'));
      await tester.pump();
      expect(scrapedSingle, true);
    });

    testWidgets('StagedEventDetailDialog displays full 5-tab details and AI copy', (tester) async {
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

      expect(find.textContaining('Staged Event #101'), findsOneWidget);
      expect(find.textContaining('✨ AI Enhanced Garba 2026'), findsNWidgets(2));
      expect(find.text('🔥 Book now for the best passes!'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Passes (0)'), findsOneWidget);
      expect(find.text('Artists (0)'), findsOneWidget);
      expect(find.text('Days (0)'), findsOneWidget);
      expect(find.text('Rules & Perks (0)'), findsOneWidget);
    });

    testWidgets('AdminImportHubScreen renders Discovery mode and Staging Review mode cleanly', (tester) async {
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
            activeImportHubTabProvider.overrideWith((ref) => 1),
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

      expect(find.text('Universal Dynamic Scraping Engine'), findsOneWidget);
      expect(find.text('✨ Surat Navratri Mahotsav'), findsOneWidget);
      expect(find.text('0 of 1 events selected'), findsOneWidget);

      // Select event card
      await tester.tap(find.text('✨ Surat Navratri Mahotsav'));
      await tester.pumpAndSettle();

      expect(find.text('1 of 1 events selected'), findsOneWidget);
      expect(find.text('Approve & Import Selected (1)'), findsOneWidget);
    });
  });
}
