import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_footer.dart';
import '../../core/widgets/app_navbar.dart';
import '../../core/widgets/glass_card.dart';

/// "Contact Us" public screen matching Figma ContactPage.tsx.
/// Channel cards (WhatsApp, Phone, Email, Instagram, Facebook), WhatsApp CTA, and Footer.
class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchWhatsApp(String? number) async {
    final clean = (number ?? '917041615131').replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = settingsAsync.value;
    final whatsapp = settings?.whatsappNumber ?? '917041615131';
    final phone = settings?.phone ?? '+91 70416 15131';
    final email = settings?.email ?? 'hello@vibemynight.com';
    final instagram = settings?.instagramUrl ?? 'https://instagram.com/vibemynight';
    final facebook = settings?.facebookUrl ?? 'https://facebook.com/vibemynight';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppNavbar(currentRoute: '/contact'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GET IN TOUCH',
                        style: TextStyle(
                          color: AppColors.neonPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Contact Us',
                        style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'We are just a message away. Reach out via any channel below.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      ),
                      const SizedBox(height: 36),

                      // Contact Channel Grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 600;
                          return GridView.count(
                            crossAxisCount: isWide ? 3 : 1,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: isWide ? 1.5 : 2.5,
                            children: [
                              _ContactCard(
                                icon: '💬',
                                label: 'WhatsApp',
                                value: whatsapp,
                                accentColor: const Color(0xFF25D366),
                                onTap: () => _launchWhatsApp(whatsapp),
                              ),
                              _ContactCard(
                                icon: '📞',
                                label: 'Phone',
                                value: phone,
                                accentColor: AppColors.neonBlue,
                                onTap: () => _launch('tel:$phone'),
                              ),
                              _ContactCard(
                                icon: '✉️',
                                label: 'Email',
                                value: email,
                                accentColor: AppColors.neonPurple,
                                onTap: () => _launch('mailto:$email'),
                              ),
                              _ContactCard(
                                icon: '📸',
                                label: 'Instagram',
                                value: '@vibemynight',
                                accentColor: AppColors.neonPink,
                                onTap: () => _launch(instagram),
                              ),
                              _ContactCard(
                                icon: '👤',
                                label: 'Facebook',
                                value: 'VibeMyNight',
                                accentColor: const Color(0xFF1877F2),
                                onTap: () => _launch(facebook),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 48),

                      // WhatsApp Direct CTA Card
                      GlassCard(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              const Text('💬', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 16),
                              const Text(
                                'Chat on WhatsApp',
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'For pass inquiries, event questions, or any help — our team is active on WhatsApp.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.chat_bubble, size: 18),
                                label: const Text('Start a Conversation', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                onPressed: () => _launchWhatsApp(whatsapp),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color accentColor;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
