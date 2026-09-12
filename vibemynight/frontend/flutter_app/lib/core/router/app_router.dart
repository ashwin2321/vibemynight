import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/about_screen.dart';
import '../../features/admin/artists/admin_artist_form_screen.dart' deferred as admin_artist_form;
import '../../features/admin/artists/admin_artists_screen.dart' deferred as admin_artists;
import '../../features/admin/auth/admin_login_screen.dart' deferred as admin_login;
import '../../features/admin/billing/admin_billing_screen.dart' deferred as admin_billing;
import '../../features/admin/dashboard/admin_dashboard_screen.dart' deferred as admin_dashboard;
import '../../features/admin/events/admin_days_screen.dart' deferred as admin_days;
import '../../features/admin/events/admin_event_form_screen.dart' deferred as admin_event_form;
import '../../features/admin/events/admin_events_screen.dart' deferred as admin_events;
import '../../features/admin/events/admin_passes_screen.dart' deferred as admin_passes;
import '../../features/admin/facilities/admin_facilities_screen.dart' deferred as admin_facilities;
import '../../features/admin/inquiries/admin_inquiries_screen.dart' deferred as admin_inquiries;
import '../../features/admin/inquiries/admin_inquiry_details_screen.dart' deferred as admin_inquiry_details;
import '../../features/admin/passes/admin_pass_catalog_screen.dart' deferred as admin_pass_catalog;
import '../../features/admin/settings/admin_settings_screen.dart' deferred as admin_settings;
import '../../features/artists/artists_screen.dart';
import '../../features/contact/contact_screen.dart';
import '../../features/event_details/event_day_screen.dart';
import '../../features/event_details/event_details_screen.dart';
import '../../features/events/events_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/inquiry/inquiry_screen.dart';
import '../../features/inquiry/inquiry_success_screen.dart';
import '../../models/inquiry.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_view.dart';

/// Deferred loader helper for code splitting in Flutter Web
class DeferredWidget extends StatelessWidget {
  final Future<void> Function() loadLibrary;
  final Widget Function() builder;

  const DeferredWidget({
    super.key,
    required this.loadLibrary,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: loadLibrary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: const Color(0xFF07070E),
              body: Center(
                child: Text('Error loading module: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70)),
              ),
            );
          }
          return builder();
        }
        return const Scaffold(
          backgroundColor: Color(0xFF07070E),
          body: LoadingView(message: 'Loading admin panel...'),
        );
      },
    );
  }
}

