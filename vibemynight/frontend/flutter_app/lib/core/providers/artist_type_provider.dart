import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kArtistTypesStorageKey = 'vmn_artist_types_v1';
const _storage = FlutterSecureStorage();

const defaultArtistTypes = <String>[
  'SINGER',
  'DJ',
  'BAND',
  'CELEBRITY',
  'PERFORMER',
  'LIVE_ARTIST',
  'DHOL_PLAYER',
  'HOST',
  'ANCHOR',
  'COMEDIAN',
  'DANCER',
  'MUSICIAN',
  'FOLK_ARTIST',
  'INSTRUMENTALIST',
  'SPECIAL_GUEST',
  'ACTOR',
  'INFLUENCER',
  'RAPPER',
  'OTHER',
];

const Map<String, String> coreArtistTypeLabels = {
  'SINGER': 'Singer / Vocalist',
  'DJ': 'DJ / Music Producer',
  'BAND': 'Band / Orchestra / Mandli',
  'CELEBRITY': 'Celebrity / Special Appearance',
  'PERFORMER': 'Performer / Stage Artist',
  'LIVE_ARTIST': 'Live Artist',
  'DHOL_PLAYER': 'Dhol Player / Percussionist',
  'HOST': 'Host / MC',
  'ANCHOR': 'Anchor / Presenter',
  'COMEDIAN': 'Comedian / Standup',
  'DANCER': 'Dancer / Dance Troupe',
  'MUSICIAN': 'Musician / Composer',
  'FOLK_ARTIST': 'Folk Artist / Traditional',
  'INSTRUMENTALIST': 'Instrumentalist',
  'SPECIAL_GUEST': 'Special Guest',
  'ACTOR': 'Actor / Actress',
  'INFLUENCER': 'Influencer / Creator',
  'RAPPER': 'Rapper / Hip-Hop',
  'OTHER': 'Other / Custom Role',
};

String formatArtistType(String code) {
  if (coreArtistTypeLabels.containsKey(code)) {
    return coreArtistTypeLabels[code]!;
  }
  // Convert custom codes like GARBA_SINGER -> Garba Singer
  return code
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}

class ArtistTypesNotifier extends StateNotifier<List<String>> {
  ArtistTypesNotifier() : super(defaultArtistTypes) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final raw = await _storage.read(key: _kArtistTypesStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = (jsonDecode(raw) as List).cast<String>();
        if (decoded.isNotEmpty) {
          final merged = {...defaultArtistTypes, ...decoded}.toList();
          state = merged;
        }
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      await _storage.write(key: _kArtistTypesStorageKey, value: jsonEncode(state));
    } catch (_) {}
  }

  Future<String> addArtistType(String type) async {
    final clean = type.trim().toUpperCase().replaceAll(' ', '_');
    if (clean.isEmpty) return 'OTHER';
    if (!state.contains(clean)) {
      state = [...state, clean];
      await _persist();
    }
    return clean;
  }

  Future<void> deleteArtistType(String type) async {
    state = state.where((t) => t != type).toList();
    await _persist();
  }

  Future<void> resetArtistTypes() async {
    state = defaultArtistTypes;
    await _persist();
  }
}

final artistTypesProvider = StateNotifierProvider<ArtistTypesNotifier, List<String>>((ref) {
  return ArtistTypesNotifier();
});
