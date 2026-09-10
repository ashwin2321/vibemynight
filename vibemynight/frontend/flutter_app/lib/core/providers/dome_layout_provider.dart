import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/event_detail.dart';

const _kDomeLayoutEventsKey = 'vmn_dome_layout_events_v1';
const _storage = FlutterSecureStorage();

class DomeLayoutState {
  final Set<String> enabledSlugs;
  final Set<int> enabledIds;

  const DomeLayoutState({
    this.enabledSlugs = const {},
    this.enabledIds = const {},
  });

  bool isEnabledFor(EventDetail event) {
    // 1. Direct ID or slug match in admin toggle settings
    if (enabledIds.contains(event.id) || enabledSlugs.contains(event.slug)) {
      return true;
    }
    // 2. Rule or highlight tag
    if (event.rules.contains('FEATURE_DOME_LAYOUT') ||
        event.highlights.contains('FEATURE_DOME_LAYOUT') ||
        event.rules.any((r) => r.toUpperCase().contains('DOME LAYOUT'))) {
      return true;
    }
    // 3. Name or Venue contains 'AC Dome' or 'Dome Garba'
    final nameVenue = '${event.name} ${event.venue ?? ""} ${event.description ?? ""}'.toLowerCase();
    if (nameVenue.contains('ac dome') || nameVenue.contains('dome garba') || nameVenue.contains('dome arena')) {
      return true;
    }
    return false;
  }
}

class DomeLayoutNotifier extends StateNotifier<DomeLayoutState> {
  DomeLayoutNotifier() : super(const DomeLayoutState()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final raw = await _storage.read(key: _kDomeLayoutEventsKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final slugs = (data['slugs'] as List?)?.cast<String>().toSet() ?? {};
        final ids = (data['ids'] as List?)?.cast<int>().toSet() ?? {};
        state = DomeLayoutState(enabledSlugs: slugs, enabledIds: ids);
      }
    } catch (_) {}
  }

  Future<void> setEventDomeLayout({int? eventId, String? slug, required bool enabled}) async {
    final updatedSlugs = Set<String>.from(state.enabledSlugs);
    final updatedIds = Set<int>.from(state.enabledIds);

    if (enabled) {
      if (slug != null && slug.isNotEmpty) updatedSlugs.add(slug);
      if (eventId != null && eventId > 0) updatedIds.add(eventId);
    } else {
      if (slug != null && slug.isNotEmpty) updatedSlugs.remove(slug);
      if (eventId != null && eventId > 0) updatedIds.remove(eventId);
    }

    state = DomeLayoutState(enabledSlugs: updatedSlugs, enabledIds: updatedIds);
    try {
      await _storage.write(
        key: _kDomeLayoutEventsKey,
        value: jsonEncode({
          'slugs': updatedSlugs.toList(),
          'ids': updatedIds.toList(),
        }),
      );
    } catch (_) {}
  }
}

final domeLayoutProvider = StateNotifierProvider<DomeLayoutNotifier, DomeLayoutState>((ref) {
  return DomeLayoutNotifier();
});
