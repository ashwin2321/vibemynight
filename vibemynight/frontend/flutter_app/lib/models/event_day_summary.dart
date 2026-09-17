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
        id: (json['id'] as num?)?.toInt() ?? 0,
        dayNumber: (json['dayNumber'] as num?)?.toInt() ?? 0,
        date: json['date']?.toString() ?? '',
        dayName: json['dayName']?.toString(),
        programName: json['programName']?.toString(),
        startTime: json['startTime']?.toString(),
        endTime: json['endTime']?.toString(),
        primaryArtistName: json['primaryArtistName']?.toString(),
        primaryArtistPhotoUrl: json['primaryArtistPhotoUrl']?.toString(),
        startingPrice: (json['startingPrice'] as num?)?.toDouble(),
      );
}
