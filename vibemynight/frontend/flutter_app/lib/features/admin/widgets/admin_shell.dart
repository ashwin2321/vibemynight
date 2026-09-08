import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/vmn_logo.dart';

/// Shared admin layout: a fixed sidebar on wide (desktop/tablet) screens,
/// a Drawer on narrow (mobile) screens - per the spec's "Desktop: Sidebar,
/// Mobile: Drawer" responsive requirement. Every admin screen wraps its body
/// in this so navigation is consistent everywhere.
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
    (label: 'Dashboard', route: '/admin/dashboard', icon: Icons.dashboard_outlined),
    (label: 'Events', route: '/admin/events', icon: Icons.event_outlined),
    (label: 'Artists', route: '/admin/artists', icon: Icons.mic_external_on_outlined),
    (label: 'Facilities', route: '/admin/facilities', icon: Icons.local_parking_outlined),
    (label: 'Inquiries', route: '/admin/inquiries', icon: Icons.mail_outline),
    (label: 'Billing & Invoices', route: '/admin/billing', icon: Icons.receipt_long_outlined),
    (label: 'Settings', route: '/admin/settings', icon: Icons.settings_outlined),
  ];

  bool _isWide(BuildContext context) => MediaQuery.of(context).size.width >= 900;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = _isWide(context);

    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...?actions,
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/admin/login');
            },
          ),
        ],
      ),
      drawer: wide ? null : Drawer(child: _NavList(currentPath: currentPath)),
      floatingActionButton: floatingActionButton,
      body: body,
    );

    if (!wide) return scaffold;

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 260,
            child: Container(
              color: AppColors.surface,
              child: _NavList(currentPath: currentPath),
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.divider),
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
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: VmnLogo(size: 32, fontSize: 18),
        ),
        const SizedBox(height: 12),
        ...AdminShell._navItems.map((item) {
          final selected = item.route == currentPath;
          return ListTile(
            selected: selected,
            selectedTileColor: AppColors.surfaceGlass,
            leading: Icon(item.icon, color: selected ? AppColors.neonPink : AppColors.textSecondary),
            title: Text(item.label, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary)),
            onTap: () {
              if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                Navigator.of(context).pop();
              }
              context.go(item.route);
            },
          );
        }),
      ],
    );
  }
}
