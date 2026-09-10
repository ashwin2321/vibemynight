import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/about_screen.dart';
import '../../features/admin/artists/admin_artist_form_screen.dart';
import '../../features/admin/artists/admin_artists_screen.dart';
import '../../features/admin/auth/admin_login_screen.dart';
import '../../features/admin/billing/admin_billing_screen.dart';
import '../../features/admin/dashboard/admin_dashboard_screen.dart';
import '../../features/admin/events/admin_days_screen.dart';
import '../../features/admin/events/admin_event_form_screen.dart';
import '../../features/admin/events/admin_events_screen.dart';
import '../../features/admin/events/admin_passes_screen.dart';
import '../../features/admin/facilities/admin_facilities_screen.dart';
import '../../features/admin/inquiries/admin_inquiries_screen.dart';
import '../../features/admin/inquiries/admin_inquiry_details_screen.dart';
import '../../features/admin/passes/admin_pass_catalog_screen.dart';
import '../../features/admin/settings/admin_settings_screen.dart';
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

/// Every screen/route named in the spec is wired here now (Phase 7), even
/// though several bodies are still [PlaceholderScreen] pending Phase 8/9.
/// Admin routes redirect to /admin/login when there's no JWT in storage.
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

      // ---------- Admin ----------
      GoRoute(path: '/admin/login', builder: (context, state) => const AdminLoginScreen()),
      GoRoute(path: '/admin/dashboard', builder: (context, state) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/events', builder: (context, state) => const AdminEventsScreen()),
      GoRoute(path: '/admin/events/new', builder: (context, state) => const AdminCreateEventScreen()),
      GoRoute(
        path: '/admin/events/:id/edit',
        builder: (context, state) =>
            AdminEditEventScreen(eventId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/admin/events/:id/days',
        builder: (context, state) =>
            AdminManageDaysScreen(eventId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/admin/events/:id/days/new',
        builder: (context, state) =>
            AdminDayFormScreen(eventId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/admin/event-days/:dayId/edit',
        builder: (context, state) {
          final dayId = int.parse(state.pathParameters['dayId']!);
          final eventId = state.extra as int? ?? 0;
          return AdminDayFormScreen(eventId: eventId, dayId: dayId);
        },
      ),
      GoRoute(
        path: '/admin/event-days/:dayId/passes',
        builder: (context, state) =>
            AdminManagePassesScreen(eventDayId: int.parse(state.pathParameters['dayId']!)),
      ),
      GoRoute(
        path: '/admin/event-days/:dayId/passes/new',
        builder: (context, state) =>
            AdminCreatePassScreen(eventDayId: int.parse(state.pathParameters['dayId']!)),
      ),
      GoRoute(
        path: '/admin/event-days/:dayId/passes/:passId/edit',
        builder: (context, state) => AdminEditPassScreen(
          eventDayId: int.parse(state.pathParameters['dayId']!),
          passId: int.parse(state.pathParameters['passId']!),
        ),
      ),
      GoRoute(path: '/admin/artists', builder: (context, state) => const AdminArtistsScreen()),
      GoRoute(path: '/admin/artists/new', builder: (context, state) => const AdminCreateArtistScreen()),
      GoRoute(
        path: '/admin/artists/:id/edit',
        builder: (context, state) =>
            AdminEditArtistScreen(artistId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/admin/pass-templates', builder: (context, state) => const AdminPassCatalogScreen()),
      GoRoute(path: '/admin/facilities', builder: (context, state) => const AdminFacilitiesScreen()),
      GoRoute(path: '/admin/inquiries', builder: (context, state) => const AdminInquiriesScreen()),
      GoRoute(
        path: '/admin/inquiries/:id',
        builder: (context, state) =>
            AdminInquiryDetailsScreen(inquiryId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/admin/billing', builder: (context, state) => const AdminBillingScreen()),
      GoRoute(path: '/admin/settings', builder: (context, state) => const AdminSettingsScreen()),
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
