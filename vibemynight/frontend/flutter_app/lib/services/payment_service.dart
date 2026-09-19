import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/upi_payment.dart';

class PaymentService {
  PaymentService(this._client);
  final ApiClient _client;

  Future<UpiPaymentResponse> initiateUpi({
    required int eventId,
    required int eventDayId,
    required Map<int, int> selectedQuantities,
    required String customerName,
    required String customerMobile,
    String? customerEmail,
  }) async {
    final quantitiesMap = <String, int>{};
    selectedQuantities.forEach((key, value) {
      if (value > 0) {
        quantitiesMap[key.toString()] = value;
      }
    });

    final body = {
      'eventId': eventId,
      'eventDayId': eventDayId,
      'selectedQuantities': quantitiesMap,
      'customerName': customerName,
      'customerMobile': customerMobile,
      if (customerEmail != null && customerEmail.isNotEmpty) 'customerEmail': customerEmail,
    };

    final data = await _client.post(ApiConstants.paymentsUpiInitiate, body: body);
    return UpiPaymentResponse.fromJson(data as Map<String, dynamic>);
  }
}
