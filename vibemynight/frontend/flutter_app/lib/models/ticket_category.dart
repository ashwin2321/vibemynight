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
        id: (json['id'] as num?)?.toInt() ?? 0,
        eventDayId: (json['eventDayId'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        type: json['type']?.toString() ?? 'REGULAR',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        availableQuantity: (json['availableQuantity'] as num?)?.toInt() ?? 0,
        maxPerCustomer: (json['maxPerCustomer'] as num?)?.toInt() ?? 10,
        description: json['description']?.toString(),
        benefits: (json['benefits'] as List?)
                ?.map((e) => e.toString())
                .where((s) => s.isNotEmpty)
                .toList() ??
            const [],
        status: json['status']?.toString() ?? 'AVAILABLE',
        soldOut: json['soldOut'] == true,
      );

  bool get lowStock => !soldOut && availableQuantity <= 10;
}
