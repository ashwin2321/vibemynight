import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/staged_event_models.dart';

class StagedEventDetailDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 800),
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
                          'Staged Event #${event.id} Details',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Source: ${event.source.toUpperCase()} (${event.sourceEventId})',
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

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Poster & Title Banner
                  if (event.posterUrl != null && event.posterUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        color: const Color(0xFF1E1730),
                        child: Image.network(
                          event.posterUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Duplicate Alert
                  if (event.duplicateOf != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7A00).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFF7A00).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Color(0xFFFF7A00)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Duplicate Warning: Matches existing staged event #${event.duplicateOf}.',
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

                  // AI Enhanced Title Section
                  _buildSectionCard(
                    title: 'Event Title',
                    icon: Icons.title_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (event.enhancedTitle != null &&
                            event.enhancedTitle!.isNotEmpty) ...[
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
                              fontSize: 18,
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
                            color: (event.enhancedTitle != null &&
                                    event.enhancedTitle!.isNotEmpty)
                                ? AppColors.textSecondary
                                : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // WhatsApp Teaser Section with Copy Button
                  if (event.whatsAppTeaser != null &&
                      event.whatsAppTeaser!.isNotEmpty) ...[
                    _buildSectionCard(
                      title: 'WhatsApp Viral Teaser',
                      icon: Icons.chat_bubble_rounded,
                      headerAction: IconButton(
                        icon: const Icon(Icons.copy_rounded,
                            size: 16, color: AppColors.neonPink),
                        tooltip: 'Copy WhatsApp Teaser',
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: event.whatsAppTeaser!));
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
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
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
                    const SizedBox(height: 16),
                  ],

                  // Marketing Description
                  _buildSectionCard(
                    title: 'Description',
                    icon: Icons.description_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (event.catchyDescription != null &&
                            event.catchyDescription!.isNotEmpty) ...[
                          const Text(
                            'AI CATCHY MARKETING COPY',
                            style: TextStyle(
                              color: AppColors.neonBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.catchyDescription!,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13.5,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (event.description != null &&
                            event.description!.isNotEmpty) ...[
                          const Text(
                            'ORIGINAL DESCRIPTION',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.description!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Event Schedule & Venue Information
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
                        _buildInfoRow('Ticket Price', event.priceDisplay),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Highlights & Genre Badges
                  if (event.highlights.isNotEmpty || event.genreTags.isNotEmpty) ...[
                    _buildSectionCard(
                      title: 'Tags & Highlights',
                      icon: Icons.local_offer_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (event.genreTags.isNotEmpty) ...[
                            const Text(
                              'GENRES & VIBES',
                              style: TextStyle(
                                color: AppColors.neonPink,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: event.genreTags.map((tag) {
                                return Chip(
                                  label: Text(tag),
                                  labelStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  backgroundColor:
                                      AppColors.neonPurple.withValues(alpha: 0.3),
                                  side: BorderSide(
                                    color: AppColors.neonPurple.withValues(alpha: 0.6),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (event.highlights.isNotEmpty) ...[
                            const Text(
                              'EVENT HIGHLIGHTS',
                              style: TextStyle(
                                color: AppColors.neonBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...event.highlights.map((h) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ',
                                          style: TextStyle(
                                              color: AppColors.neonPink,
                                              fontSize: 14)),
                                      Expanded(
                                        child: Text(
                                          h,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Modal Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0B1E),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
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
                    label: const Text('Edit Staged Event'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.neonBlue,
                      side: const BorderSide(color: AppColors.neonBlue),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onEdit();
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
