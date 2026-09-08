/// Event card shape for the events listing screen.
class EventSummary {
  final int id;
  final String name;
  final String slug;
  final String? mainImage;
  final String? thumbnail;
  final String? city;
  final String? location;
  final String startDate;
  final String endDate;
  final int dayCount;
  final double? startingPrice;
  final String? featuredArtistName;
  final bool featured;
  final String status;

  const EventSummary({
    required this.id,
    required this.name,
    required this.slug,
    this.mainImage,
    this.thumbnail,
    this.city,
    this.location,
    required this.startDate,
    required this.endDate,
    required this.dayCount,
    this.startingPrice,
    this.featuredArtistName,
    required this.featured,
    required this.status,
  });

  factory EventSummary.fromJson(Map<String, dynamic> json) => EventSummary(
        id: json['id'] as int,
        name: json['name'] as String,
        slug: json['slug'] as String,
        mainImage: json['mainImage'] as String?,
        thumbnail: json['thumbnail'] as String?,
        city: json['city'] as String?,
        location: json['location'] as String?,
        startDate: json['startDate'] as String,
        endDate: json['endDate'] as String,
        dayCount: json['dayCount'] as int? ?? 0,
        startingPrice: (json['startingPrice'] as num?)?.toDouble(),
        featuredArtistName: json['featuredArtistName'] as String?,
        featured: json['featured'] as bool? ?? false,
        status: json['status'] as String? ?? 'DRAFT',
      );
}
