import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../models/artist.dart';
import '../../../models/event_summary.dart';
import '../../../models/inquiry_admin_summary.dart';
import '../widgets/admin_shell.dart';
import '../widgets/status_badge.dart';

/// Full Admin Dashboard with Luxury Glassmorphic Styling:
/// - Quick action shortcuts (+ Create Event, + Add Artist, Inquiries, Settings)
/// - Live System Metric Cards with subtle neon glow & gradient backdrops
/// - Recent Inquiries Feed with customer avatars and status chips.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(adminEventsProvider);
    final artistsAsync = ref.watch(adminArtistsProvider);
    final inquiriesAsync = ref.watch(adminInquiriesProvider(const InquiryFilterParams()));

    return AdminShell(
      title: 'Admin Dashboard',
      currentPath: '/admin/dashboard',
      actions: [
        IconButton(
          tooltip: 'Refresh Metrics',
          icon: const Icon(Icons.refresh_rounded, size: 20),
          onPressed: () {
            ref.invalidate(adminEventsProvider);
            ref.invalidate(adminArtistsProvider);
            ref.invalidate(adminInquiriesProvider(const InquiryFilterParams()));
          },
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminEventsProvider);
          ref.invalidate(adminArtistsProvider);
          ref.invalidate(adminInquiriesProvider(const InquiryFilterParams()));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Quick Actions Bar
              _QuickActionsSection(),
              const SizedBox(height: 28),

              // 2. Metrics Grid
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.neonPurple,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'PLATFORM OVERVIEW & METRICS',
                    style: TextStyle(
                      color: AppColors.neonPurple,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _MetricsSection(
                eventsAsync: eventsAsync,
                artistsAsync: artistsAsync,
                inquiriesAsync: inquiriesAsync,
              ),
              const SizedBox(height: 36),

              // 3. Recent Inquiries
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.neonPink,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Recent Pass Inquiries',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.neonPink,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('View All Inquiries', style: TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: () => context.push('/admin/inquiries'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              inquiriesAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: LoadingView())),
                error: (err, _) => ErrorView(message: err.toString()),
                data: (inquiries) => _RecentInquiriesCard(inquiries: inquiries.take(6).toList()),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK SHORTCUTS',
            style: TextStyle(
              color: AppColors.neonPink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ActionButton(
                icon: Icons.add_circle_outline_rounded,
                label: '+ Create Event',
                isPrimary: true,
                onTap: () => context.push('/admin/events/new'),
              ),
              _ActionButton(
                icon: Icons.person_add_alt_1_rounded,
                label: '+ Add Artist',
                onTap: () => context.push('/admin/artists/new'),
              ),
              _ActionButton(
                icon: Icons.receipt_long_rounded,
                label: 'Billing & Invoices',
                color: AppColors.neonPink,
                onTap: () => context.push('/admin/billing'),
              ),
              _ActionButton(
                icon: Icons.mark_email_unread_rounded,
                label: 'Manage Inquiries',
                color: AppColors.neonBlue,
                onTap: () => context.push('/admin/inquiries'),
              ),
              _ActionButton(
                icon: Icons.settings_rounded,
                label: 'Site Settings',
                onTap: () => context.push('/admin/settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 4,
          shadowColor: AppColors.neonPurple.withValues(alpha: 0.5),
        ),
        onPressed: onTap,
      );
    }

    final accent = color ?? Colors.white;
    return OutlinedButton.icon(
      icon: Icon(icon, size: 17, color: accent),
      label: Text(label, style: TextStyle(color: accent, fontWeight: FontWeight.w600, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        side: BorderSide(color: (color ?? AppColors.neonPurple).withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onTap,
    );
  }
}

class _MetricsSection extends StatelessWidget {
  final AsyncValue<List<EventSummary>> eventsAsync;
  final AsyncValue<List<Artist>> artistsAsync;
  final AsyncValue<List<InquiryAdminSummary>> inquiriesAsync;

  const _MetricsSection({
    required this.eventsAsync,
    required this.artistsAsync,
    required this.inquiriesAsync,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1000;
    final isTablet = size.width >= 600 && size.width < 1000;
    final cols = isDesktop ? 4 : (isTablet ? 2 : 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (cols - 1) * 14) / cols;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            // 1. Total Events
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                label: 'Total Events',
                value: eventsAsync.maybeWhen(data: (events) => '${events.length}', orElse: () => '0'),
                icon: Icons.celebration_rounded,
                iconColor: AppColors.neonPurple,
              ),
            ),
            // 2. Published Events
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                label: 'Live Published Events',
                value: eventsAsync.maybeWhen(
                  data: (events) => '${events.where((e) => e.status == 'PUBLISHED').length}',
                  orElse: () => '0',
                ),
                icon: Icons.verified_rounded,
                iconColor: const Color(0xFF34D399),
              ),
            ),
            // 3. Total Artists
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                label: 'Active Artists',
                value: artistsAsync.maybeWhen(data: (artists) => '${artists.length}', orElse: () => '0'),
                icon: Icons.mic_external_on_rounded,
                iconColor: AppColors.neonPink,
              ),
            ),
            // 4. Total Inquiries
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                label: 'Total Inquiries',
                value: inquiriesAsync.maybeWhen(data: (inquiries) => '${inquiries.length}', orElse: () => '0'),
                icon: Icons.mark_email_read_rounded,
                iconColor: AppColors.neonBlue,
              ),
            ),
            // 5. New Pending Inquiries
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                label: 'New Pending Leads',
                value: inquiriesAsync.maybeWhen(
                  data: (inquiries) => '${inquiries.where((i) => i.status == 'NEW').length}',
                  orElse: () => '0',
                ),
                icon: Icons.pending_actions_rounded,
                iconColor: const Color(0xFFFB923C),
              ),
            ),
            // 6. Confirmed Bookings
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                label: 'Confirmed Bookings',
                value: inquiriesAsync.maybeWhen(
                  data: (inquiries) => '${inquiries.where((i) => i.status == 'CONFIRMED' || i.status == 'COMPLETED').length}',
                  orElse: () => '0',
                ),
                icon: Icons.task_alt_rounded,
                iconColor: const Color(0xFF2DD4BF),
              ),
            ),
            // 7. Passes Requested
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                label: 'Passes Requested',
                value: inquiriesAsync.maybeWhen(
                  data: (inquiries) {
                    int total = 0;
                    for (final i in inquiries) {
                      total += i.quantity;
                    }
                    return '$total';
                  },
                  orElse: () => '0',
                ),
                icon: Icons.confirmation_num_rounded,
                iconColor: const Color(0xFFC084FC),
              ),
            ),
            // 8. Pipeline Total
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                label: 'Pipeline Booking Value',
                value: inquiriesAsync.maybeWhen(
                  data: (inquiries) {
                    double total = 0.0;
                    for (final i in inquiries) {
                      total += i.estimatedTotal;
                    }
                    return '₹${total.toStringAsFixed(0)}';
                  },
                  orElse: () => '₹0',
                ),
                icon: Icons.currency_rupee_rounded,
                iconColor: const Color(0xFFFBBF24),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ],
      ),
    );
  }
}

class _RecentInquiriesCard extends StatelessWidget {
  final List<InquiryAdminSummary> inquiries;

  const _RecentInquiriesCard({required this.inquiries});

  @override
  Widget build(BuildContext context) {
    if (inquiries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Center(
          child: Text(
            'No inquiries received yet. When customers book passes, they will appear here.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.2)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: inquiries.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
        itemBuilder: (context, index) {
          final inq = inquiries[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.neonPurple.withValues(alpha: 0.18),
              child: const Icon(Icons.person_rounded, color: AppColors.neonPurple, size: 20),
            ),
            title: Row(
              children: [
                Text(inq.customerName, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGlass,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '#${inq.inquiryNumber}',
                    style: const TextStyle(color: AppColors.neonPurple, fontSize: 10.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${inq.eventName} · ${inq.ticketCategoryName} (Qty: ${inq.quantity})',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${inq.estimatedTotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14),
                ),
                const SizedBox(width: 14),
                StatusBadge(status: inq.status),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 20),
                  onPressed: () => context.push('/admin/inquiries/${inq.id}'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
