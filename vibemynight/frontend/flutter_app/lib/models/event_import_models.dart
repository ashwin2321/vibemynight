import 'package:equatable/equatable.dart';

class ValidationMessage extends Equatable {
  final String level; // "INFO", "WARNING", "ERROR"
  final String sheet;
  final int? row;
  final String? field;
  final String message;

  const ValidationMessage({
    required this.level,
    required this.sheet,
    this.row,
    this.field,
    required this.message,
  });

  bool get isError => level.toUpperCase() == 'ERROR';
  bool get isWarning => level.toUpperCase() == 'WARNING';
  bool get isInfo => level.toUpperCase() == 'INFO';

  factory ValidationMessage.fromJson(Map<String, dynamic> json) {
    return ValidationMessage(
      level: json['level'] as String? ?? 'INFO',
      sheet: json['sheet'] as String? ?? '',
      row: json['row'] as int?,
      field: json['field'] as String?,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'sheet': sheet,
        'row': row,
        'field': field,
        'message': message,
      };

  @override
  List<Object?> get props => [level, sheet, row, field, message];
}

class EventHeaderImport extends Equatable {
  final String name;
  final String? slug;
  final String? startDate;
  final String? endDate;
  final String? venue;
  final String? address;
  final String? city;
  final String? location;
  final String? googleMapsUrl;
  final String? organizer;
  final String? contactNumber;
  final String? email;
  final String? description;
  final bool featured;
  final String status;
  final String? mainImage;
  final String? banner;
  final String? thumbnail;

  const EventHeaderImport({
    required this.name,
    this.slug,
    this.startDate,
    this.endDate,
    this.venue,
    this.address,
    this.city,
    this.location,
    this.googleMapsUrl,
    this.organizer,
    this.contactNumber,
    this.email,
    this.description,
    this.featured = false,
    this.status = 'DRAFT',
    this.mainImage,
    this.banner,
    this.thumbnail,
  });

