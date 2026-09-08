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
        id: json['id'] as int,
        name: json['name'] as String,
        slug: json['slug'] as String,
        photoUrl: json['photoUrl'] as String?,
        type: json['type'] as String,
        shortBio: json['shortBio'] as String?,
        fullBio: json['fullBio'] as String?,
        instagramUrl: json['instagramUrl'] as String?,
        facebookUrl: json['facebookUrl'] as String?,
        youtubeUrl: json['youtubeUrl'] as String?,
        featured: json['featured'] as bool? ?? false,
        status: json['status'] as String,
      );
}
