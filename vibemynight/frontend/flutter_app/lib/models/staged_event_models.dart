import 'package:equatable/equatable.dart';

/// Represents the status of a staged event in the Staging Sync system.
enum StagedStatus {
  pendingReview,
  approved,
  imported,
  rejected,
  conflict;

  static StagedStatus fromString(String? val) {
    if (val == null) return StagedStatus.pendingReview;
    switch (val.toUpperCase()) {
      case 'APPROVED':
        return StagedStatus.approved;
      case 'IMPORTED':
        return StagedStatus.imported;
      case 'REJECTED':
        return StagedStatus.rejected;
      case 'CONFLICT':
      case 'DUPLICATE':
      case 'AI_PROCESSING_FAILED':
      case 'SYNC_FAILED':
        return StagedStatus.conflict;
      case 'PENDING_REVIEW':
      case 'READY_TO_IMPORT':
      default:
        return StagedStatus.pendingReview;
    }
  }

  String toApiString() {
    switch (this) {
      case StagedStatus.approved:
        return 'APPROVED';
      case StagedStatus.imported:
        return 'IMPORTED';
      case StagedStatus.rejected:
        return 'REJECTED';
      case StagedStatus.conflict:
        return 'CONFLICT';
      case StagedStatus.pendingReview:
        return 'PENDING_REVIEW';
    }
  }

  String get displayName {
    switch (this) {
      case StagedStatus.approved:
        return 'Approved';
      case StagedStatus.imported:
        return 'Imported';
      case StagedStatus.rejected:
        return 'Rejected';
      case StagedStatus.conflict:
        return 'Conflict / Dup';
      case StagedStatus.pendingReview:
        return 'Pending Review';
    }
  }
}

/// Represents an artist scraped from source data.
class ScrapedArtistItem extends Equatable {
  final String name;
  final String? role;
  final String? imageUrl;
  final String? bio;

  const ScrapedArtistItem({
    required this.name,
    this.role,
    this.imageUrl,
    this.bio,
  });

  factory ScrapedArtistItem.fromJson(Map<String, dynamic> json) {
    return ScrapedArtistItem(
      name: json['name'] as String? ?? 'Artist',
      role: json['role'] as String?,
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role,
        'imageUrl': imageUrl,
        'bio': bio,
      };

  @override
  List<Object?> get props => [name, role, imageUrl, bio];
}

/// Represents a ticket pass scraped from source data without fabricated defaults.
class ScrapedPassItem extends Equatable {
  final String name;
  final String type;
  final double? price;
  final int? availableQuantity;
  final int? maxPerCustomer;
  final List<String> benefits;
  final String? description;

  const ScrapedPassItem({
    required this.name,
    this.type = 'REGULAR',
    this.price,
    this.availableQuantity,
    this.maxPerCustomer,
    this.benefits = const [],
    this.description,
  });

  factory ScrapedPassItem.fromJson(Map<String, dynamic> json) {
    double? parsePrice(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      return int.tryParse(val.toString());
    }

    List<String> parseBenefits(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return const [];
    }

    return ScrapedPassItem(
      name: json['name'] as String? ?? 'Pass',
      type: json['type'] as String? ?? 'REGULAR',
      price: parsePrice(json['price']),
      availableQuantity: parseInt(json['available_quantity'] ?? json['totalQuantity']),
      maxPerCustomer: parseInt(json['max_per_customer'] ?? json['maxPerCustomer']),
      benefits: parseBenefits(json['benefits']),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'price': price,
        'available_quantity': availableQuantity,
        'max_per_customer': maxPerCustomer,
        'benefits': benefits,
        'description': description,
      };

  @override
  List<Object?> get props => [
        name,
        type,
        price,
        availableQuantity,
        maxPerCustomer,
        benefits,
        description,
      ];
}

/// Represents an event day scraped from source data.
class ScrapedDayItem extends Equatable {
  final int dayNumber;
  final String? date;
  final String? dayName;
  final String? programName;
  final String? startTime;
  final String? endTime;
  final String? venue;
  final String? description;

  const ScrapedDayItem({
    required this.dayNumber,
    this.date,
    this.dayName,
    this.programName,
    this.startTime,
    this.endTime,
    this.venue,
    this.description,
  });

