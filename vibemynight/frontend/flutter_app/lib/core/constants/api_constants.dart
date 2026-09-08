/// Central place for backend base URL and endpoint paths.
///
/// Per the spec, no business data (WhatsApp number, prices, event data) is
/// ever hardcoded here - only the API shape itself. The WhatsApp number is
/// fetched at runtime from GET /settings/public.
class ApiConstants {
  ApiConstants._();

  /// Overridden per-flavor via --dart-define=API_BASE_URL=... at build time.
  /// Defaults to a local backend for development.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

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

  // ---- Auth ----
  static const String login = '/auth/login';

  // ---- Admin ----
  static const String adminEvents = '/admin/events';
  static String adminEventById(int id) => '/admin/events/$id';
  static String adminEventStatus(int id) => '/admin/events/$id/status';
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
  static const String adminUploads = '/admin/uploads';
  static const String adminInquiries = '/admin/inquiries';
  static String adminInquiryById(int id) => '/admin/inquiries/$id';
  static String adminInquiryStatus(int id) => '/admin/inquiries/$id/status';
}
