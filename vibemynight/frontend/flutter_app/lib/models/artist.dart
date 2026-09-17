class Artist {
  final int id;
  final String name;
  final String slug;
  final String? photoUrl;
  final String type;
  final String? shortBio;
  final String? fullBio;
  final String? instagramUrl;
  final String? facebookUrl;
  final String? youtubeUrl;
  final bool featured;
  final String status;

  const Artist({
    required this.id,
    required this.name,
    required this.slug,
    this.photoUrl,
    required this.type,
    this.shortBio,
    this.fullBio,
    this.instagramUrl,
    this.facebookUrl,
    this.youtubeUrl,
    required this.featured,
    required this.status,
  });

  factory Artist.fromJson(Map<String, dynamic> json) => Artist(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        photoUrl: json['photoUrl']?.toString(),
        type: json['type']?.toString() ?? 'ARTIST',
        shortBio: json['shortBio']?.toString(),
        fullBio: json['fullBio']?.toString(),
        instagramUrl: json['instagramUrl']?.toString(),
        facebookUrl: json['facebookUrl']?.toString(),
        youtubeUrl: json['youtubeUrl']?.toString(),
        featured: json['featured'] == true,
        status: json['status']?.toString() ?? 'ACTIVE',
      );
}
