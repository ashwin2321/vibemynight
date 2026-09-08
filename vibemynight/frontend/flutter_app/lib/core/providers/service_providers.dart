import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/admin_service.dart';
import '../../services/artist_service.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../services/facility_service.dart';
import '../../services/inquiry_service.dart';
import '../../services/settings_service.dart';
import '../network/api_client.dart';

/// Single ApiClient instance shared by every service - all HTTP traffic
/// (customer reads, admin writes, auth) goes through this one Dio wrapper.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient.instance);

final eventServiceProvider =
    Provider<EventService>((ref) => EventService(ref.watch(apiClientProvider)));

final artistServiceProvider =
    Provider<ArtistService>((ref) => ArtistService(ref.watch(apiClientProvider)));

final facilityServiceProvider =
    Provider<FacilityService>((ref) => FacilityService(ref.watch(apiClientProvider)));

final settingsServiceProvider =
    Provider<SettingsService>((ref) => SettingsService(ref.watch(apiClientProvider)));

final inquiryServiceProvider =
    Provider<InquiryService>((ref) => InquiryService(ref.watch(apiClientProvider)));

final authServiceProvider =
    Provider<AuthService>((ref) => AuthService(ref.watch(apiClientProvider)));

/// All admin read/write operations (Events, Days, Artists, Facilities,
/// Passes, Gallery/Highlights/Rules, Inquiries, Settings) - see
/// services/admin_service.dart for why this is one class instead of one
/// per resource.
final adminServiceProvider =
    Provider<AdminService>((ref) => AdminService(ref.watch(apiClientProvider)));
