import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/vmn_logo.dart';

/// Shared admin layout with aesthetic frosted glass styling:
/// - Fixed sidebar on wide (desktop/tablet) screens
/// - Frosted glass drawer on narrow (mobile) screens
/// - Glowing active route pills and top action icons.
class AdminShell extends ConsumerWidget {
  final String title;
  final String currentPath;
  final Widget body;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  const AdminShell({
    super.key,
    required this.title,
    required this.currentPath,
    required this.body,
    this.floatingActionButton,
    this.actions,
  });

  static const _navItems = [
    (label: 'Dashboard', route: '/admin/dashboard', icon: Icons.dashboard_rounded),
    (label: 'Events', route: '/admin/events', icon: Icons.celebration_rounded),
    (label: 'Artists', route: '/admin/artists', icon: Icons.mic_external_on_rounded),
    (label: 'Pass Catalog & Prices', route: '/admin/pass-templates', icon: Icons.confirmation_number_rounded),
    (label: 'Facilities', route: '/admin/facilities', icon: Icons.stars_rounded),
    (label: 'Inquiries', route: '/admin/inquiries', icon: Icons.mark_email_unread_rounded),
    (label: 'Billing & Invoices', route: '/admin/billing', icon: Icons.receipt_long_rounded),
    (label: 'Settings', route: '/admin/settings', icon: Icons.settings_suggest_rounded),
  ];

  bool _isWide(BuildContext context) => MediaQuery.of(context).size.width >= 900;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = _isWide(context);

    final scaffold = Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xF20F0B1E),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.neonPurple.withValues(alpha: 0.15),
            height: 1,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        actions: [
          ...?actions,
          IconButton(
            tooltip: 'View Live Public Site',
            icon: const Icon(Icons.open_in_new_rounded, color: AppColors.neonPurple, size: 20),
            onPressed: () => context.push('/'),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 20),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/admin/login');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: wide ? null : Drawer(
        backgroundColor: AppColors.surface,
        child: _NavList(currentPath: currentPath),
      ),
      floatingActionButton: floatingActionButton,
      body: body,
    );

    if (!wide) return scaffold;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          SizedBox(
            width: 270,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F0B1E),
                border: Border(
                  right: BorderSide(
                    color: AppColors.neonPurple.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
              ),
              child: _NavList(currentPath: currentPath),
            ),
          ),
          Expanded(child: scaffold),
        ],
      ),
    );
  }
}

class _NavList extends StatelessWidget {
  final String currentPath;

  const _NavList({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: VmnLogo(size: 34, fontSize: 19),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.neonPurple.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.neonPurple,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ADMIN CONSOLE',
                style: TextStyle(
                  color: AppColors.neonPurple,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...AdminShell._navItems.map((item) {
          final selected = item.route == currentPath;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                    Navigator.of(context).pop();
                  }
                  context.go(item.route);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: selected
                        ? LinearGradient(
                            colors: [
                              AppColors.neonPurple.withValues(alpha: 0.22),
                              AppColors.neonPink.withValues(alpha: 0.12),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    border: selected
                        ? Border.all(color: AppColors.neonPurple.withValues(alpha: 0.4), width: 1)
                        : Border.all(color: Colors.transparent, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: selected ? AppColors.neonPink : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: selected ? Colors.white : AppColors.textSecondary,
                            fontSize: 13.5,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (selected)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.neonPink,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonPink.withValues(alpha: 0.8),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
