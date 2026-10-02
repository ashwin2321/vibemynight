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
        return StagedStatus.conflict;
      case 'PENDING_REVIEW':
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
        return 'Conflict';
      case StagedStatus.pendingReview:
        return 'Pending Review';
    }
  }
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

  /// Price display string e.g. "₹499" or "₹499 - ₹1,499" or "Free / Contact"
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
