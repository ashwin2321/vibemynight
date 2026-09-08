import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibemynight/core/providers/data_providers.dart';
import 'package:vibemynight/core/widgets/app_footer.dart';
import 'package:vibemynight/core/widgets/error_view.dart';
import 'package:vibemynight/core/widgets/glass_card.dart';
import 'package:vibemynight/core/widgets/gradient_button.dart';
import 'package:vibemynight/core/widgets/loading_view.dart';
import 'package:vibemynight/features/admin/widgets/status_badge.dart';
import 'package:vibemynight/models/settings.dart';

void main() {
  group('Core UI Widget Tests', () {
    testWidgets('StatusBadge renders correct label and colors for PUBLISHED', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: 'PUBLISHED'),
          ),
        ),
      );

      expect(find.text('PUBLISHED'), findsOneWidget);
    });

    testWidgets('StatusBadge renders for DRAFT and CANCELLED', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge(status: 'DRAFT'),
                StatusBadge(status: 'CANCELLED'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('DRAFT'), findsOneWidget);
      expect(find.text('CANCELLED'), findsOneWidget);
    });

    testWidgets('GradientButton renders label and responds to tap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradientButton(
              label: 'EXPLORE EVENTS',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('EXPLORE EVENTS'), findsOneWidget);
      await tester.tap(find.text('EXPLORE EVENTS'));
      expect(tapped, isTrue);
    });

    testWidgets('GradientButton shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GradientButton(
              label: 'Submit',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('GlassCard renders child content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: Text('Glass Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Glass Card Content'), findsOneWidget);
    });

    testWidgets('ErrorView renders error message and retry button', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'Failed to load events',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Failed to load events'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);
    });

    testWidgets('LoadingView renders CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingView(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AppFooter renders brand, quick links and copyright', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appSettingsProvider.overrideWith((ref) async => const AppSettings(
                  websiteName: 'VibeMyNight',
                  whatsappNumber: '917041615131',
                  currency: 'INR',
                  footerText: '© 2026 VibeMyNight. All rights reserved.',
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AppFooter(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('VibeMyNight'), findsOneWidget);
      expect(find.text('Quick Links'), findsOneWidget);
      expect(find.text('Follow Us'), findsOneWidget);
    });
  });
}
