class UpiPaymentResponse {
  final String transactionReference;
  final double totalAmount;
  final String upiUrl;
  final String upiVpa;
  final String merchantName;
  final String status;
  final List<String> itemizedBreakdown;
  final String? note;

  const UpiPaymentResponse({
    required this.transactionReference,
    required this.totalAmount,
    required this.upiUrl,
    required this.upiVpa,
    required this.merchantName,
    required this.status,
    required this.itemizedBreakdown,
    this.note,
  });

  factory UpiPaymentResponse.fromJson(Map<String, dynamic> json) => UpiPaymentResponse(
        transactionReference: json['transactionReference']?.toString() ?? '',
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
        upiUrl: json['upiUrl']?.toString() ?? '',
        upiVpa: json['upiVpa']?.toString() ?? '',
        merchantName: json['merchantName']?.toString() ?? 'VibeMyNight',
        status: json['status']?.toString() ?? 'INITIATED',
        itemizedBreakdown: (json['itemizedBreakdown'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        note: json['note']?.toString(),
      );
}
