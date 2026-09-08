import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/data_providers.dart';
import '../theme/app_colors.dart';
import 'vmn_logo.dart';

/// App footer component matching Figma Footer.tsx.
/// Integrates dynamic site settings from backend (WhatsApp number, email, phone, social links, footer text).
class AppFooter extends ConsumerWidget {
  const AppFooter({super.key});

  Future<void> _launchUrl(String url) async {
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
    final email = settings?.email ?? 'hello@vibemynight.com';
    final phone = settings?.phone ?? '+91 70416 15131';
    final instagram = settings?.instagramUrl;
    final facebook = settings?.facebookUrl;
    final footerText = settings?.footerText ?? '© 2026 VibeMyNight. All rights reserved.';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 700;
                  return Wrap(
                    spacing: 40,
                    runSpacing: 32,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      // Brand & description
                      SizedBox(
                        width: isWide ? 280 : double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const VmnLogo(size: 32),
                            const SizedBox(height: 12),
                            const Text(
                              'Discover the best events, artists and unforgettable nightlife experiences.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.chat_bubble, size: 14),
                              label: const Text('Chat on WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () => _launchWhatsApp(whatsapp),
                            ),
                          ],
                        ),
                      ),

                      // Quick Links
                      SizedBox(
                        width: isWide ? 160 : double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quick Links',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            _FooterLink(label: 'Home', onTap: () => context.go('/')),
                            _FooterLink(label: 'Events', onTap: () => context.go('/events')),
                            _FooterLink(label: 'About', onTap: () => context.go('/about')),
                            _FooterLink(label: 'Contact', onTap: () => context.go('/contact')),
                          ],
                        ),
                      ),

                      // Contact info
                      SizedBox(
                        width: isWide ? 180 : double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contact',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            _FooterLink(label: phone, onTap: () => _launchUrl('tel:$phone')),
                            _FooterLink(label: email, onTap: () => _launchUrl('mailto:$email')),
                          ],
                        ),
                      ),

                      // Social links & admin portal
                      SizedBox(
                        width: isWide ? 160 : double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Follow Us',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (instagram != null && instagram.isNotEmpty) ...[
                                  _SocialCircle(icon: Icons.camera_alt, color: const Color(0xFFE1306C), onTap: () => _launchUrl(instagram)),
                                  const SizedBox(width: 8),
                                ],
                                if (facebook != null && facebook.isNotEmpty) ...[
                                  _SocialCircle(icon: Icons.facebook, color: const Color(0xFF1877F2), onTap: () => _launchUrl(facebook)),
                                  const SizedBox(width: 8),
                                ],
                                _SocialCircle(icon: Icons.chat, color: const Color(0xFF25D366), onTap: () => _launchWhatsApp(whatsapp)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 36),
              Divider(color: Colors.white.withValues(alpha: 0.08)),
              const SizedBox(height: 16),
              Text(
                footerText,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ),
    );
  }
}

class _SocialCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialCircle({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(child: Icon(icon, size: 16, color: Colors.white)),
      ),
    );
  }
}
