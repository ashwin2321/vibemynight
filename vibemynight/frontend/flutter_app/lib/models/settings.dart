/// Public site settings - notably the WhatsApp number, fetched at runtime
/// rather than hardcoded anywhere in the app.
class AppSettings {
  final String websiteName;
  final String? logoUrl;
  final String whatsappNumber;
  final String? phone;
  final String? email;
  final String? instagramUrl;
  final String? facebookUrl;
  final String currency;
  final String? footerText;
  final bool upiEnabled;
  final String? upiVpa;
  final String? upiMerchantName;

  const AppSettings({
    required this.websiteName,
    this.logoUrl,
    required this.whatsappNumber,
    this.phone,
    this.email,
    this.instagramUrl,
    this.facebookUrl,
    required this.currency,
    this.footerText,
    this.upiEnabled = false,
    this.upiVpa,
    this.upiMerchantName,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        websiteName: json['websiteName']?.toString() ?? 'VibeMyNight',
        logoUrl: json['logoUrl']?.toString(),
        whatsappNumber: json['whatsappNumber']?.toString() ?? '917041615131',
        phone: json['phone']?.toString(),
        email: json['email']?.toString(),
        instagramUrl: json['instagramUrl']?.toString(),
        facebookUrl: json['facebookUrl']?.toString(),
        currency: json['currency']?.toString() ?? 'INR',
        footerText: json['footerText']?.toString(),
        upiEnabled: json['upiEnabled'] == true,
        upiVpa: json['upiVpa']?.toString(),
        upiMerchantName: json['upiMerchantName']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'websiteName': websiteName,
        'logoUrl': logoUrl,
        'whatsappNumber': whatsappNumber,
        'phone': phone,
        'email': email,
        'instagramUrl': instagramUrl,
        'facebookUrl': facebookUrl,
        'currency': currency,
        'footerText': footerText,
        'upiEnabled': upiEnabled,
        'upiVpa': upiVpa,
        'upiMerchantName': upiMerchantName,
      };
}
