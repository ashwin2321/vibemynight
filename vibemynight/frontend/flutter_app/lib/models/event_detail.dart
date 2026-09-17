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
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        mainImage: json['mainImage']?.toString(),
        banner: json['banner']?.toString(),
        thumbnail: json['thumbnail']?.toString(),
        description: json['description']?.toString(),
        startDate: json['startDate']?.toString() ?? '',
        endDate: json['endDate']?.toString() ?? '',
        venue: json['venue']?.toString(),
        address: json['address']?.toString(),
        city: json['city']?.toString(),
        location: json['location']?.toString(),
        googleMapsUrl: json['googleMapsUrl']?.toString(),
        organizer: json['organizer']?.toString(),
        contactNumber: json['contactNumber']?.toString(),
        email: json['email']?.toString(),
        featured: json['featured'] == true,
        status: json['status']?.toString() ?? 'PUBLISHED',
        galleryImageUrls: (json['galleryImageUrls'] as List?)
                ?.map((e) => e.toString())
                .where((s) => s.isNotEmpty)
                .toList() ??
            const [],
        highlights: (json['highlights'] as List?)
                ?.map((e) => e.toString())
                .where((s) => s.isNotEmpty)
                .toList() ??
            const [],
        rules: (json['rules'] as List?)
                ?.map((e) => e.toString())
                .where((s) => s.isNotEmpty)
                .toList() ??
            const [],
        facilities: (json['facilities'] as List? ?? [])
            .map((e) => Facility.fromJson(e as Map<String, dynamic>))
            .toList(),
        days: (json['days'] as List? ?? [])
            .map((e) => EventDaySummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
