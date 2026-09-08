import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/facility.dart';

class FacilityService {
  FacilityService(this._client);
  final ApiClient _client;

  Future<List<Facility>> getFacilities() async {
    final data = await _client.get(ApiConstants.facilities) as List;
    return data.map((e) => Facility.fromJson(e as Map<String, dynamic>)).toList();
  }
}