/// Every screen/route named in the spec is wired here now (Phase 7).
/// Admin routes redirect to /admin/login when there's no JWT in storage.
/// Admin modules are loaded asynchronously on-demand for super fast customer load times.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthRefreshNotifier(ref),
    redirect: (context, state) {
      final loggedIn = authState.isLoggedIn;
      final goingToAdmin = state.matchedLocation.startsWith('/admin');
      final goingToLogin = state.matchedLocation == '/admin/login';

      if (goingToAdmin && !goingToLogin && !loggedIn) return '/admin/login';
      if (goingToLogin && loggedIn) return '/admin/dashboard';
      return null;
    },
    routes: [
      // ---------- Customer ----------
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
      GoRoute(path: '/contact', builder: (context, state) => const ContactScreen()),
      GoRoute(path: '/events', builder: (context, state) => const EventsScreen()),
      GoRoute(
        path: '/events/:slug',
        builder: (context, state) => EventDetailsScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/event-days/:dayId',
        builder: (context, state) =>
            EventDayScreen(dayId: int.parse(state.pathParameters['dayId']!)),
      ),
      GoRoute(path: '/artists', builder: (context, state) => const ArtistsScreen()),
      GoRoute(
        path: '/artists/:artistId',
        builder: (context, state) =>
            ArtistDetailsScreen(artistId: int.parse(state.pathParameters['artistId']!)),
      ),
      GoRoute(
        path: '/inquiry',
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic> ? state.extra as Map<String, dynamic> : null;
          final qParams = state.uri.queryParameters;

          final eventDayId = extra?['dayId'] as int? ??
              extra?['eventDayId'] as int? ??
              int.tryParse(qParams['eventDayId'] ?? qParams['dayId'] ?? '1') ??
              1;

          final ticketCategoryId = extra?['ticketCategoryId'] as int? ??
              int.tryParse(qParams['ticketCategoryId'] ?? '1') ??
              1;

          final initialQuantity = extra?['quantity'] as int? ??
              int.tryParse(qParams['quantity'] ?? '1') ??
              1;

          return InquiryScreen(
            eventDayId: eventDayId,
            ticketCategoryId: ticketCategoryId,
            initialQuantity: initialQuantity,
          );
        },
      ),
      GoRoute(
        path: '/inquiry/success',
        builder: (context, state) {
          final inq = state.extra is InquiryResponse ? state.extra as InquiryResponse : null;
          if (inq != null) {
            return InquirySuccessScreen(inquiry: inq);
          }
          return const InquirySuccessScreen(
            inquiry: InquiryResponse(
              id: 0,
              inquiryNumber: 'VMN-SUCCESS',
              status: 'NEW',
              customerName: 'Valued Guest',
              customerMobile: '917041615131',
              eventId: 1,
              eventName: 'VibeMyNight Event',
              eventDayId: 1,
              ticketCategoryId: 1,
              ticketCategoryName: 'Standard Pass',
              price: 499.0,
              quantity: 1,
              estimatedTotal: 499.0,
              whatsappUrl: 'https://wa.me/917041615131',
            ),
          );
        },
      ),

      // ---------- Admin (Deferred / Code-Split) ----------
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => DeferredWidget(
          loadLibrary: admin_login.loadLibrary,
          builder: () => admin_login.AdminLoginScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => DeferredWidget(
          loadLibrary: admin_dashboard.loadLibrary,
          builder: () => admin_dashboard.AdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/events',
        builder: (context, state) => DeferredWidget(
          loadLibrary: admin_events.loadLibrary,
          builder: () => admin_events.AdminEventsScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/events/new',
        builder: (context, state) => DeferredWidget(
          loadLibrary: admin_event_form.loadLibrary,
          builder: () => admin_event_form.AdminCreateEventScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/events/:id/edit',
        builder: (context, state) => DeferredWidget(
          loadLibrary: admin_event_form.loadLibrary,
          builder: () => admin_event_form.AdminEditEventScreen(
            eventId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/events/:id/days',
        builder: (context, state) => DeferredWidget(
          loadLibrary: admin_days.loadLibrary,
          builder: () => admin_days.AdminManageDaysScreen(
            eventId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/events/:id/days/new',
        builder: (context, state) => DeferredWidget(
          loadLibrary: admin_days.loadLibrary,
          builder: () => admin_days.AdminDayFormScreen(
            eventId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/event-days/:dayId/edit',
        builder: (context, state) {
          final dayId = int.parse(state.pathParameters['dayId']!);
          final eventId = state.extra as int? ?? 0;
          return DeferredWidget(
            loadLibrary: admin_days.loadLibrary,
            builder: () => admin_days.AdminDayFormScreen(
              eventId: eventId,
              dayId: dayId,
            ),
          );
        },
      ),
      GoRoute(
        path: '/admin/event-days/:dayId/passes',
        builder: (context, state) => DeferredWidget(
          loadLibrary: admin_passes.loadLibrary,
          builder: () => admin_passes.AdminManagePassesScreen(
            eventDayId: int.parse(state.pathParameters['dayId']!),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/event-days/:dayId/passes/new',
        builder: (context, state) => DeferredWidget(
          loadLibrary: admin_passes.loadLibrary,
          builder: () => admin_passes.AdminCreatePassScreen(
            eventDayId: int.parse(state.pathParameters['dayId']!),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/event-days/:dayId/passes/:passId/edit',
        builder: (context, state) => DeferredWidget(
          loadLibrary: admin_passes.loadLibrary,
          builder: () => admin_passes.AdminEditPassScreen(
            eventDayId: int.parse(state.pathParameters['dayId']!),
            passId: int.parse(state.pathParameters['passId']!),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/artists',
        builder: (context, state) => DeferredWidget(
          loadLibrary: admin_artists.loadLibrary,
          builder: () => admin_artists.AdminArtistsScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/artists/new',
        builder: (context, state) => DeferredWidget(
          loadLibrary: admin_artist_form.loadLibrary,
          builder: () => admin_artist_form.AdminCreateArtistScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/artists/:id/edit',
        builder: (context, state) => DeferredWidget(
          loadLibrary: admin_artist_form.loadLibrary,
          builder: () => admin_artist_form.AdminEditArtistScreen(
            artistId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/pass-templates',
        builder: (context, state) => DeferredWidget(
          loadLibrary: admin_pass_catalog.loadLibrary,
          builder: () => admin_pass_catalog.AdminPassCatalogScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/facilities',
        builder: (context, state) => DeferredWidget(
          loadLibrary: admin_facilities.loadLibrary,
          builder: () => admin_facilities.AdminFacilitiesScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/inquiries',
        builder: (context, state) => DeferredWidget(
          loadLibrary: admin_inquiries.loadLibrary,
          builder: () => admin_inquiries.AdminInquiriesScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/inquiries/:id',
        builder: (context, state) => DeferredWidget(
          loadLibrary: admin_inquiry_details.loadLibrary,
          builder: () => admin_inquiry_details.AdminInquiryDetailsScreen(
            inquiryId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/billing',
        builder: (context, state) => DeferredWidget(
          loadLibrary: admin_billing.loadLibrary,
          builder: () => admin_billing.AdminBillingScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/settings',
        builder: (context, state) => DeferredWidget(
          loadLibrary: admin_settings.loadLibrary,
          builder: () => admin_settings.AdminSettingsScreen(),
        ),
      ),
    ],
  );
});

/// Bridges Riverpod's AuthState changes into something GoRouter's
/// `refreshListenable` (a plain Listenable) can react to, so login/logout
/// immediately re-runs the redirect logic above.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}

