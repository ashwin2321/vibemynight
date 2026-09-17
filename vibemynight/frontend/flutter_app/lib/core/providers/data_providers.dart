import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/artist.dart';
import '../../models/event_day_detail.dart';
import '../../models/event_detail.dart';
import '../../models/event_summary.dart';
import '../../models/facility.dart';
import '../../models/settings.dart';
import 'service_providers.dart';

/// Extension to keep providers alive with a controlled TTL cache duration.
extension CacheForExtension on Ref {
  void cacheFor(Duration duration) {
    final link = keepAlive();
    final timer = Timer(duration, () => link.close());
    onDispose(() => timer.cancel());
  }
}

/// Read-only data providers used across the customer screens. Screen-local
/// state (selected day, quantity, form fields, admin table filters) belongs
/// in each feature's own providers, added in Phase 8/9 alongside the screens
/// that need them - these cover the shared, cacheable backend reads.

final publishedEventsProvider = FutureProvider<List<EventSummary>>((ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  return ref.watch(eventServiceProvider).getPublishedEvents();
});

final eventDetailProvider =
    FutureProvider.family<EventDetail, String>((ref, slug) {
  ref.cacheFor(const Duration(minutes: 10));
  return ref.watch(eventServiceProvider).getEventBySlug(slug);
});

final eventDayDetailProvider =
    FutureProvider.family<EventDayDetail, int>((ref, dayId) {
  ref.cacheFor(const Duration(minutes: 10));
  return ref.watch(eventServiceProvider).getDayDetail(dayId);
});

final artistsProvider = FutureProvider<List<Artist>>((ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  return ref.watch(artistServiceProvider).getArtists();
});

final artistByIdProvider = FutureProvider.family<Artist, int>((ref, id) {
  ref.cacheFor(const Duration(minutes: 10));
  return ref.watch(artistServiceProvider).getArtistById(id);
});

final facilitiesProvider = FutureProvider<List<Facility>>((ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  return ref.watch(facilityServiceProvider).getFacilities();
});

/// WhatsApp number and other site settings - fetched once, never hardcoded.
final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  ref.cacheFor(const Duration(minutes: 10));
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


