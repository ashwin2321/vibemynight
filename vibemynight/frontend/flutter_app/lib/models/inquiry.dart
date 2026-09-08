/// Request payload for POST /inquiries. Deliberately has no price/total field -
/// the backend always computes those itself.
class CreateInquiryRequest {
  final String customerName;
  final String customerMobile;
  final String? customerEmail;
  final int eventDayId;
  final int ticketCategoryId;
  final int quantity;
  final String? message;

  const CreateInquiryRequest({
    required this.customerName,
    required this.customerMobile,
    this.customerEmail,
    required this.eventDayId,
    required this.ticketCategoryId,
    required this.quantity,
    this.message,
  });

  Map<String, dynamic> toJson() => {
        'customerName': customerName,
        'customerMobile': customerMobile,
        if (customerEmail != null && customerEmail!.isNotEmpty) 'customerEmail': customerEmail,
        'eventDayId': eventDayId,
        'ticketCategoryId': ticketCategoryId,
        'quantity': quantity,
        if (message != null && message!.isNotEmpty) 'message': message,
      };
}

/// Everything needed to render the confirmation screen and open WhatsApp -
/// price/total/whatsappUrl are all server-derived.
class InquiryResponse {
  final int id;
  final String inquiryNumber;
  final String status;
  final String customerName;
  final String customerMobile;
  final String? customerEmail;
  final int eventId;
  final String eventName;
  final int eventDayId;
  final int? dayNumber;
  final String? date;
  final String? programName;
  final int? artistId;
  final String? artistName;
  final String? startTime;
  final String? endTime;
  final String? venue;
  final String? location;
  final int ticketCategoryId;
  final String ticketCategoryName;
  final double price;
  final int quantity;
  final double estimatedTotal;
  final String? customerMessage;
  final String? whatsappNumber;
  final String? whatsappMessage;
  final String? whatsappUrl;
  final String? createdAt;

  const InquiryResponse({
    required this.id,
    required this.inquiryNumber,
    required this.status,
    required this.customerName,
    required this.customerMobile,
    this.customerEmail,
    required this.eventId,
    required this.eventName,
    required this.eventDayId,
    this.dayNumber,
    this.date,
    this.programName,
    this.artistId,
    this.artistName,
    this.startTime,
    this.endTime,
    this.venue,
    this.location,
    required this.ticketCategoryId,
    required this.ticketCategoryName,
    required this.price,
    required this.quantity,
    required this.estimatedTotal,
    this.customerMessage,
    this.whatsappNumber,
    this.whatsappMessage,
    this.whatsappUrl,
    this.createdAt,
  });

  factory InquiryResponse.fromJson(Map<String, dynamic> json) => InquiryResponse(
        id: json['id'] as int,
        inquiryNumber: json['inquiryNumber'] as String,
        status: json['status'] as String,
        customerName: json['customerName'] as String,
        customerMobile: json['customerMobile'] as String,
        customerEmail: json['customerEmail'] as String?,
        eventId: json['eventId'] as int,
        eventName: json['eventName'] as String,
        eventDayId: json['eventDayId'] as int,
        dayNumber: json['dayNumber'] as int?,
        date: json['date'] as String?,
        programName: json['programName'] as String?,
        artistId: json['artistId'] as int?,
        artistName: json['artistName'] as String?,
        startTime: json['startTime'] as String?,
        endTime: json['endTime'] as String?,
        venue: json['venue'] as String?,
        location: json['location'] as String?,
        ticketCategoryId: json['ticketCategoryId'] as int,
        ticketCategoryName: json['ticketCategoryName'] as String,
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'] as int,
        estimatedTotal: (json['estimatedTotal'] as num).toDouble(),
        customerMessage: json['customerMessage'] as String?,
        whatsappNumber: json['whatsappNumber'] as String?,
        whatsappMessage: json['whatsappMessage'] as String?,
        whatsappUrl: json['whatsappUrl'] as String?,
        createdAt: json['createdAt'] as String?,
      );
}
