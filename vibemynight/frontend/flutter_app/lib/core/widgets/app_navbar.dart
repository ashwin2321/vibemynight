import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/data_providers.dart';
import '../theme/app_colors.dart';
import 'gradient_button.dart';
import 'vmn_logo.dart';

/// Top navigation bar with luxury frosted glassmorphism, glowing links & quick WhatsApp action.
class AppNavbar extends ConsumerWidget implements PreferredSizeWidget {
  final String currentRoute;

  const AppNavbar({super.key, this.currentRoute = '/'});

  @override
  Size get preferredSize => const Size.fromHeight(68);

  Future<void> _launchWhatsApp(String? number) async {
    String clean = (number ?? '917041615131').replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 10) clean = '91$clean';
    final uri = Uri.parse('https://api.whatsapp.com/send?phone=$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final whatsappNumber = settingsAsync.value?.whatsappNumber ?? '917041615131';
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 820;

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xF5080712),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Brand Logo
              InkWell(
                onTap: () => context.go('/'),
                borderRadius: BorderRadius.circular(10),
                child: const VmnLogo(size: 38),
              ),

              // Desktop Nav links
              if (isDesktop)
                Row(
                  children: [
                    _NavLink(label: 'Home', route: '/', active: currentRoute == '/'),
                    const SizedBox(width: 8),
                    _NavLink(label: 'Events', route: '/events', active: currentRoute.startsWith('/events')),
                    const SizedBox(width: 8),
                    _NavLink(label: 'Artists', route: '/artists', active: currentRoute.startsWith('/artists')),
                    const SizedBox(width: 8),
                    _NavLink(label: 'About', route: '/about', active: currentRoute == '/about'),
                    const SizedBox(width: 8),
                    _NavLink(label: 'Contact', route: '/contact', active: currentRoute == '/contact'),
                  ],
                ),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDesktop) ...[
                    InkWell(
                      onTap: () => _launchWhatsApp(whatsappNumber),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF25D366).withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 15),
                            SizedBox(width: 6),
                            Text(
                              'WhatsApp',
                              style: TextStyle(
                                color: Color(0xFF25D366),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  GradientButton(
                    label: 'Get Your Pass',
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
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
      backgroundColor: const Color(0xFF0F0E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.home_outlined, color: AppColors.neonPurple),
                  title: const Text('Home', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event_outlined, color: AppColors.neonPink),
                  title: const Text('Events', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/events');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.mic_external_on_outlined, color: Color(0xFF60A5FA)),
                  title: const Text('Artists', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/artists');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.neonBlue),
                  title: const Text('About', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/about');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.contact_support_outlined, color: Colors.greenAccent),
                  title: const Text('Contact', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/contact');
                  },
                ),
                const Divider(color: Color(0x1FFFFFFF), height: 28),
                ListTile(
                  leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
                  title: const Text(
                    'Chat on WhatsApp',
                    style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.bold),
                  ),
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

class _NavLink extends StatefulWidget {
  final String label;
  final String route;
  final bool active;

  const _NavLink({required this.label, required this.route, required this.active});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: () => context.go(widget.route),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.active
                ? const Color(0xFFA855F7).withValues(alpha: 0.16)
                : (_isHovered ? Colors.white.withValues(alpha: 0.06) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.active
                  ? const Color(0xFFA855F7).withValues(alpha: 0.4)
                  : (_isHovered ? Colors.white.withValues(alpha: 0.12) : Colors.transparent),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.active
                  ? const Color(0xFFE9D5FF)
                  : (_isHovered ? Colors.white : AppColors.textSecondary),
              fontWeight: widget.active ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
