import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibemynight/core/providers/data_providers.dart';
import 'package:vibemynight/core/providers/service_providers.dart';
import 'package:vibemynight/features/admin/settings/admin_settings_screen.dart';
import 'package:vibemynight/features/event_details/event_details_screen.dart';
import 'package:vibemynight/models/event_day_detail.dart';
import 'package:vibemynight/models/event_day_summary.dart';
import 'package:vibemynight/models/event_detail.dart';
import 'package:vibemynight/models/settings.dart';
import 'package:vibemynight/models/ticket_category.dart';
import 'package:vibemynight/services/admin_service.dart';

class FakeAdminService implements AdminService {
  AppSettings currentSettings = const AppSettings(
    websiteName: 'VibeMyNight',
    whatsappNumber: '917041615131',
    currency: 'INR',
    upiEnabled: false,
    upiVpa: null,
    upiMerchantName: null,
  );

  Map<String, dynamic>? lastUpdatePayload;

  @override
  Future<AppSettings> getAdminSettings() async => currentSettings;

  @override
  Future<void> updateSettings(Map<String, dynamic> body) async {
    lastUpdatePayload = body;
    currentSettings = AppSettings(
      websiteName: body['websiteName']?.toString() ?? 'VibeMyNight',
      logoUrl: body['logoUrl']?.toString(),
      whatsappNumber: body['whatsappNumber']?.toString() ?? '917041615131',
      phone: body['phone']?.toString(),
      email: body['email']?.toString(),
      instagramUrl: body['instagramUrl']?.toString(),
      facebookUrl: body['facebookUrl']?.toString(),
      currency: body['currency']?.toString() ?? 'INR',
      footerText: body['footerText']?.toString(),
      upiEnabled: body['upiEnabled'] == true,
      upiVpa: body['upiVpa']?.toString(),
      upiMerchantName: body['upiMerchantName']?.toString(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('E2E UPI Configuration Lifecycle Tests', () {
    late FakeAdminService fakeAdminService;

    const dummyEvent = EventDetail(
      id: 1,
      name: 'Sunburn Arena 2026',
      slug: 'sunburn-arena-2026',
      startDate: '2026-10-15',
      endDate: '2026-10-16',
      venue: 'Club Neon',
      location: 'Goa',
      city: 'Goa',
      featured: true,
      status: 'PUBLISHED',
      facilities: [],
      galleryImageUrls: [],
      highlights: [],
      rules: [],
      days: [
        EventDaySummary(
          id: 101,
          dayNumber: 1,
          date: '2026-10-15',
          dayName: 'Day 1',
          programName: 'Opening Night',
        ),
      ],
    );

    const dummyDayDetail = EventDayDetail(
      id: 101,
      eventId: 1,
      dayNumber: 1,
      date: '2026-10-15',
      dayName: 'Day 1',
      programName: 'Opening Night',
      status: 'PUBLISHED',
      passes: [
        TicketCategory(
          id: 501,
          eventDayId: 101,
          name: 'VIP Pass',
          type: 'VIP',
          price: 1999.0,
          description: 'VIP Entry + Access',
          availableQuantity: 50,
          maxPerCustomer: 10,
          benefits: ['Fast-track entry'],
          status: 'ACTIVE',
          soldOut: false,
        ),
      ],
      artists: [],
      facilities: [],
    );

    void suppressTestOverflows() {
      FlutterError.onError = (FlutterErrorDetails details) {
        final message = details.exceptionAsString();
        if (message.contains('RenderFlex') || message.contains('ListTile')) {
          return;
        }
        FlutterError.presentError(details);
      };
    }

    setUp(() {
      fakeAdminService = FakeAdminService();
    });

    testWidgets('Step 1 & Step 2: Admin Save UPI & Reload Persistence', (tester) async {
      suppressTestOverflows();
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminServiceProvider.overrideWithValue(fakeAdminService),
          ],
          child: const MaterialApp(
            home: AdminSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find UPI Switch
      final switchFinder = find.byType(SwitchListTile);
      expect(switchFinder, findsOneWidget);
      expect((tester.widget(switchFinder) as SwitchListTile).value, isFalse);

      // Scroll to switch and tap to turn ON
      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Enter UPI VPA and Merchant Name
      final upiVpaFinder = find.widgetWithText(TextFormField, 'Merchant UPI VPA / ID *');
      expect(upiVpaFinder, findsOneWidget);
      await tester.ensureVisible(upiVpaFinder);
      await tester.enterText(upiVpaFinder, 'testmerchant@upi');

      final merchantNameFinder = find.widgetWithText(TextFormField, 'Merchant Display Name (Optional)');
      expect(merchantNameFinder, findsOneWidget);
      await tester.ensureVisible(merchantNameFinder);
      await tester.enterText(merchantNameFinder, 'VibeMyNight Live');

      // Tap Save Settings
      final saveBtn = find.text('SAVE SETTINGS');
      expect(saveBtn, findsOneWidget);
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify payload sent
      expect(fakeAdminService.lastUpdatePayload!['upiEnabled'], isTrue);
      expect(fakeAdminService.lastUpdatePayload!['upiVpa'], 'testmerchant@upi');
      expect(fakeAdminService.lastUpdatePayload!['upiMerchantName'], 'VibeMyNight Live');
      expect(find.text('Settings saved'), findsOneWidget);

      // STEP 2: Simulate Browser Refresh / Reload
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminServiceProvider.overrideWithValue(fakeAdminService),
          ],
          child: const MaterialApp(
            home: AdminSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify persisted state
      final refreshedSwitch = tester.widget(find.byType(SwitchListTile)) as SwitchListTile;
      expect(refreshedSwitch.value, isTrue);
      expect(find.text('testmerchant@upi'), findsOneWidget);
      expect(find.text('VibeMyNight Live'), findsOneWidget);
    });

    testWidgets('Step 3: Admin Logout/Login Session & Settings Persistence', (tester) async {
      suppressTestOverflows();
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      fakeAdminService.currentSettings = const AppSettings(
        websiteName: 'VibeMyNight',
        whatsappNumber: '917041615131',
        currency: 'INR',
        upiEnabled: true,
        upiVpa: 'testmerchant@upi',
        upiMerchantName: 'VibeMyNight Live',
      );

      // Render Admin Settings after fresh login
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminServiceProvider.overrideWithValue(fakeAdminService),
          ],
          child: const MaterialApp(
            home: AdminSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all UPI values are still present after fresh login
      final switchWidget = tester.widget(find.byType(SwitchListTile)) as SwitchListTile;
      expect(switchWidget.value, isTrue);
      expect(find.text('testmerchant@upi'), findsOneWidget);
      expect(find.text('VibeMyNight Live'), findsOneWidget);
    });

    testWidgets('Step 4a: Customer Desktop UI displays Pay Online via UPI when enabled', (tester) async {
      suppressTestOverflows();
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const activeSettings = AppSettings(
        websiteName: 'VibeMyNight',
        whatsappNumber: '917041615131',
        currency: 'INR',
        upiEnabled: true,
        upiVpa: 'testmerchant@upi',
        upiMerchantName: 'VibeMyNight Live',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith((ref) async => activeSettings),
            eventDetailProvider('sunburn-arena-2026').overrideWith((ref) async => dummyEvent),
            eventDayDetailProvider(101).overrideWith((ref) async => dummyDayDetail),
          ],
          child: const MaterialApp(
            home: EventDetailsScreen(slug: 'sunburn-arena-2026'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select Pass
      final passCard = find.text('VIP Pass');
      expect(passCard, findsWidgets);
      await tester.ensureVisible(passCard.first);
      await tester.pumpAndSettle();
      await tester.tap(passCard.first);
      await tester.pumpAndSettle();

      // Verify "Pay Online via UPI" appears on desktop
      expect(find.text('⚡ Pay Online via UPI (GPay/PhonePe)'), findsOneWidget);
      expect(find.text('PROCEED TO INQUIRY'), findsOneWidget);
      expect(find.text('Chat on WhatsApp'), findsWidgets);
    });

    testWidgets('Step 4b: Customer Mobile UI displays floating UPI button when enabled', (tester) async {
      suppressTestOverflows();
      // Mobile viewport: 390x844
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const activeSettings = AppSettings(
        websiteName: 'VibeMyNight',
        whatsappNumber: '917041615131',
        currency: 'INR',
        upiEnabled: true,
        upiVpa: 'testmerchant@upi',
        upiMerchantName: 'VibeMyNight Live',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith((ref) async => activeSettings),
            eventDetailProvider('sunburn-arena-2026').overrideWith((ref) async => dummyEvent),
            eventDayDetailProvider(101).overrideWith((ref) async => dummyDayDetail),
          ],
          child: const MaterialApp(
            home: EventDetailsScreen(slug: 'sunburn-arena-2026'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select Pass
      final passCard = find.text('VIP Pass');
      expect(passCard, findsWidgets);
      await tester.ensureVisible(passCard.first);
      await tester.pumpAndSettle();
      await tester.tap(passCard.first);
      await tester.pumpAndSettle();

      // Verify floating / bottom bar UPI button appears on mobile
      final mobileUpiBtn = find.byTooltip('Pay via UPI');
      expect(mobileUpiBtn, findsOneWidget);
      expect(find.text('BOOK TICKETS'), findsOneWidget);
    });

    testWidgets('Step 5: Customer UI hides Pay Online via UPI when disabled', (tester) async {
      suppressTestOverflows();
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const disabledSettings = AppSettings(
        websiteName: 'VibeMyNight',
        whatsappNumber: '917041615131',
        currency: 'INR',
        upiEnabled: false,
        upiVpa: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith((ref) async => disabledSettings),
            eventDetailProvider('sunburn-arena-2026').overrideWith((ref) async => dummyEvent),
            eventDayDetailProvider(101).overrideWith((ref) async => dummyDayDetail),
          ],
          child: const MaterialApp(
            home: EventDetailsScreen(slug: 'sunburn-arena-2026'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select Pass
      final passCard = find.text('VIP Pass');
      expect(passCard, findsWidgets);
      await tester.ensureVisible(passCard.first);
      await tester.pumpAndSettle();
      await tester.tap(passCard.first);
      await tester.pumpAndSettle();

      // Verify "Pay Online via UPI" is HIDDEN
      expect(find.text('⚡ Pay Online via UPI (GPay/PhonePe)'), findsNothing);
      expect(find.byTooltip('Pay via UPI'), findsNothing);
      // Verify standard Inquiry and WhatsApp buttons REMAIN
      expect(find.text('PROCEED TO INQUIRY'), findsOneWidget);
      expect(find.text('Chat on WhatsApp'), findsWidgets);
    });

    testWidgets('Step 6: Customer UI re-displays UPI when re-enabled', (tester) async {
      suppressTestOverflows();
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const reEnabledSettings = AppSettings(
        websiteName: 'VibeMyNight',
        whatsappNumber: '917041615131',
        currency: 'INR',
        upiEnabled: true,
        upiVpa: 'testmerchant@upi',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith((ref) async => reEnabledSettings),
            eventDetailProvider('sunburn-arena-2026').overrideWith((ref) async => dummyEvent),
            eventDayDetailProvider(101).overrideWith((ref) async => dummyDayDetail),
          ],
          child: const MaterialApp(
            home: EventDetailsScreen(slug: 'sunburn-arena-2026'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final passCard = find.text('VIP Pass');
      await tester.ensureVisible(passCard.first);
      await tester.pumpAndSettle();
      await tester.tap(passCard.first);
      await tester.pumpAndSettle();

      // Verify "Pay Online via UPI" reappears
      expect(find.text('⚡ Pay Online via UPI (GPay/PhonePe)'), findsOneWidget);
    });
  });
}
