import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/data_providers.dart';
import '../theme/app_colors.dart';
import 'gradient_button.dart';

import 'vmn_logo.dart';

/// Top navigation bar matching Figma Navbar.tsx.
/// Adapts on desktop/tablet/mobile, provides links to Home, Events, About, Contact,
/// and includes WhatsApp & Get Your Pass action buttons.
class AppNavbar extends ConsumerWidget implements PreferredSizeWidget {
  final String currentRoute;

  const AppNavbar({super.key, this.currentRoute = '/'});

  @override
  Size get preferredSize => const Size.fromHeight(64);

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
    final whatsappNumber = settingsAsync.value?.whatsappNumber ?? '917041615131';
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand Logo
          InkWell(
            onTap: () => context.go('/'),
            borderRadius: BorderRadius.circular(8),
            child: const VmnLogo(size: 32),
          ),

          // Desktop Nav links
          if (isDesktop)
            Row(
              children: [
                _NavLink(label: 'Home', route: '/', active: currentRoute == '/'),
                const SizedBox(width: 24),
                _NavLink(label: 'Events', route: '/events', active: currentRoute.startsWith('/events')),
                const SizedBox(width: 24),
                _NavLink(label: 'About', route: '/about', active: currentRoute == '/about'),
                const SizedBox(width: 24),
                _NavLink(label: 'Contact', route: '/contact', active: currentRoute == '/contact'),
              ],
            ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDesktop) ...[
                TextButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 16),
                  label: const Text('WhatsApp', style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.w600)),
                  onPressed: () => _launchWhatsApp(whatsappNumber),
                ),
                const SizedBox(width: 8),
              ],
              GradientButton(
                label: 'Get Your Pass',
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onPressed: () => context.push('/events'),
              ),
              if (!isDesktop) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => _showMobileDrawer(context, whatsappNumber),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showMobileDrawer(BuildContext context, String whatsappNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.home_outlined, color: AppColors.neonPurple),
                  title: const Text('Home'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event_outlined, color: AppColors.neonPink),
                  title: const Text('Events'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/events');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.neonBlue),
                  title: const Text('About'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/about');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.contact_support_outlined, color: Colors.greenAccent),
                  title: const Text('Contact'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/contact');
                  },
                ),
                const Divider(color: AppColors.divider),
                ListTile(
                  leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
                  title: const Text('Chat on WhatsApp', style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _launchWhatsApp(whatsappNumber);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final String route;
  final bool active;

  const _NavLink({required this.label, required this.route, required this.active});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(route),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : AppColors.textSecondary,
          fontWeight: active ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
}
