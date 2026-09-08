/// One row of the admin inquiries table (GET /admin/inquiries).
class InquiryAdminSummary {
  final int id;
  final String inquiryNumber;
  final String customerName;
  final String customerMobile;
  final String eventName;
  final int? dayNumber;
  final String? date;
  final String? artistName;
  final String ticketCategoryName;
  final double price;
  final int quantity;
  final double estimatedTotal;
  final String status;
  final String? createdAt;

  const InquiryAdminSummary({
    required this.id,
    required this.inquiryNumber,
    required this.customerName,
    required this.customerMobile,
    required this.eventName,
    this.dayNumber,
    this.date,
    this.artistName,
    required this.ticketCategoryName,
    required this.price,
    required this.quantity,
    required this.estimatedTotal,
    required this.status,
    this.createdAt,
  });

  factory InquiryAdminSummary.fromJson(Map<String, dynamic> json) => InquiryAdminSummary(
        id: json['id'] as int,
        inquiryNumber: json['inquiryNumber'] as String,
        customerName: json['customerName'] as String,
        customerMobile: json['customerMobile'] as String,
        eventName: json['eventName'] as String,
        dayNumber: json['dayNumber'] as int?,
        date: json['date'] as String?,
        artistName: json['artistName'] as String?,
        ticketCategoryName: json['ticketCategoryName'] as String,
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'] as int,
        estimatedTotal: (json['estimatedTotal'] as num).toDouble(),
        status: json['status'] as String,
        createdAt: json['createdAt'] as String?,
      );
}
