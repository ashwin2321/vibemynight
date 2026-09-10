import 'package:equatable/equatable.dart';

/// Reusable Pass Template for Master Pass Catalog & Multi-Event Pricing.
/// Allows administrators to define standard rates (e.g. ₹200 Early Entry, ₹499 Regular, ₹1499 Couple)
/// and reuse them across any Event or Day with 1-click.
class PassTemplate extends Equatable {
  final String id;
  final String name;
  final String type;
  final double price;
  final int defaultQuantity;
  final int maxPerCustomer;
  final List<String> benefits;
  final String? description;

  const PassTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    this.defaultQuantity = 500,
    this.maxPerCustomer = 5,
    this.benefits = const [],
    this.description,
  });

  PassTemplate copyWith({
    String? id,
    String? name,
    String? type,
    double? price,
    int? defaultQuantity,
    int? maxPerCustomer,
    List<String>? benefits,
    String? description,
  }) {
    return PassTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      price: price ?? this.price,
      defaultQuantity: defaultQuantity ?? this.defaultQuantity,
      maxPerCustomer: maxPerCustomer ?? this.maxPerCustomer,
      benefits: benefits ?? this.benefits,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'price': price,
        'defaultQuantity': defaultQuantity,
        'maxPerCustomer': maxPerCustomer,
        'benefits': benefits,
        'description': description,
      };

  factory PassTemplate.fromJson(Map<String, dynamic> json) => PassTemplate(
        id: json['id'] as String? ?? 'tpl_${DateTime.now().millisecondsSinceEpoch}',
        name: json['name'] as String,
        type: json['type'] as String? ?? 'REGULAR',
        price: (json['price'] as num).toDouble(),
        defaultQuantity: json['defaultQuantity'] as int? ?? 500,
        maxPerCustomer: json['maxPerCustomer'] as int? ?? 5,
        benefits: (json['benefits'] as List?)?.cast<String>() ?? const [],
        description: json['description'] as String?,
      );

  @override
  List<Object?> get props => [id, name, type, price, defaultQuantity, maxPerCustomer, benefits, description];
}
