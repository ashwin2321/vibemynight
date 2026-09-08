/// Lightweight shape for the "CHOOSE YOUR NIGHT" day-selector strip -
/// one per day, however many days the event has (never assume a fixed count).
class EventDaySummary {
  final int id;
  final int dayNumber;
  final String date;
  final String? dayName;
  final String? programName;
  final String? startTime;
  final String? endTime;
  final String? primaryArtistName;
  final String? primaryArtistPhotoUrl;
  final double? startingPrice;

  const EventDaySummary({
    required this.id,
    required this.dayNumber,
    required this.date,
    this.dayName,
    this.programName,
    this.startTime,
    this.endTime,
    this.primaryArtistName,
    this.primaryArtistPhotoUrl,
    this.startingPrice,
  });

  factory EventDaySummary.fromJson(Map<String, dynamic> json) => EventDaySummary(
        id: json['id'] as int,
        dayNumber: json['dayNumber'] as int,
        date: json['date'] as String,
        dayName: json['dayName'] as String?,
        programName: json['programName'] as String?,
        startTime: json['startTime'] as String?,
        endTime: json['endTime'] as String?,
        primaryArtistName: json['primaryArtistName'] as String?,
        primaryArtistPhotoUrl: json['primaryArtistPhotoUrl'] as String?,
        startingPrice: (json['startingPrice'] as num?)?.toDouble(),
      );
}
