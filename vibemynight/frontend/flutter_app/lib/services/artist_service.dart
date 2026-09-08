import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/artist.dart';

class ArtistService {
  ArtistService(this._client);
  final ApiClient _client;

  Future<List<Artist>> getArtists() async {
    final data = await _client.get(ApiConstants.artists) as List;
    return data.map((e) => Artist.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Artist> getArtistById(int id) async {
    final data = await _client.get(ApiConstants.artistById(id));
    return Artist.fromJson(data as Map<String, dynamic>);
  }
}
