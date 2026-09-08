import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/inquiry.dart';

class InquiryService {
  InquiryService(this._client);
  final ApiClient _client;

  Future<InquiryResponse> submitInquiry(CreateInquiryRequest request) async {
    final data = await _client.post(ApiConstants.inquiries, body: request.toJson());
    return InquiryResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<InquiryResponse> getByInquiryNumber(String inquiryNumber) async {
    final data = await _client.get(ApiConstants.inquiryByNumber(inquiryNumber));
    return InquiryResponse.fromJson(data as Map<String, dynamic>);
  }
}