  factory EventHeaderImport.fromJson(Map<String, dynamic> json) {
    return EventHeaderImport(
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      venue: json['venue'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      location: json['location'] as String?,
      googleMapsUrl: json['googleMapsUrl'] as String?,
      organizer: json['organizer'] as String?,
      contactNumber: json['contactNumber'] as String?,
      email: json['email'] as String?,
      description: json['description'] as String?,
      featured: json['featured'] as bool? ?? false,
      status: json['status'] as String? ?? 'DRAFT',
      mainImage: json['mainImage'] as String?,
      banner: json['banner'] as String?,
      thumbnail: json['thumbnail'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'slug': slug,
        'startDate': startDate,
        'endDate': endDate,
        'venue': venue,
        'address': address,
        'city': city,
        'location': location,
        'googleMapsUrl': googleMapsUrl,
        'organizer': organizer,
        'contactNumber': contactNumber,
        'email': email,
        'description': description,
        'featured': featured,
        'status': status,
        'mainImage': mainImage,
        'banner': banner,
        'thumbnail': thumbnail,
      };

  @override
  List<Object?> get props => [name, slug, startDate, endDate, venue, city, status];
}

class PassImportItem extends Equatable {
  final String dayNumber;
  final String name;
  final String type;
  final double price;
  final int availableQuantity;
  final int maxPerCustomer;
  final String? description;
  final List<String> benefits;

  const PassImportItem({
    required this.dayNumber,
    required this.name,
    this.type = 'REGULAR',
    required this.price,
    required this.availableQuantity,
    this.maxPerCustomer = 10,
    this.description,
    this.benefits = const [],
  });

  factory PassImportItem.fromJson(Map<String, dynamic> json) {
    return PassImportItem(
      dayNumber: json['dayNumber']?.toString() ?? '1',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'REGULAR',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      availableQuantity: json['availableQuantity'] as int? ?? 100,
      maxPerCustomer: json['maxPerCustomer'] as int? ?? 10,
      description: json['description'] as String?,
      benefits: (json['benefits'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        'name': name,
        'type': type,
        'price': price,
        'availableQuantity': availableQuantity,
        'maxPerCustomer': maxPerCustomer,
        'description': description,
        'benefits': benefits,
      };

  @override
  List<Object?> get props => [dayNumber, name, type, price, availableQuantity];
}

class ArtistImportItem extends Equatable {
  final int dayNumber;
  final String artistName;
  final String artistType;
  final bool isPrimary;
  final int? performanceOrder;
  final String? performanceStartTime;
  final String? performanceEndTime;
  final String? photoUrl;
  final String? instagramUrl;
  final bool isExistingArtist;
  final int? matchedArtistId;

  const ArtistImportItem({
    required this.dayNumber,
    required this.artistName,
    this.artistType = 'SINGER',
    this.isPrimary = false,
    this.performanceOrder,
    this.performanceStartTime,
    this.performanceEndTime,
    this.photoUrl,
    this.instagramUrl,
    this.isExistingArtist = false,
    this.matchedArtistId,
  });

  factory ArtistImportItem.fromJson(Map<String, dynamic> json) {
    return ArtistImportItem(
      dayNumber: json['dayNumber'] as int? ?? 1,
      artistName: json['artistName'] as String? ?? '',
      artistType: json['artistType'] as String? ?? 'SINGER',
      isPrimary: json['isPrimary'] as bool? ?? false,
      performanceOrder: json['performanceOrder'] as int?,
      performanceStartTime: json['performanceStartTime'] as String?,
      performanceEndTime: json['performanceEndTime'] as String?,
      photoUrl: json['photoUrl'] as String?,
      instagramUrl: json['instagramUrl'] as String?,
      isExistingArtist: json['isExistingArtist'] as bool? ?? false,
      matchedArtistId: json['matchedArtistId'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        'artistName': artistName,
        'artistType': artistType,
        'isPrimary': isPrimary,
        'performanceOrder': performanceOrder,
        'performanceStartTime': performanceStartTime,
        'performanceEndTime': performanceEndTime,
        'photoUrl': photoUrl,
        'instagramUrl': instagramUrl,
        'isExistingArtist': isExistingArtist,
        'matchedArtistId': matchedArtistId,
      };

  @override
  List<Object?> get props => [dayNumber, artistName, artistType, isPrimary];
}

class FacilityImportItem extends Equatable {
  final String name;
  final String scope;
  final String? icon;
  final String? description;
  final bool isExistingFacility;
  final int? matchedFacilityId;

  const FacilityImportItem({
    required this.name,
    this.scope = 'EVENT',
    this.icon,
    this.description,
    this.isExistingFacility = false,
    this.matchedFacilityId,
  });

  factory FacilityImportItem.fromJson(Map<String, dynamic> json) {
    return FacilityImportItem(
      name: json['name'] as String? ?? '',
      scope: json['scope'] as String? ?? 'EVENT',
      icon: json['icon'] as String?,
      description: json['description'] as String?,
      isExistingFacility: json['isExistingFacility'] as bool? ?? false,
      matchedFacilityId: json['matchedFacilityId'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'scope': scope,
        'icon': icon,
        'description': description,
        'isExistingFacility': isExistingFacility,
        'matchedFacilityId': matchedFacilityId,
      };

  @override
  List<Object?> get props => [name, scope, icon];
}

class EventDayImportItem extends Equatable {
  final int dayNumber;
  final String? date;
  final String? dayName;
  final String? programName;
  final String? startTime;
  final String? endTime;
  final String? venue;
  final String? description;
  final List<PassImportItem> passes;
  final List<ArtistImportItem> artists;
  final List<FacilityImportItem> facilities;

  const EventDayImportItem({
    required this.dayNumber,
    this.date,
    this.dayName,
    this.programName,
    this.startTime,
    this.endTime,
    this.venue,
    this.description,
    this.passes = const [],
    this.artists = const [],
    this.facilities = const [],
  });

  factory EventDayImportItem.fromJson(Map<String, dynamic> json) {
    return EventDayImportItem(
      dayNumber: json['dayNumber'] as int? ?? 1,
      date: json['date'] as String?,
      dayName: json['dayName'] as String?,
      programName: json['programName'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      venue: json['venue'] as String?,
      description: json['description'] as String?,
      passes: (json['passes'] as List<dynamic>?)?.map((p) => PassImportItem.fromJson(p as Map<String, dynamic>)).toList() ?? const [],
      artists: (json['artists'] as List<dynamic>?)?.map((a) => ArtistImportItem.fromJson(a as Map<String, dynamic>)).toList() ?? const [],
      facilities: (json['facilities'] as List<dynamic>?)?.map((f) => FacilityImportItem.fromJson(f as Map<String, dynamic>)).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        'date': date,
        'dayName': dayName,
        'programName': programName,
        'startTime': startTime,
        'endTime': endTime,
        'venue': venue,
        'description': description,
        'passes': passes.map((p) => p.toJson()).toList(),
        'artists': artists.map((a) => a.toJson()).toList(),
        'facilities': facilities.map((f) => f.toJson()).toList(),
      };

  @override
  List<Object?> get props => [dayNumber, date, programName, passes, artists];
}

class ScrapedImageCandidate extends Equatable {
  final String url;
  final String? localUrl;
  final String suggestedRole; // "POSTER_3_4", "BANNER_16_9", "THUMBNAIL_1_1", "GALLERY"
  final String? label;
  final String? source;

  const ScrapedImageCandidate({
    required this.url,
    this.localUrl,
    this.suggestedRole = 'GALLERY',
    this.label,
    this.source,
  });

  /// The effective URL to display (prefers verified local backend URL to prevent CORS/hotlink failure)
  String get effectiveUrl {
    if (localUrl != null && localUrl!.trim().isNotEmpty) {
      return localUrl!.trim();
    }
    if (url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('/'))) {
      return url.trim();
    }
    return '';
  }

  factory ScrapedImageCandidate.fromJson(Map<String, dynamic> json) {
    return ScrapedImageCandidate(
      url: json['url'] as String? ?? '',
      localUrl: json['localUrl'] as String?,
      suggestedRole: json['suggestedRole'] as String? ?? 'GALLERY',
      label: json['label'] as String?,
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'localUrl': localUrl,
        'suggestedRole': suggestedRole,
        'label': label,
        'source': source,
      };

  @override
  List<Object?> get props => [url, localUrl, suggestedRole, label, source];
}

class EventImportPreview extends Equatable {
  final EventHeaderImport? event;
  final List<EventDayImportItem> days;
  final List<FacilityImportItem> eventFacilities;
  final List<String> highlights;
  final List<String> rules;
  final List<String> galleryImageUrls;
  final List<ScrapedImageCandidate> artworkCandidates;
  final List<ValidationMessage> validationMessages;
  final bool hasBlockingErrors;
  final int totalDays;
  final int totalPasses;
  final int totalArtists;

  const EventImportPreview({
    this.event,
    this.days = const [],
    this.eventFacilities = const [],
    this.highlights = const [],
    this.rules = const [],
    this.galleryImageUrls = const [],
    this.artworkCandidates = const [],
    this.validationMessages = const [],
    this.hasBlockingErrors = false,
    this.totalDays = 0,
    this.totalPasses = 0,
    this.totalArtists = 0,
  });

  factory EventImportPreview.fromJson(Map<String, dynamic> json) {
    return EventImportPreview(
      event: json['event'] != null ? EventHeaderImport.fromJson(json['event'] as Map<String, dynamic>) : null,
      days: (json['days'] as List<dynamic>?)?.map((d) => EventDayImportItem.fromJson(d as Map<String, dynamic>)).toList() ?? const [],
      eventFacilities: (json['eventFacilities'] as List<dynamic>?)?.map((f) => FacilityImportItem.fromJson(f as Map<String, dynamic>)).toList() ?? const [],
      highlights: (json['highlights'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      rules: (json['rules'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      galleryImageUrls: (json['galleryImageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      artworkCandidates: (json['artworkCandidates'] as List<dynamic>?)?.map((a) => ScrapedImageCandidate.fromJson(a as Map<String, dynamic>)).toList() ?? const [],
      validationMessages: (json['validationMessages'] as List<dynamic>?)?.map((v) => ValidationMessage.fromJson(v as Map<String, dynamic>)).toList() ?? const [],
      hasBlockingErrors: json['hasBlockingErrors'] as bool? ?? false,
      totalDays: json['totalDays'] as int? ?? 0,
      totalPasses: json['totalPasses'] as int? ?? 0,
      totalArtists: json['totalArtists'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'event': event?.toJson(),
        'days': days.map((d) => d.toJson()).toList(),
        'eventFacilities': eventFacilities.map((f) => f.toJson()).toList(),
        'highlights': highlights,
        'rules': rules,
        'galleryImageUrls': galleryImageUrls,
        'artworkCandidates': artworkCandidates.map((a) => a.toJson()).toList(),
        'validationMessages': validationMessages.map((v) => v.toJson()).toList(),
        'hasBlockingErrors': hasBlockingErrors,
        'totalDays': totalDays,
        'totalPasses': totalPasses,
        'totalArtists': totalArtists,
      };

  @override
  List<Object?> get props => [event, days, artworkCandidates, validationMessages, hasBlockingErrors];
}

