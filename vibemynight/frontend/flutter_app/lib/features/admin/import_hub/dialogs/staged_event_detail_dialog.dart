import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/staged_event_models.dart';

class StagedEventDetailDialog extends StatefulWidget {
  final StagedEvent event;
  final VoidCallback onEdit;
  final VoidCallback? onImportSingle;

  const StagedEventDetailDialog({
    super.key,
    required this.event,
    required this.onEdit,
    this.onImportSingle,
  });

  @override
  State<StagedEventDetailDialog> createState() => _StagedEventDetailDialogState();
}

class _StagedEventDetailDialogState extends State<StagedEventDetailDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 850),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0B1E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.neonPurple.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.neonPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.neonPink,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Staged Event #${event.id}: ${event.displayTitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Source: ${event.source.toUpperCase()} (${event.sourceEventId}) • Status: ${event.status.displayName}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: const Color(0xFF140E24),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.neonPink,
                indicatorWeight: 3,
                labelColor: AppColors.neonPink,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                isScrollable: true,
                tabs: [
                  const Tab(icon: Icon(Icons.dashboard_rounded, size: 16), text: 'Overview'),
                  Tab(
                    icon: const Icon(Icons.confirmation_number_rounded, size: 16),
                    text: 'Passes (${event.passes.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.people_alt_rounded, size: 16),
                    text: 'Artists (${event.artists.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.calendar_month_rounded, size: 16),
                    text: 'Days (${event.days.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.fact_check_rounded, size: 16),
                    text: 'Rules & Perks (${event.facilities.length + event.rules.length})',
                  ),
                ],
              ),
            ),

            // Scrollable Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(event),
                  _buildPassesTab(event),
                  _buildArtistsTab(event),
                  _buildDaysTab(event),
                  _buildRulesTab(event),
                ],
              ),
            ),

            // Modal Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0B1E),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(
                  top: BorderSide(
                    color: AppColors.neonPurple.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.divider),
                    ),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Event'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.neonBlue,
                      side: const BorderSide(color: AppColors.neonBlue),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onEdit();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: OVERVIEW ---
  Widget _buildOverviewTab(StagedEvent event) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Poster & Banner
        if (event.posterUrl != null && event.posterUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 180,
              width: double.infinity,
              color: const Color(0xFF1E1730),
              child: Image.network(
                event.posterUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        const SizedBox(height: 14),

        // Duplicate Alert
        if (event.duplicateOf != null)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A00).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF7A00)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Duplicate Alert: Matches existing staged event #${event.duplicateOf}.',
                    style: const TextStyle(
                      color: Color(0xFFFF7A00),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // AI Title
        _buildSectionCard(
          title: 'Event Title',
          icon: Icons.title_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.enhancedTitle != null && event.enhancedTitle!.isNotEmpty) ...[
                const Text(
                  'AI-ENHANCED TITLE',
                  style: TextStyle(
                    color: AppColors.neonPink,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.enhancedTitle!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const Text(
                'ORIGINAL SOURCE TITLE',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                event.title,
                style: TextStyle(
                  color: (event.enhancedTitle != null && event.enhancedTitle!.isNotEmpty)
                      ? AppColors.textSecondary
                      : Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // WhatsApp Viral Teaser
        if (event.whatsAppTeaser != null && event.whatsAppTeaser!.isNotEmpty) ...[
          _buildSectionCard(
            title: 'WhatsApp Viral Teaser',
            icon: Icons.chat_bubble_rounded,
            headerAction: IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.neonPink),
              tooltip: 'Copy WhatsApp Teaser',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: event.whatsAppTeaser!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('WhatsApp teaser copied to clipboard!'),
                    duration: Duration(seconds: 2),
                    backgroundColor: AppColors.neonPurple,
                  ),
                );
              },
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2618),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Text(
                event.whatsAppTeaser!,
                style: const TextStyle(
                  color: Color(0xFF86EFAC),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Schedule & Location
        _buildSectionCard(
          title: 'Schedule & Location',
          icon: Icons.pin_drop_rounded,
          child: Column(
            children: [
              _buildInfoRow('Start Date', event.eventStartDate ?? 'TBA'),
              _buildInfoRow('End Date', event.eventEndDate ?? 'TBA'),
              _buildInfoRow('Time', '${event.startTime ?? ''} - ${event.endTime ?? ''}'),
              _buildInfoRow('Venue', event.venueName ?? 'TBA'),
              _buildInfoRow('Address', event.venueAddress ?? 'TBA'),
              _buildInfoRow('City & State', '${event.city ?? 'Gujarat'}, ${event.state ?? 'India'}'),
              _buildInfoRow('Starting Price', event.priceDisplay),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 2: PASSES & PRICING ---
  Widget _buildPassesTab(StagedEvent event) {
    final passes = event.passes;
    if (passes.isEmpty) {
      return const Center(
        child: Text(
          'No passes extracted from source data.\n(Admin can manually add passes via Edit).',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: passes.length,
      itemBuilder: (context, index) {
        final p = passes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161026),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      p.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.neonPink.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.neonPink.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      p.price != null ? '₹${p.price!.toStringAsFixed(0)}' : 'Price TBA',
                      style: const TextStyle(
                        color: AppColors.neonPink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF231A3B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      p.type,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (p.availableQuantity != null)
                    Text(
                      'Quantity: ${p.availableQuantity}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  if (p.maxPerCustomer != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• Max/User: ${p.maxPerCustomer}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ],
              ),
              if (p.benefits.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: p.benefits.map((b) => Chip(
                    label: Text(b, style: const TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: AppColors.neonPurple.withValues(alpha: 0.25),
                    padding: EdgeInsets.zero,
                  )).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // --- TAB 3: ARTISTS & LINEUP ---
  Widget _buildArtistsTab(StagedEvent event) {
    final artists = event.artists;
    if (artists.isEmpty) {
      return const Center(
        child: Text(
          'No artists extracted from source data.\n(Admin can add artists via Edit).',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final a = artists[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161026),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 60,
                  height: 60,
                  color: const Color(0xFF231A3B),
                  child: a.imageUrl != null && a.imageUrl!.isNotEmpty
                      ? Image.network(a.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppColors.textMuted))
                      : const Icon(Icons.person, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.name,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    if (a.role != null && a.role!.isNotEmpty)
                      Text(
                        a.role!,
                        style: const TextStyle(color: AppColors.neonPink, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    if (a.bio != null && a.bio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        a.bio!,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB 4: DAYS & SCHEDULE ---
  Widget _buildDaysTab(StagedEvent event) {
    final days = event.days;
    if (days.isEmpty) {
      return const Center(
        child: Text(
          'No specific day schedule breakdown extracted.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final d = days[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161026),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.neonPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'D${d.dayNumber}',
                  style: const TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.dayName ?? 'Day ${d.dayNumber}',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    if (d.date != null)
                      Text(
                        'Date: ${d.date} • ${d.startTime ?? ''}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB 5: RULES & FACILITIES ---
  Widget _buildRulesTab(StagedEvent event) {
    final facilities = event.facilities;
    final rules = event.rules;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionCard(
          title: 'Facilities & Amenities',
          icon: Icons.local_convenience_store_rounded,
          child: facilities.isNotEmpty
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: facilities.map((f) => Chip(
                    label: Text(f, style: const TextStyle(fontSize: 12, color: Colors.white)),
                    backgroundColor: const Color(0xFF231A3B),
                  )).toList(),
                )
              : const Text('No explicit facilities provided.', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Entry Rules & Guidelines',
          icon: Icons.gavel_rounded,
          child: rules.isNotEmpty
              ? Column(
                  children: rules.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: AppColors.neonPink, fontSize: 14)),
                        Expanded(child: Text(r, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5))),
                      ],
                    ),
                  )).toList(),
                )
              : const Text('Standard event policies apply.', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? headerAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161026),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.neonPurple),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (headerAction != null) ...[
                const Spacer(),
                headerAction,
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
