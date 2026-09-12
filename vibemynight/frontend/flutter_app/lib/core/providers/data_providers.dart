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

final publishedEventsProvider = FutureProvider<List<EventSummary>>((ref) {
  return ref.watch(eventServiceProvider).getPublishedEvents();
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

final artistsProvider = FutureProvider<List<Artist>>((ref) {
  return ref.watch(artistServiceProvider).getArtists();
});

final artistByIdProvider = FutureProvider.family<Artist, int>((ref, id) {
  ref.keepAlive();
  return ref.watch(artistServiceProvider).getArtistById(id);
});

final facilitiesProvider = FutureProvider<List<Facility>>((ref) {
  return ref.watch(facilityServiceProvider).getFacilities();
});

/// WhatsApp number and other site settings - fetched once, never hardcoded.
final appSettingsProvider = FutureProvider<AppSettings>((ref) {
  return ref.watch(settingsServiceProvider).getPublicSettings();
});

