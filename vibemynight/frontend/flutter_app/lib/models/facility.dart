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
        id: json['id'] as int,
        name: json['name'] as String,
        icon: json['icon'] as String?,
        description: json['description'] as String?,
        status: json['status'] as String,
      );
}
