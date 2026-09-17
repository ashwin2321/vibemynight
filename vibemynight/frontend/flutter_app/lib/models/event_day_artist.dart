class EventDayArtist {
  final int artistId;
  final String name;
  final String? photoUrl;
  final String type;
  final bool isPrimary;
  final int? performanceOrder;
  final String? performanceStartTime;
  final String? performanceEndTime;

  const EventDayArtist({
    required this.artistId,
    required this.name,
    this.photoUrl,
    required this.type,
    required this.isPrimary,
    this.performanceOrder,
    this.performanceStartTime,
    this.performanceEndTime,
  });

  factory EventDayArtist.fromJson(Map<String, dynamic> json) => EventDayArtist(
        artistId: (json['artistId'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        photoUrl: json['photoUrl']?.toString(),
        type: json['type']?.toString() ?? 'ARTIST',
        isPrimary: json['isPrimary'] == true,
        performanceOrder: (json['performanceOrder'] as num?)?.toInt(),
        performanceStartTime: json['performanceStartTime']?.toString(),
        performanceEndTime: json['performanceEndTime']?.toString(),
      );
}
