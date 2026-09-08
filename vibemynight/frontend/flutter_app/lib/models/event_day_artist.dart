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
        artistId: json['artistId'] as int,
        name: json['name'] as String,
        photoUrl: json['photoUrl'] as String?,
        type: json['type'] as String,
        isPrimary: json['isPrimary'] as bool? ?? false,
        performanceOrder: json['performanceOrder'] as int?,
        performanceStartTime: json['performanceStartTime'] as String?,
        performanceEndTime: json['performanceEndTime'] as String?,
      );
}
