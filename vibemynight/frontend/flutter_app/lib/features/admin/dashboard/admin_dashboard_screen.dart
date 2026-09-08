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

/// Full Admin Dashboard matching Figma and requirement:
/// - Quick action shortcuts (+ Create Event, + Add Artist, Bulk Import, Public Preview, Site Settings)
/// - Live Metrics & Stat Cards (Total Events, Published, Artists, Total Inquiries, Confirmed, Passes Sold, Revenue)
/// - Recent Inquiries Feed with quick actions and status badges.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(adminEventsProvider);
    final artistsAsync = ref.watch(adminArtistsProvider);
    final inquiriesAsync = ref.watch(adminInquiriesProvider(const InquiryFilterParams()));

    return AdminShell(
      title: 'Dashboard',
      currentPath: '/admin/dashboard',
      actions: [
        IconButton(
          tooltip: 'Public Site Preview',
          icon: const Icon(Icons.open_in_new, color: AppColors.neonPurple),
          onPressed: () => context.push('/'),
        ),
        IconButton(
          tooltip: 'Refresh Metrics',
          icon: const Icon(Icons.refresh),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Quick Actions Bar
              _QuickActionsSection(),
              const SizedBox(height: 24),

              // 2. Metrics Grid
              const Text(
                'SYSTEM METRICS',
                style: TextStyle(
                  color: AppColors.neonPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              _MetricsSection(
                eventsAsync: eventsAsync,
                artistsAsync: artistsAsync,
                inquiriesAsync: inquiriesAsync,
              ),
              const SizedBox(height: 32),

              // 3. Recent Inquiries
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Inquiries',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('View All Inquiries'),
                    onPressed: () => context.push('/admin/inquiries'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              inquiriesAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: LoadingView())),
                error: (err, _) => ErrorView(message: err.toString()),
                data: (inquiries) => _RecentInquiriesCard(inquiries: inquiries.take(6).toList()),
              ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK ACTIONS',
            style: TextStyle(
              color: AppColors.neonPink,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('+ Create Event'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonPurple, foregroundColor: Colors.white),
                onPressed: () => context.push('/admin/events/new'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                label: const Text('+ Add Artist'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceGlass, foregroundColor: Colors.white),
                onPressed: () => context.push('/admin/artists/new'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: const Text('Excel / CSV Events'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceGlass, foregroundColor: AppColors.neonBlue),
                onPressed: () => context.push('/admin/events'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Generate Bill / WhatsApp'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceGlass, foregroundColor: AppColors.neonPink),
                onPressed: () => context.push('/admin/billing'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.mail_outline, size: 18),
                label: const Text('Manage Inquiries'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceGlass, foregroundColor: Colors.white),
                onPressed: () => context.push('/admin/inquiries'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Site Settings'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceGlass, foregroundColor: Colors.white),
                onPressed: () => context.push('/admin/settings'),
              ),
            ],
          ),
        ],
      ),
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
                icon: Icons.event,
                iconColor: AppColors.neonPurple,
              ),
            ),
            // 2. Published Events
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                label: 'Published Events',
                value: eventsAsync.maybeWhen(
                  data: (events) => '${events.where((e) => e.status == 'PUBLISHED').length}',
                  orElse: () => '0',
                ),
                icon: Icons.check_circle_outline,
                iconColor: Colors.greenAccent,
              ),
            ),
            // 3. Total Artists
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                label: 'Total Artists',
                value: artistsAsync.maybeWhen(data: (artists) => '${artists.length}', orElse: () => '0'),
                icon: Icons.mic_external_on,
                iconColor: AppColors.neonPink,
              ),
            ),
            // 4. Total Inquiries
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                label: 'Total Inquiries',
                value: inquiriesAsync.maybeWhen(data: (inquiries) => '${inquiries.length}', orElse: () => '0'),
                icon: Icons.mail,
                iconColor: AppColors.neonBlue,
              ),
            ),
            // 5. New Inquiries
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                label: 'New Pending Inquiries',
                value: inquiriesAsync.maybeWhen(
                  data: (inquiries) => '${inquiries.where((i) => i.status == 'NEW').length}',
                  orElse: () => '0',
                ),
                icon: Icons.mark_email_unread_outlined,
                iconColor: Colors.orangeAccent,
              ),
            ),
            // 6. Confirmed Inquiries
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                label: 'Confirmed Bookings',
                value: inquiriesAsync.maybeWhen(
                  data: (inquiries) => '${inquiries.where((i) => i.status == 'CONFIRMED').length}',
                  orElse: () => '0',
                ),
                icon: Icons.verified_outlined,
                iconColor: Colors.tealAccent,
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
                icon: Icons.confirmation_num_outlined,
                iconColor: const Color(0xFFC084FC),
              ),
            ),
            // 8. Pipeline Value
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                label: 'Pipeline Value',
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
                icon: Icons.currency_rupee,
                iconColor: Colors.amber,
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
        border: Border.all(color: AppColors.divider),
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
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
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
        border: Border.all(color: AppColors.divider),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: inquiries.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
        itemBuilder: (context, index) {
          final inq = inquiries[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: AppColors.neonPurple.withValues(alpha: 0.2),
              child: const Icon(Icons.person_outline, color: AppColors.neonPurple),
            ),
            title: Row(
              children: [
                Text(inq.customerName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: 8),
                Text('#${inq.inquiryNumber}', style: const TextStyle(color: AppColors.neonPurple, fontSize: 12)),
              ],
            ),
            subtitle: Text(
              '${inq.eventName} · ${inq.ticketCategoryName} (Qty: ${inq.quantity})',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${inq.estimatedTotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
                const SizedBox(width: 12),
                StatusBadge(status: inq.status),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white70),
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
