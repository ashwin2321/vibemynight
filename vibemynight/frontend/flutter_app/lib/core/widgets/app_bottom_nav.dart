import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Showmates / District style floating bottom navigation bar for mobile devices.
/// Appears when screen width < 768px.
class AppBottomNav extends StatelessWidget {
  final String currentRoute;

  const AppBottomNav({
    super.key,
    required this.currentRoute,
  });

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/917041615131?text=Hi%20VibeMyNight!%20I%20want%20to%20inquire%20about%20event%20passes%20and%20VIP%20tables.',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    if (!isMobile) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xE60D0B18),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: currentRoute == '/',
                onTap: () {
                  if (currentRoute != '/') context.go('/');
                },
              ),
              _NavItem(
                icon: Icons.confirmation_number_rounded,
                label: 'Events',
                isSelected: currentRoute == '/events',
                onTap: () {
                  if (currentRoute != '/events') context.go('/events');
                },
              ),
              // Center WhatsApp VIP Passes Floating Button
              GestureDetector(
                onTap: _openWhatsApp,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withValues(alpha: 0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat, color: Colors.white, size: 16),
                      SizedBox(width: 5),
                      Text(
                        'VIP Passes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.mic_external_on_rounded,
                label: 'Artists',
                isSelected: currentRoute == '/artists',
                onTap: () {
                  if (currentRoute != '/artists') context.go('/artists');
                },
              ),
              _NavItem(
                icon: Icons.info_outline_rounded,
                label: 'About',
                isSelected: currentRoute == '/about',
                onTap: () {
                  if (currentRoute != '/about') context.go('/about');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFFC084FC) : Colors.white60,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFFC084FC) : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
