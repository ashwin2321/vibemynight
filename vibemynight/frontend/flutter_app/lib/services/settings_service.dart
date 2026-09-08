import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/settings.dart';

class SettingsService {
  SettingsService(this._client);
  final ApiClient _client;

  Future<AppSettings> getPublicSettings() async {
    final data = await _client.get(ApiConstants.settingsPublic);
    return AppSettings.fromJson(data as Map<String, dynamic>);
  }
}
