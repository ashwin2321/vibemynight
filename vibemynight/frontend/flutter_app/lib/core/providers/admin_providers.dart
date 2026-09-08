import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/artist.dart';
import '../../models/event_detail.dart';
import '../../models/event_summary.dart';
import '../../models/facility.dart';
import '../../models/inquiry_admin_summary.dart';
import 'service_providers.dart';

export 'service_providers.dart';

/// Admin-side read providers. Screen-local state (form fields, table filter
/// selections) lives in each screen's own StatefulWidget/controller - these
/// are the shared, invalidate-and-refetch backed lists and details.

final adminEventsProvider = FutureProvider.autoDispose<List<EventSummary>>((ref) {
  return ref.watch(adminServiceProvider).getAllEvents();
});

final adminEventDetailProvider = FutureProvider.autoDispose.family<EventDetail, int>((ref, id) {
  return ref.watch(adminServiceProvider).getEventDetail(id);
});

final adminArtistsProvider = FutureProvider.autoDispose<List<Artist>>((ref) {
  return ref.watch(adminServiceProvider).getAllArtists();
});

final adminFacilitiesProvider = FutureProvider.autoDispose<List<Facility>>((ref) {
  return ref.watch(adminServiceProvider).getAllFacilities();
});

/// Params for the admin inquiries table's search/filter bar.
class InquiryFilterParams {
  final String? search;
  final String? status;

  const InquiryFilterParams({this.search, this.status});

  @override
  bool operator ==(Object other) =>
      other is InquiryFilterParams && other.search == search && other.status == status;

  @override
  int get hashCode => Object.hash(search, status);
}

final adminInquiriesProvider =
    FutureProvider.autoDispose.family<List<InquiryAdminSummary>, InquiryFilterParams>((ref, params) {
  return ref.watch(adminServiceProvider).getInquiries(search: params.search, status: params.status);
});
