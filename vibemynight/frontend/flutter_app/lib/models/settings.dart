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
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        websiteName: json['websiteName'] as String? ?? 'VibeMyNight',
        logoUrl: json['logoUrl'] as String?,
        whatsappNumber: json['whatsappNumber'] as String,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        instagramUrl: json['instagramUrl'] as String?,
        facebookUrl: json['facebookUrl'] as String?,
        currency: json['currency'] as String? ?? 'INR',
        footerText: json['footerText'] as String?,
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
      };
}
