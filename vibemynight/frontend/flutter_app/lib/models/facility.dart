class Facility {
  final int id;
  final String name;
  final String? icon;
  final String? description;
  final String status;

  const Facility({
    required this.id,
    required this.name,
    this.icon,
    this.description,
    required this.status,
  });

  factory Facility.fromJson(Map<String, dynamic> json) => Facility(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        icon: json['icon']?.toString(),
        description: json['description']?.toString(),
        status: json['status']?.toString() ?? 'ACTIVE',
      );
}
