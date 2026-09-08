import 'event_day_summary.dart';
import 'facility.dart';

class EventDetail {
  final int id;
  final String name;
  final String slug;
  final String? mainImage;
  final String? banner;
  final String? thumbnail;
  final String? description;
  final String startDate;
  final String endDate;
  final String? venue;
  final String? address;
  final String? city;
  final String? location;
  final String? googleMapsUrl;
  final String? organizer;
  final String? contactNumber;
  final String? email;
  final bool featured;
  final String status;
  final List<String> galleryImageUrls;
  final List<String> highlights;
  final List<String> rules;
  final List<Facility> facilities;
  final List<EventDaySummary> days;

  const EventDetail({
    required this.id,
    required this.name,
    required this.slug,
    this.mainImage,
    this.banner,
    this.thumbnail,
    this.description,
    required this.startDate,
    required this.endDate,
    this.venue,
    this.address,
    this.city,
    this.location,
    this.googleMapsUrl,
    this.organizer,
    this.contactNumber,
    this.email,
    required this.featured,
    required this.status,
    required this.galleryImageUrls,
    required this.highlights,
    required this.rules,
    required this.facilities,
    required this.days,
  });

  factory EventDetail.fromJson(Map<String, dynamic> json) => EventDetail(
        id: json['id'] as int,
        name: json['name'] as String,
        slug: json['slug'] as String,
        mainImage: json['mainImage'] as String?,
        banner: json['banner'] as String?,
        thumbnail: json['thumbnail'] as String?,
        description: json['description'] as String?,
        startDate: json['startDate'] as String,
        endDate: json['endDate'] as String,
        venue: json['venue'] as String?,
        address: json['address'] as String?,
        city: json['city'] as String?,
        location: json['location'] as String?,
        googleMapsUrl: json['googleMapsUrl'] as String?,
        organizer: json['organizer'] as String?,
        contactNumber: json['contactNumber'] as String?,
        email: json['email'] as String?,
        featured: json['featured'] as bool? ?? false,
        status: json['status'] as String,
        galleryImageUrls: (json['galleryImageUrls'] as List?)?.cast<String>() ?? const [],
        highlights: (json['highlights'] as List?)?.cast<String>() ?? const [],
        rules: (json['rules'] as List?)?.cast<String>() ?? const [],
        facilities: (json['facilities'] as List? ?? [])
            .map((e) => Facility.fromJson(e as Map<String, dynamic>))
            .toList(),
        days: (json['days'] as List? ?? [])
            .map((e) => EventDaySummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