  factory ScrapedDayItem.fromJson(Map<String, dynamic> json) {
    return ScrapedDayItem(
      dayNumber: json['day_number'] as int? ?? json['dayNumber'] as int? ?? 1,
      date: json['date'] as String?,
      dayName: json['day_name'] as String? ?? json['dayName'] as String?,
      programName: json['program_name'] as String? ?? json['programName'] as String?,
      startTime: json['start_time'] as String? ?? json['startTime'] as String?,
      endTime: json['end_time'] as String? ?? json['endTime'] as String?,
      venue: json['venue'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'day_number': dayNumber,
        'date': date,
        'day_name': dayName,
        'program_name': programName,
        'start_time': startTime,
        'end_time': endTime,
        'venue': venue,
        'description': description,
      };

  @override
  List<Object?> get props => [
        dayNumber,
        date,
        dayName,
        programName,
        startTime,
        endTime,
        venue,
        description,
      ];
}

/// Represents an image candidate scraped from source data.
class ScrapedArtworkCandidate extends Equatable {
  final String url;
  final String suggestedRole;
  final String? altText;

  const ScrapedArtworkCandidate({
    required this.url,
    this.suggestedRole = 'GALLERY',
    this.altText,
  });

  factory ScrapedArtworkCandidate.fromJson(Map<String, dynamic> json) {
    return ScrapedArtworkCandidate(
      url: json['url'] as String? ?? '',
      suggestedRole: json['suggested_role'] as String? ?? json['suggestedRole'] as String? ?? 'GALLERY',
      altText: json['alt_text'] as String? ?? json['altText'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'suggested_role': suggestedRole,
        'alt_text': altText,
      };

  @override
  List<Object?> get props => [url, suggestedRole, altText];
}

/// Represents an external event fetched and AI-enhanced in the staging database.
class StagedEvent extends Equatable {
  final int id;
  final String source;
  final String sourceEventId;
  final String? sourceUrl;
  final String title;
  final String? description;
  final String? enhancedTitle;
  final String? catchyDescription;
  final List<String> highlights;
  final List<String> genreTags;
  final List<String> seoKeywords;
  final String? whatsAppTeaser;
  final String? posterUrl;
  final String? bannerUrl;
  final String? eventStartDate;
  final String? eventEndDate;
  final String? startTime;
  final String? endTime;
  final String? venueName;
  final String? venueAddress;
  final String? city;
  final String? state;
  final double? minTicketPrice;
  final double? maxTicketPrice;
  final String currency;
  final StagedStatus status;
  final int? duplicateOf;
  final bool aiProcessed;
  final String? aiProvider;
  final String? aiModel;
  final String? aiError;
  final Map<String, dynamic>? rawPayload;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StagedEvent({
    required this.id,
    required this.source,
    required this.sourceEventId,
    this.sourceUrl,
    required this.title,
    this.description,
    this.enhancedTitle,
    this.catchyDescription,
    this.highlights = const [],
    this.genreTags = const [],
    this.seoKeywords = const [],
    this.whatsAppTeaser,
    this.posterUrl,
    this.bannerUrl,
    this.eventStartDate,
    this.eventEndDate,
    this.startTime,
    this.endTime,
    this.venueName,
    this.venueAddress,
    this.city,
    this.state,
    this.minTicketPrice,
    this.maxTicketPrice,
    this.currency = 'INR',
    this.status = StagedStatus.pendingReview,
    this.duplicateOf,
    this.aiProcessed = false,
    this.aiProvider,
    this.aiModel,
    this.aiError,
    this.rawPayload,
    this.createdAt,
    this.updatedAt,
  });

  /// Returns the best display title (AI-enhanced title if available, otherwise original).
  String get displayTitle =>
      (enhancedTitle != null && enhancedTitle!.trim().isNotEmpty)
          ? enhancedTitle!.trim()
          : title;

  /// Returns the best display description.
  String get displayDescription =>
      (catchyDescription != null && catchyDescription!.trim().isNotEmpty)
          ? catchyDescription!.trim()
          : (description ?? '');

  /// Price display string e.g. "₹499" or "₹499 - ₹1,499" or "Price TBA"
  String get priceDisplay {
    if (minTicketPrice == null && maxTicketPrice == null) {
      return 'Price TBA';
    }
    if (minTicketPrice != null &&
        (maxTicketPrice == null || maxTicketPrice == minTicketPrice)) {
      return '₹${minTicketPrice!.toStringAsFixed(0)}';
    }
    if (minTicketPrice != null && maxTicketPrice != null) {
      return '₹${minTicketPrice!.toStringAsFixed(0)} - ₹${maxTicketPrice!.toStringAsFixed(0)}';
    }
    return '₹${maxTicketPrice!.toStringAsFixed(0)}';
  }

  // --- Rich Hierarchy Getters ---

  List<ScrapedPassItem> get passes {
    if (rawPayload == null) return const [];
    final rawPasses = rawPayload!['passes'];
    if (rawPasses is List) {
      return rawPasses
          .whereType<Map<String, dynamic>>()
          .map((p) => ScrapedPassItem.fromJson(p))
          .toList();
    }
    return const [];
  }

  List<ScrapedArtistItem> get artists {
    if (rawPayload == null) return const [];
    final rawArtists = rawPayload!['artists'];
    if (rawArtists is List) {
      return rawArtists
          .whereType<Map<String, dynamic>>()
          .map((a) => ScrapedArtistItem.fromJson(a))
          .toList();
    }
    return const [];
  }

  List<ScrapedDayItem> get days {
    if (rawPayload == null) return const [];
    final rawDays = rawPayload!['days'];
    if (rawDays is List) {
      return rawDays
          .whereType<Map<String, dynamic>>()
          .map((d) => ScrapedDayItem.fromJson(d))
          .toList();
    }
    return const [];
  }

  List<String> get facilities {
    if (rawPayload == null) return const [];
    final rawFacilities = rawPayload!['facilities'];
    if (rawFacilities is List) {
      return rawFacilities.map((f) => f.toString()).toList();
    }
    return const [];
  }

  List<String> get rules {
    if (rawPayload == null) return const [];
    final rawRules = rawPayload!['rules'];
    if (rawRules is List) {
      return rawRules.map((r) => r.toString()).toList();
    }
    return const [];
  }

  List<ScrapedArtworkCandidate> get artworkCandidates {
    if (rawPayload == null) return const [];
    final rawArtworks = rawPayload!['artwork_candidates'] ?? rawPayload!['artworkCandidates'];
    if (rawArtworks is List) {
      return rawArtworks
          .whereType<Map<String, dynamic>>()
          .map((a) => ScrapedArtworkCandidate.fromJson(a))
          .toList();
    }
    return const [];
  }

  factory StagedEvent.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return const [];
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    DateTime? parseDateTime(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    Map<String, dynamic>? parseRawPayload(dynamic val) {
      if (val is Map<String, dynamic>) return val;
      if (val is Map) {
        return val.map((k, v) => MapEntry(k.toString(), v));
      }
      return null;
    }

    return StagedEvent(
      id: json['id'] as int? ?? 0,
      source: json['source'] as String? ?? 'showmates',
      sourceEventId: json['source_event_id'] as String? ??
          json['sourceEventId'] as String? ??
          '',
      sourceUrl: json['source_url'] as String? ?? json['sourceUrl'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      enhancedTitle: json['enhanced_title'] as String? ??
          json['enhancedTitle'] as String?,
      catchyDescription: json['catchy_description'] as String? ??
          json['catchyDescription'] as String?,
      highlights: parseList(json['highlights']),
      genreTags: parseList(json['genre_tags'] ?? json['genreTags']),
      seoKeywords: parseList(json['seo_keywords'] ?? json['seoKeywords']),
      whatsAppTeaser: json['whatsapp_teaser'] as String? ??
          json['whatsAppTeaser'] as String?,
      posterUrl: json['poster_url'] as String? ?? json['posterUrl'] as String?,
      bannerUrl: json['banner_url'] as String? ?? json['bannerUrl'] as String?,
      eventStartDate: json['event_start_date'] as String? ??
          json['eventStartDate'] as String?,
      eventEndDate: json['event_end_date'] as String? ??
          json['eventEndDate'] as String?,
      startTime:
          json['start_time'] as String? ?? json['startTime'] as String?,
      endTime: json['end_time'] as String? ?? json['endTime'] as String?,
      venueName:
          json['venue_name'] as String? ?? json['venueName'] as String?,
      venueAddress: json['venue_address'] as String? ??
          json['venueAddress'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      minTicketPrice: parseDouble(
          json['min_ticket_price'] ?? json['minTicketPrice']),
      maxTicketPrice: parseDouble(
          json['max_ticket_price'] ?? json['maxTicketPrice']),
      currency: json['currency'] as String? ?? 'INR',
      status: StagedStatus.fromString(json['status'] as String?),
      duplicateOf: json['duplicate_of'] as int? ?? json['duplicateOf'] as int?,
      aiProcessed: json['ai_processed'] as bool? ??
          json['aiProcessed'] as bool? ??
          false,
      aiProvider:
          json['ai_provider'] as String? ?? json['aiProvider'] as String?,
      aiModel: json['ai_model'] as String? ?? json['aiModel'] as String?,
      aiError: json['ai_error'] as String? ?? json['aiError'] as String?,
      rawPayload: parseRawPayload(json['raw_payload'] ?? json['rawPayload']),
      createdAt: parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'source_event_id': sourceEventId,
        'source_url': sourceUrl,
        'title': title,
        'description': description,
        'enhanced_title': enhancedTitle,
        'catchy_description': catchyDescription,
        'highlights': highlights,
        'genre_tags': genreTags,
        'seo_keywords': seoKeywords,
        'whatsapp_teaser': whatsAppTeaser,
        'poster_url': posterUrl,
        'banner_url': bannerUrl,
        'event_start_date': eventStartDate,
        'event_end_date': eventEndDate,
        'start_time': startTime,
        'end_time': endTime,
        'venue_name': venueName,
        'venue_address': venueAddress,
        'city': city,
        'state': state,
        'min_ticket_price': minTicketPrice,
        'max_ticket_price': maxTicketPrice,
        'currency': currency,
        'status': status.toApiString(),
        'duplicate_of': duplicateOf,
        'ai_processed': aiProcessed,
        'ai_provider': aiProvider,
        'ai_model': aiModel,
        'ai_error': aiError,
        'raw_payload': rawPayload,
      };

  StagedEvent copyWith({
    int? id,
    String? source,
    String? sourceEventId,
    String? sourceUrl,
    String? title,
    String? description,
    String? enhancedTitle,
    String? catchyDescription,
    List<String>? highlights,
    List<String>? genreTags,
    List<String>? seoKeywords,
    String? whatsAppTeaser,
    String? posterUrl,
    String? bannerUrl,
    String? eventStartDate,
    String? eventEndDate,
    String? startTime,
    String? endTime,
    String? venueName,
    String? venueAddress,
    String? city,
    String? state,
    double? minTicketPrice,
    double? maxTicketPrice,
    String? currency,
    StagedStatus? status,
    int? duplicateOf,
    bool? aiProcessed,
    String? aiProvider,
    String? aiModel,
    String? aiError,
    Map<String, dynamic>? rawPayload,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StagedEvent(
      id: id ?? this.id,
      source: source ?? this.source,
      sourceEventId: sourceEventId ?? this.sourceEventId,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      enhancedTitle: enhancedTitle ?? this.enhancedTitle,
      catchyDescription: catchyDescription ?? this.catchyDescription,
      highlights: highlights ?? this.highlights,
      genreTags: genreTags ?? this.genreTags,
      seoKeywords: seoKeywords ?? this.seoKeywords,
      whatsAppTeaser: whatsAppTeaser ?? this.whatsAppTeaser,
      posterUrl: posterUrl ?? this.posterUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      eventStartDate: eventStartDate ?? this.eventStartDate,
      eventEndDate: eventEndDate ?? this.eventEndDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      venueName: venueName ?? this.venueName,
      venueAddress: venueAddress ?? this.venueAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      minTicketPrice: minTicketPrice ?? this.minTicketPrice,
      maxTicketPrice: maxTicketPrice ?? this.maxTicketPrice,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      duplicateOf: duplicateOf ?? this.duplicateOf,
      aiProcessed: aiProcessed ?? this.aiProcessed,
      aiProvider: aiProvider ?? this.aiProvider,
      aiModel: aiModel ?? this.aiModel,
      aiError: aiError ?? this.aiError,
      rawPayload: rawPayload ?? this.rawPayload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        source,
        sourceEventId,
        sourceUrl,
        title,
        description,
        enhancedTitle,
        catchyDescription,
        highlights,
        genreTags,
        seoKeywords,
        whatsAppTeaser,
        posterUrl,
        bannerUrl,
        eventStartDate,
        eventEndDate,
        startTime,
        endTime,
        venueName,
        venueAddress,
        city,
        state,
        minTicketPrice,
        maxTicketPrice,
        currency,
        status,
        duplicateOf,
        aiProcessed,
        aiProvider,
        aiModel,
        aiError,
        rawPayload,
      ];
}

/// Paginated list of staged events returned by Staging API.
class StagedEventListResponse extends Equatable {
  final List<StagedEvent> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const StagedEventListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory StagedEventListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    return StagedEventListResponse(
      items: list.map((e) => StagedEvent.fromJson(e as Map<String, dynamic>)).toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? json['pageSize'] as int? ?? 20,
      totalPages: json['total_pages'] as int? ?? json['totalPages'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [items, total, page, pageSize, totalPages];
}

/// Overall stats summary of staged events.
class StagedEventStats extends Equatable {
  final int total;
  final int pending;
  final int imported;
  final int rejected;
  final int conflicts;

  const StagedEventStats({
    this.total = 0,
    this.pending = 0,
    this.imported = 0,
    this.rejected = 0,
    this.conflicts = 0,
  });

  factory StagedEventStats.fromJson(Map<String, dynamic> json) {
    return StagedEventStats(
      total: json['total'] as int? ?? 0,
      pending: json['pending'] as int? ?? json['pendingReview'] as int? ?? 0,
      imported: json['imported'] as int? ?? 0,
      rejected: json['rejected'] as int? ?? 0,
      conflicts: json['conflicts'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [total, pending, imported, rejected, conflicts];
}

// =========================================================================
// UNIVERSAL LIVE DISCOVERY & DEEP SCRAPING MODELS
// =========================================================================

/// Lightweight discovery card item.
class DiscoveredEventItem extends Equatable {
  final String source;
  final String sourceEventId;
  final String title;
  final String eventUrl;
  final String? posterUrl;
  final String? bannerUrl;
  final String? venueName;
  final String? city;
  final String? eventStartDate;
  final String? eventEndDate;
  final double? startingPrice;
  final String currency;
  final String? category;
  final bool isAlreadyStaged;
  final bool isAlreadyInProduction;
  final String? discoveredAt;
  final Map<String, dynamic>? rawDiscoveryPayload;

  const DiscoveredEventItem({
    required this.source,
    required this.sourceEventId,
    required this.title,
    required this.eventUrl,
    this.posterUrl,
    this.bannerUrl,
    this.venueName,
    this.city,
    this.eventStartDate,
    this.eventEndDate,
    this.startingPrice,
    this.currency = 'INR',
    this.category,
    this.isAlreadyStaged = false,
    this.isAlreadyInProduction = false,
    this.discoveredAt,
    this.rawDiscoveryPayload,
  });

  String get priceDisplay {
    if (startingPrice == null || startingPrice == 0) return 'Free / TBA';
    return 'From ₹${startingPrice!.toStringAsFixed(0)}';
  }

  factory DiscoveredEventItem.fromJson(Map<String, dynamic> json) {
    double? parsePrice(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    Map<String, dynamic>? parsePayload(dynamic val) {
      if (val is Map<String, dynamic>) return val;
      if (val is Map) return val.map((k, v) => MapEntry(k.toString(), v));
      return null;
    }

    return DiscoveredEventItem(
      source: json['source'] as String? ?? '',
      sourceEventId: json['source_event_id'] as String? ?? json['sourceEventId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      eventUrl: json['event_url'] as String? ?? json['eventUrl'] as String? ?? '',
      posterUrl: json['poster_url'] as String? ?? json['posterUrl'] as String?,
      bannerUrl: json['banner_url'] as String? ?? json['bannerUrl'] as String?,
      venueName: json['venue_name'] as String? ?? json['venueName'] as String?,
      city: json['city'] as String?,
      eventStartDate: json['event_start_date'] as String? ?? json['eventStartDate'] as String?,
      eventEndDate: json['event_end_date'] as String? ?? json['eventEndDate'] as String?,
      startingPrice: parsePrice(json['starting_price'] ?? json['startingPrice']),
      currency: json['currency'] as String? ?? 'INR',
      category: json['category'] as String?,
      isAlreadyStaged: json['is_already_staged'] as bool? ?? json['isAlreadyStaged'] as bool? ?? false,
      isAlreadyInProduction: json['is_already_in_production'] as bool? ?? json['isAlreadyInProduction'] as bool? ?? false,
      discoveredAt: json['discovered_at'] as String? ?? json['discoveredAt'] as String?,
      rawDiscoveryPayload: parsePayload(json['raw_discovery_payload'] ?? json['rawDiscoveryPayload']),
    );
  }

  Map<String, dynamic> toJson() => {
        'source': source,
        'source_event_id': sourceEventId,
        'title': title,
        'event_url': eventUrl,
        'poster_url': posterUrl,
        'banner_url': bannerUrl,
        'venue_name': venueName,
        'city': city,
        'event_start_date': eventStartDate,
        'event_end_date': eventEndDate,
        'starting_price': startingPrice,
        'currency': currency,
        'category': category,
        'is_already_staged': isAlreadyStaged,
        'is_already_in_production': isAlreadyInProduction,
        'discovered_at': discoveredAt,
        'raw_discovery_payload': rawDiscoveryPayload,
      };

  @override
  List<Object?> get props => [
        source,
        sourceEventId,
        title,
        eventUrl,
        posterUrl,
        bannerUrl,
        venueName,
        city,
        eventStartDate,
        eventEndDate,
        startingPrice,
        currency,
        category,
        isAlreadyStaged,
        isAlreadyInProduction,
      ];
}

/// Response returned from live discovery API.
class DiscoverEventsResponse extends Equatable {
  final bool success;
  final String source;
  final String? city;
  final String? category;
  final int totalDiscovered;
  final List<DiscoveredEventItem> items;
  final String timestamp;

  const DiscoverEventsResponse({
    required this.success,
    required this.source,
    this.city,
    this.category,
    required this.totalDiscovered,
    required this.items,
    required this.timestamp,
  });

  factory DiscoverEventsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    return DiscoverEventsResponse(
      success: json['success'] as bool? ?? false,
      source: json['source'] as String? ?? 'all',
      city: json['city'] as String?,
      category: json['category'] as String?,
      totalDiscovered: json['total_discovered'] as int? ?? json['totalDiscovered'] as int? ?? 0,
      items: list.map((e) => DiscoveredEventItem.fromJson(e as Map<String, dynamic>)).toList(),
      timestamp: json['timestamp'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        success,
        source,
        city,
        category,
        totalDiscovered,
        items,
        timestamp,
      ];
}

/// Target payload for deep scraping.
class DeepScrapeSelectedTarget extends Equatable {
  final String source;
  final String sourceEventId;
  final String eventUrl;
  final String? title;
  final Map<String, dynamic>? hintPayload;

  const DeepScrapeSelectedTarget({
    required this.source,
    required this.sourceEventId,
    required this.eventUrl,
    this.title,
    this.hintPayload,
  });

  Map<String, dynamic> toJson() => {
        'source': source,
        'source_event_id': sourceEventId,
        'event_url': eventUrl,
        'title': title,
        'hint_payload': hintPayload,
      };

  @override
  List<Object?> get props => [source, sourceEventId, eventUrl, title, hintPayload];
}

/// Response returned from deep scraping selected events.
class DeepScrapeResultItem extends Equatable {
  final String source;
  final String sourceEventId;
  final int? stagingId;
  final String title;
  final String status;
  final String validationStatus;
  final bool isDuplicate;
  final int? duplicateOf;
  final String? message;

  const DeepScrapeResultItem({
    required this.source,
    required this.sourceEventId,
    this.stagingId,
    required this.title,
    required this.status,
    required this.validationStatus,
    this.isDuplicate = false,
    this.duplicateOf,
    this.message,
  });

  factory DeepScrapeResultItem.fromJson(Map<String, dynamic> json) {
    return DeepScrapeResultItem(
      source: json['source'] as String? ?? '',
      sourceEventId: json['source_event_id'] as String? ?? json['sourceEventId'] as String? ?? '',
      stagingId: json['staging_id'] as int? ?? json['stagingId'] as int?,
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING_REVIEW',
      validationStatus: json['validation_status'] as String? ?? json['validationStatus'] as String? ?? 'VALID',
      isDuplicate: json['is_duplicate'] as bool? ?? json['isDuplicate'] as bool? ?? false,
      duplicateOf: json['duplicate_of'] as int? ?? json['duplicateOf'] as int?,
      message: json['message'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        source,
        sourceEventId,
        stagingId,
        title,
        status,
        validationStatus,
        isDuplicate,
        duplicateOf,
        message,
      ];
}

class DeepScrapeResponse extends Equatable {
  final bool success;
  final int totalRequested;
  final int totalStaged;
  final int totalDuplicates;
  final int totalFailed;
  final List<DeepScrapeResultItem> results;
  final String message;

  const DeepScrapeResponse({
    required this.success,
    required this.totalRequested,
    required this.totalStaged,
    required this.totalDuplicates,
    required this.totalFailed,
    required this.results,
    required this.message,
  });

  factory DeepScrapeResponse.fromJson(Map<String, dynamic> json) {
    final resList = json['results'] as List? ?? [];
    return DeepScrapeResponse(
      success: json['success'] as bool? ?? false,
      totalRequested: json['total_requested'] as int? ?? json['totalRequested'] as int? ?? 0,
      totalStaged: json['total_staged'] as int? ?? json['totalStaged'] as int? ?? 0,
      totalDuplicates: json['total_duplicates'] as int? ?? json['totalDuplicates'] as int? ?? 0,
      totalFailed: json['total_failed'] as int? ?? json['totalFailed'] as int? ?? 0,
      results: resList.map((e) => DeepScrapeResultItem.fromJson(e as Map<String, dynamic>)).toList(),
      message: json['message'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        success,
        totalRequested,
        totalStaged,
        totalDuplicates,
        totalFailed,
        results,
        message,
      ];
}

/// Phase 2 Import Batch Result DTO returned by Spring Boot.
class StagedImportBatchResult extends Equatable {
  final int totalRequested;
  final int imported;
  final int alreadyImported;
  final int conflicts;
  final int failed;
  final List<StagedEventImportResultItem> results;

  const StagedImportBatchResult({
    required this.totalRequested,
    required this.imported,
    required this.alreadyImported,
    required this.conflicts,
    required this.failed,
    required this.results,
  });

  factory StagedImportBatchResult.fromJson(Map<String, dynamic> json) {
    final resultsList = json['results'] as List? ?? [];
    return StagedImportBatchResult(
      totalRequested: json['totalRequested'] as int? ?? 0,
      imported: json['imported'] as int? ?? 0,
      alreadyImported: json['alreadyImported'] as int? ?? 0,
      conflicts: json['conflicts'] as int? ?? 0,
      failed: json['failed'] as int? ?? 0,
      results: resultsList
          .map((e) => StagedEventImportResultItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        totalRequested,
        imported,
        alreadyImported,
        conflicts,
        failed,
        results,
      ];
}

/// Individual item status in an import batch result.
class StagedEventImportResultItem extends Equatable {
  final int stagedEventId;
  final String status; // "SUCCESS", "CONFLICT", "ALREADY_IMPORTED", "FAILED"
  final int? productionEventId;
  final String eventName;
  final String slug;
  final String? reason;

  const StagedEventImportResultItem({
    required this.stagedEventId,
    required this.status,
    this.productionEventId,
    required this.eventName,
    required this.slug,
    this.reason,
  });

  bool get isSuccess =>
      status.toUpperCase() == 'SUCCESS' || status.toUpperCase() == 'IMPORTED';
  bool get isConflict => status.toUpperCase() == 'CONFLICT';
  bool get isAlreadyImported => status.toUpperCase() == 'ALREADY_IMPORTED';
  bool get isFailed =>
      status.toUpperCase() == 'FAILED' || status.toUpperCase() == 'REJECTED';

  factory StagedEventImportResultItem.fromJson(Map<String, dynamic> json) {
    return StagedEventImportResultItem(
      stagedEventId: json['stagedEventId'] as int? ?? 0,
      status: json['status'] as String? ?? 'FAILED',
      productionEventId: json['productionEventId'] as int?,
      eventName: json['eventName'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      reason: json['reason'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        stagedEventId,
        status,
        productionEventId,
        eventName,
        slug,
        reason,
      ];
}
