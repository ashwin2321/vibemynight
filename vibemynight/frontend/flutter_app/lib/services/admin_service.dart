import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/artist.dart';
import '../models/event_day_detail.dart';
import '../models/event_detail.dart';
import '../models/event_summary.dart';
import '../models/facility.dart';
import '../models/inquiry.dart';
import '../models/inquiry_admin_summary.dart';
import '../models/settings.dart';

/// All admin write/read operations in one place, mirroring the
/// `/api/v1/admin/**` routes from Phase 5-6. Kept as a single service
/// (rather than one class per resource) since every method here is a thin,
/// uniform pass-through to ApiClient - splitting it up would just add file
/// count without adding clarity.
class AdminService {
  AdminService(this._client);
  final ApiClient _client;

  // ---------- Events ----------

  Future<List<EventSummary>> getAllEvents() async {
    final data = await _client.get(ApiConstants.adminEvents) as List;
    return data.map((e) => EventSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EventDetail> getEventDetail(int id) async {
    final data = await _client.get(ApiConstants.adminEventById(id));
    return EventDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<void> createEvent(Map<String, dynamic> body) =>
      _client.post(ApiConstants.adminEvents, body: body);

  Future<void> updateEvent(int id, Map<String, dynamic> body) =>
      _client.put(ApiConstants.adminEventById(id), body: body);

  Future<void> deleteEvent(int id) => _client.delete(ApiConstants.adminEventById(id));

  Future<void> changeEventStatus(int id, String status) =>
      _client.patch(ApiConstants.adminEventStatus(id), body: {'status': status});

  // ---------- Event days ----------

  Future<void> createEventDay(int eventId, Map<String, dynamic> body) =>
      _client.post(ApiConstants.adminEventDays(eventId), body: body);

  Future<void> updateEventDay(int dayId, Map<String, dynamic> body) =>
      _client.put(ApiConstants.adminEventDayById(dayId), body: body);

  Future<void> deleteEventDay(int dayId) => _client.delete(ApiConstants.adminEventDayById(dayId));

  Future<EventDayDetail> getDayDetail(int dayId) async {
    final data = await _client.get(ApiConstants.eventDayDetail(dayId));
    return EventDayDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<void> assignArtistToDay(int dayId, Map<String, dynamic> body) =>
      _client.post(ApiConstants.adminEventDayArtists(dayId), body: body);

  Future<void> removeArtistFromDay(int dayId, int artistId) =>
      _client.delete(ApiConstants.adminEventDayArtistById(dayId, artistId));

  // ---------- Artists ----------

  Future<List<Artist>> getAllArtists() async {
    final data = await _client.get(ApiConstants.adminArtists) as List;
    return data.map((e) => Artist.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createArtist(Map<String, dynamic> body) =>
      _client.post(ApiConstants.adminArtists, body: body);

  Future<void> updateArtist(int id, Map<String, dynamic> body) =>
      _client.put(ApiConstants.adminArtistById(id), body: body);

  Future<void> deleteArtist(int id) => _client.delete(ApiConstants.adminArtistById(id));

  Future<void> changeArtistStatus(int id, String status) =>
      _client.patch(ApiConstants.adminArtistStatus(id), body: {'status': status});

  // ---------- Facilities ----------

  Future<List<Facility>> getAllFacilities() async {
    final data = await _client.get(ApiConstants.adminFacilities) as List;
    return data.map((e) => Facility.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createFacility(Map<String, dynamic> body) =>
      _client.post(ApiConstants.adminFacilities, body: body);

  Future<void> updateFacility(int id, Map<String, dynamic> body) =>
      _client.put(ApiConstants.adminFacilityById(id), body: body);

  Future<void> deleteFacility(int id) => _client.delete(ApiConstants.adminFacilityById(id));

  Future<void> changeFacilityStatus(int id, String status) =>
      _client.patch(ApiConstants.adminFacilityStatus(id), body: {'status': status});

  Future<void> addFacilityToEvent(int eventId, int facilityId) =>
      _client.post('/admin/events/$eventId/facilities/$facilityId');

  Future<void> removeFacilityFromEvent(int eventId, int facilityId) =>
      _client.delete('/admin/events/$eventId/facilities/$facilityId');

  Future<void> addFacilityToDay(int dayId, int facilityId) =>
      _client.post('/admin/event-days/$dayId/facilities/$facilityId');

  Future<void> removeFacilityFromDay(int dayId, int facilityId) =>
      _client.delete('/admin/event-days/$dayId/facilities/$facilityId');

  // ---------- Passes ----------

  Future<void> createPass(int eventDayId, Map<String, dynamic> body) =>
      _client.post(ApiConstants.adminEventDayPasses(eventDayId), body: body);

  Future<void> updatePass(int id, Map<String, dynamic> body) =>
      _client.put(ApiConstants.adminPassById(id), body: body);

  Future<void> deletePass(int id) => _client.delete(ApiConstants.adminPassById(id));

  // ---------- Gallery / Highlights / Rules ----------

  Future<void> addGalleryImage(int eventId, Map<String, dynamic> body) =>
      _client.post(ApiConstants.adminEventGallery(eventId), body: body);

  Future<void> deleteGalleryImage(int id) => _client.delete(ApiConstants.adminGalleryById(id));

  Future<void> addHighlight(int eventId, Map<String, dynamic> body) =>
      _client.post(ApiConstants.adminEventHighlights(eventId), body: body);

  Future<void> deleteHighlight(int id) => _client.delete(ApiConstants.adminHighlightById(id));

  Future<void> addRule(int eventId, Map<String, dynamic> body) =>
      _client.post(ApiConstants.adminEventRules(eventId), body: body);

  Future<void> deleteRule(int id) => _client.delete(ApiConstants.adminRuleById(id));

  // ---------- Inquiries ----------

  Future<List<InquiryAdminSummary>> getInquiries({
    String? search,
    String? status,
    int? eventId,
    int? artistId,
    int? ticketCategoryId,
    String? date,
  }) async {
    final data = await _client.get(ApiConstants.adminInquiries, query: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null) 'status': status,
      if (eventId != null) 'eventId': eventId,
      if (artistId != null) 'artistId': artistId,
      if (ticketCategoryId != null) 'ticketCategoryId': ticketCategoryId,
      if (date != null) 'date': date,
    }) as List;
    return data.map((e) => InquiryAdminSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<InquiryResponse> getInquiryDetail(int id) async {
    final data = await _client.get(ApiConstants.adminInquiryById(id));
    return InquiryResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<void> updateInquiryStatus(int id, String status) =>
      _client.patch(ApiConstants.adminInquiryStatus(id), body: {'status': status});

  Future<void> deleteInquiry(int id) => _client.delete(ApiConstants.adminInquiryById(id));

  // ---------- Settings ----------

  Future<AppSettings> getAdminSettings() async {
    final data = await _client.get(ApiConstants.adminSettings);
    return AppSettings.fromJson(data as Map<String, dynamic>);
  }

  Future<void> updateSettings(Map<String, dynamic> body) =>
      _client.put(ApiConstants.adminSettings, body: body);

  // ---------- Uploads ----------

  /// Uploads image bytes and returns the public URL to put into a
  /// photoUrl/mainImage/imageUrl field. [folder] is a purely organizational
  /// hint (e.g. "artists", "events", "gallery").
  Future<String> uploadImage(List<int> fileBytes, String filename, {String folder = 'misc'}) async {
    final data = await _client.uploadFile(
      ApiConstants.adminUploads,
      fileBytes: fileBytes,
      filename: filename,
      folderValue: folder,
    );
    return (data as Map<String, dynamic>)['url'] as String;
  }
}
