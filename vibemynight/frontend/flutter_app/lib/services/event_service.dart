import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/event_day_detail.dart';
import '../models/event_day_summary.dart';
import '../models/event_detail.dart';
import '../models/event_summary.dart';
import '../models/ticket_category.dart';

/// Everything customer-facing that touches Events, EventDays and Passes.
/// Admin write operations live in [AdminEventService] to keep the public
/// read surface obviously side-effect-free.
class EventService {
  EventService(this._client);
  final ApiClient _client;

  Future<List<EventSummary>> getPublishedEvents() async {
    final data = await _client.get(ApiConstants.events) as List;
    return data.map((e) => EventSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EventDetail> getEventBySlug(String slug) async {
    final data = await _client.get(ApiConstants.eventBySlug(slug));
    return EventDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<List<EventDaySummary>> getDaysForEvent(int eventId) async {
    final data = await _client.get(ApiConstants.eventDays(eventId)) as List;
    return data.map((e) => EventDaySummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EventDayDetail> getDayDetail(int dayId) async {
    final data = await _client.get(ApiConstants.eventDayDetail(dayId));
    return EventDayDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<List<TicketCategory>> getPassesForDay(int dayId) async {
    final data = await _client.get(ApiConstants.eventDayPasses(dayId)) as List;
    return data.map((e) => TicketCategory.fromJson(e as Map<String, dynamic>)).toList();
  }
}
