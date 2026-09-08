class TicketCategory {
  final int id;
  final int eventDayId;
  final String name;
  final String type;
  final double price;
  final int availableQuantity;
  final int maxPerCustomer;
  final String? description;
  final List<String> benefits;
  final String status;
  final bool soldOut;

  const TicketCategory({
    required this.id,
    required this.eventDayId,
    required this.name,
    required this.type,
    required this.price,
    required this.availableQuantity,
    required this.maxPerCustomer,
    this.description,
    required this.benefits,
    required this.status,
    required this.soldOut,
  });

  factory TicketCategory.fromJson(Map<String, dynamic> json) => TicketCategory(
        id: json['id'] as int,
        eventDayId: json['eventDayId'] as int,
        name: json['name'] as String,
        type: json['type'] as String,
        price: (json['price'] as num).toDouble(),
        availableQuantity: json['availableQuantity'] as int,
        maxPerCustomer: json['maxPerCustomer'] as int,
        description: json['description'] as String?,
        benefits: (json['benefits'] as List?)?.cast<String>() ?? const [],
        status: json['status'] as String,
        soldOut: json['soldOut'] as bool? ?? false,
      );

  bool get lowStock => !soldOut && availableQuantity <= 10;
}
