/// Central place for backend base URL and endpoint paths.
///
/// Per the spec, no business data (WhatsApp number, prices, event data) is
/// ever hardcoded here - only the API shape itself. The WhatsApp number is
/// fetched at runtime from GET /settings/public.
class ApiConstants {
  ApiConstants._();

  static String get baseUrl {
    const raw = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://vibemynight.onrender.com/api/v1',
    );
    if (raw.endsWith('/api/v1')) {
      return raw;
    }
    return raw.endsWith('/') ? '${raw}api/v1' : '$raw/api/v1';
  }

  static String get publicAppUrl {
    const raw = String.fromEnvironment(
      'PUBLIC_APP_URL',
      defaultValue: 'https://vibemynight.in',
    );
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  // ---- Public ----
  static const String events = '/events';
  static String eventBySlug(String slug) => '/events/$slug';
  static String eventDays(int eventId) => '/events/$eventId/days';
  static String eventDayDetail(int dayId) => '/event-days/$dayId';
  static String eventDayPasses(int dayId) => '/event-days/$dayId/passes';
  static const String artists = '/artists';
  static String artistById(int id) => '/artists/$id';
  static const String facilities = '/facilities';
  static const String settingsPublic = '/settings/public';
  static const String inquiries = '/inquiries';
  static String inquiryByNumber(String number) => '/inquiries/$number';
  static const String paymentsUpiInitiate = '/payments/upi/initiate';

  // ---- Auth ----
  static const String login = '/auth/login';

  // ---- Admin ----
  static const String adminEvents = '/admin/events';
  static String adminEventById(int id) => '/admin/events/$id';
  static String adminEventStatus(int id) => '/admin/events/$id/status';
  static String adminEventHero(int id) => '/admin/events/$id/hero';
  static String adminEventDays(int eventId) => '/admin/events/$eventId/days';
  static String adminEventDayById(int id) => '/admin/event-days/$id';
  static String adminEventDayArtists(int dayId) => '/admin/event-days/$dayId/artists';
  static String adminEventDayArtistById(int dayId, int artistId) =>
      '/admin/event-days/$dayId/artists/$artistId';
  static const String adminArtists = '/admin/artists';
  static String adminArtistById(int id) => '/admin/artists/$id';
  static String adminArtistStatus(int id) => '/admin/artists/$id/status';
  static const String adminFacilities = '/admin/facilities';
  static String adminFacilityById(int id) => '/admin/facilities/$id';
  static String adminFacilityStatus(int id) => '/admin/facilities/$id/status';
  static String adminEventDayPasses(int dayId) => '/admin/event-days/$dayId/passes';
  static String adminPassById(int id) => '/admin/passes/$id';
  static String adminEventGallery(int eventId) => '/admin/events/$eventId/gallery';
  static String adminGalleryById(int id) => '/admin/gallery/$id';
  static String adminEventHighlights(int eventId) => '/admin/events/$eventId/highlights';
  static String adminHighlightById(int id) => '/admin/highlights/$id';
  static String adminEventRules(int eventId) => '/admin/events/$eventId/rules';
  static String adminRuleById(int id) => '/admin/rules/$id';
  static const String adminSettings = '/admin/settings';
  static const String imagesProxy = '/images/proxy';
  static String imagesProxyUrl(String targetUrl) =>
      '$baseUrl/images/proxy?url=${Uri.encodeComponent(targetUrl)}';
  static const String adminUploads = '/admin/uploads';
  static const String adminUploadsFromUrl = '/admin/uploads/from-url';
  static const String adminEventImportParse = '/admin/events/import/parse';
  static const String adminEventImportUrl = '/admin/events/import/url';
  static const String adminEventImportTemplate = '/admin/events/import/template';
  static const String adminEventImportConfirm = '/admin/events/import/confirm';
  static const String adminInquiries = '/admin/inquiries';
  static String adminInquiryById(int id) => '/admin/inquiries/$id';
  static String adminInquiryStatus(int id) => '/admin/inquiries/$id/status';

  // ---- Phase 2 & 3: Staging & Sync Hub ----
  static const String adminStagedEventsImport = '/admin/events/import-staged';

  static String get stagingSyncBaseUrl {
    const raw = String.fromEnvironment(
      'STAGING_SYNC_URL',
      defaultValue: 'https://vibemynight.up.railway.app/api/v1',
    );
    if (raw.endsWith('/api/v1')) {
      return raw;
    }
    return raw.endsWith('/') ? '${raw}api/v1' : '$raw/api/v1';
  }

  static const String syncEvents = '/sync/events';
  static String syncEventById(int id) => '/sync/events/$id';
  static const String syncFetchNow = '/sync/fetch-now';
  static const String syncStats = '/sync/stats';
  static const String syncDiscover = '/sync/discover';
  static const String syncDeepScrape = '/sync/deep-scrape';
}

