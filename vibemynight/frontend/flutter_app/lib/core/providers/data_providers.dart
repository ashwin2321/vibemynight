import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/artist.dart';
import '../../models/event_day_detail.dart';
import '../../models/event_detail.dart';
import '../../models/event_summary.dart';
import '../../models/facility.dart';
import '../../models/settings.dart';
import 'service_providers.dart';

/// Read-only data providers used across the customer screens. Screen-local
/// state (selected day, quantity, form fields, admin table filters) belongs
/// in each feature's own providers, added in Phase 8/9 alongside the screens
/// that need them - these cover the shared, cacheable backend reads.

final publishedEventsProvider = FutureProvider<List<EventSummary>>((ref) async {
  try {
    return await ref.watch(eventServiceProvider).getPublishedEvents();
  } catch (_) {
    return <EventSummary>[];
  }
});

final eventDetailProvider =
    FutureProvider.family<EventDetail, String>((ref, slug) {
  ref.keepAlive();
  return ref.watch(eventServiceProvider).getEventBySlug(slug);
});

final eventDayDetailProvider =
    FutureProvider.family<EventDayDetail, int>((ref, dayId) {
  ref.keepAlive();
  return ref.watch(eventServiceProvider).getDayDetail(dayId);
});

final artistsProvider = FutureProvider<List<Artist>>((ref) async {
  try {
    return await ref.watch(artistServiceProvider).getArtists();
  } catch (_) {
    return <Artist>[];
  }
});

final artistByIdProvider = FutureProvider.family<Artist, int>((ref, id) {
  ref.keepAlive();
  return ref.watch(artistServiceProvider).getArtistById(id);
});

final facilitiesProvider = FutureProvider<List<Facility>>((ref) async {
  try {
    return await ref.watch(facilityServiceProvider).getFacilities();
  } catch (_) {
    return <Facility>[];
  }
});

/// WhatsApp number and other site settings - fetched once, never hardcoded.
final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  try {
    return await ref.watch(settingsServiceProvider).getPublicSettings();
  } catch (_) {
    return const AppSettings(
      websiteName: 'VibeMyNight',
      whatsappNumber: '917041615131',
      phone: '+91 7041615131',
      email: 'support@vibemynight.com',
      currency: 'INR',
    );
  }
});

