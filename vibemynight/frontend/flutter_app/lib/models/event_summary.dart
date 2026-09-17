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
  final bool showInHero;
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
    this.showInHero = false,
    required this.status,
  });

  factory EventSummary.fromJson(Map<String, dynamic> json) => EventSummary(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        mainImage: json['mainImage']?.toString(),
        thumbnail: json['thumbnail']?.toString(),
        city: json['city']?.toString(),
        location: json['location']?.toString(),
        startDate: json['startDate']?.toString() ?? '',
        endDate: json['endDate']?.toString() ?? '',
        dayCount: (json['dayCount'] as num?)?.toInt() ?? 0,
        startingPrice: (json['startingPrice'] as num?)?.toDouble(),
        featuredArtistName: json['featuredArtistName']?.toString(),
        featured: json['featured'] == true,
        showInHero: json['showInHero'] == true,
        status: json['status']?.toString() ?? 'PUBLISHED',
      );
}
