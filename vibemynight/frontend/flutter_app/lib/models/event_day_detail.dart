import 'event_day_artist.dart';
import 'facility.dart';
import 'ticket_category.dart';

/// Full detail for a single selected day - the "SELECTED DAY UI" screen shape.
class EventDayDetail {
  final int id;
  final int eventId;
  final int dayNumber;
  final String date;
  final String? dayName;
  final String? programName;
  final String? startTime;
  final String? endTime;
  final String? venue;
  final String? address;
  final String? location;
  final String? googleMapsUrl;
  final String? description;
  final String status;
  final List<EventDayArtist> artists;
  final List<Facility> facilities;
  final List<TicketCategory> passes;

  const EventDayDetail({
    required this.id,
    required this.eventId,
    required this.dayNumber,
    required this.date,
    this.dayName,
    this.programName,
    this.startTime,
    this.endTime,
    this.venue,
    this.address,
    this.location,
    this.googleMapsUrl,
    this.description,
    required this.status,
    required this.artists,
    required this.facilities,
    required this.passes,
  });

  EventDayArtist? get primaryArtist {
    for (final a in artists) {
      if (a.isPrimary) return a;
    }
    return artists.isNotEmpty ? artists.first : null;
  }

  factory EventDayDetail.fromJson(Map<String, dynamic> json) => EventDayDetail(
        id: (json['id'] as num?)?.toInt() ?? 0,
        eventId: (json['eventId'] as num?)?.toInt() ?? 0,
        dayNumber: (json['dayNumber'] as num?)?.toInt() ?? 0,
        date: json['date']?.toString() ?? '',
        dayName: json['dayName']?.toString(),
        programName: json['programName']?.toString(),
        startTime: json['startTime']?.toString(),
        endTime: json['endTime']?.toString(),
        venue: json['venue']?.toString(),
        address: json['address']?.toString(),
        location: json['location']?.toString(),
        googleMapsUrl: json['googleMapsUrl']?.toString(),
        description: json['description']?.toString(),
        status: json['status']?.toString() ?? 'ACTIVE',
        artists: (json['artists'] as List? ?? [])
            .map((e) => EventDayArtist.fromJson(e as Map<String, dynamic>))
            .toList(),
        facilities: (json['facilities'] as List? ?? [])
            .map((e) => Facility.fromJson(e as Map<String, dynamic>))
            .toList(),
        passes: (json['passes'] as List? ?? [])
            .map((e) => TicketCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
