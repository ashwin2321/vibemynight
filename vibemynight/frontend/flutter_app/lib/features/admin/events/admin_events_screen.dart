import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/network_image_box.dart';
import '../../../models/event_summary.dart';
import '../widgets/admin_shell.dart';
import '../widgets/status_badge.dart';
import 'admin_event_content_dialog.dart';

/// Admin event list (GET /admin/events) with search, status tabs,
/// publish/unpublish/complete/cancel actions, edit, manage days,
/// manage content/facilities, bulk Excel/CSV import, share link, and delete.
class AdminEventsScreen extends ConsumerStatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  ConsumerState<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends ConsumerState<AdminEventsScreen> {
  String _search = '';
  String _statusFilter = 'All';

  static const _statusTabs = ['All', 'PUBLISHED', 'DRAFT', 'COMPLETED', 'CANCELLED', 'UNPUBLISHED'];

  Future<void> _changeStatus(BuildContext context, WidgetRef ref, EventSummary event, String status) async {
    try {
      await ref.read(adminServiceProvider).changeEventStatus(event.id, status);
      ref.invalidate(adminEventsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, EventSummary event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text('This permanently deletes "${event.name}" and all its days/passes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminServiceProvider).deleteEvent(event.id);
      ref.invalidate(adminEventsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _shareEventLink(BuildContext context, EventSummary event) {
    final link = 'https://vibemynight.com/events/${event.slug.isNotEmpty ? event.slug : event.id}';
    Clipboard.setData(ClipboardData(text: link));

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share Event: ${event.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surfaceGlass, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Expanded(child: Text(link, style: const TextStyle(color: AppColors.neonPurple, fontSize: 13))),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event link copied to clipboard!')));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
              ),
              icon: const Icon(Icons.chat),
              label: const Text('Share on WhatsApp'),
              onPressed: () async {
                Navigator.pop(ctx);
                final text = Uri.encodeComponent('Check out ${event.name} on VibeMyNight!\nBook passes now: $link');
                final uri = Uri.parse('https://wa.me/?text=$text');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openBulkImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _BulkImportEventsDialog(onImportDone: () => ref.invalidate(adminEventsProvider)),
    );
  }

  void _exportEventsCsv(List<EventSummary> events) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Name,Slug,StartDate,EndDate,Days,City,Location,StartingPrice,Featured,Status');
    for (final e in events) {
      buffer.writeln('${e.id},"${e.name}","${e.slug}",${e.startDate},${e.endDate},${e.dayCount},"${e.city ?? ''}","${e.location ?? ''}",${e.startingPrice ?? 0},${e.featured},${e.status}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exported events to CSV and copied to clipboard!')),
    );
  }

  void _openContentManagement(BuildContext context, EventSummary event) {
    showDialog(
      context: context,
      builder: (context) => AdminEventContentDialog(
        eventId: event.id,
        eventName: event.name,
      ),
    );
  }

  List<EventSummary> _filterEvents(List<EventSummary> events) {
    return events.where((e) {
      final matchesSearch = _search.isEmpty ||
          e.name.toLowerCase().contains(_search.toLowerCase()) ||
          (e.location?.toLowerCase().contains(_search.toLowerCase()) ?? false) ||
          (e.city?.toLowerCase().contains(_search.toLowerCase()) ?? false);

      final matchesStatus = _statusFilter == 'All' || e.status.toUpperCase() == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(adminEventsProvider);

    return AdminShell(
      title: 'Events',
      currentPath: '/admin/events',
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.upload_file, size: 16),
          label: const Text('Excel / CSV Import'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.neonPurple,
            side: const BorderSide(color: AppColors.neonPurple),
          ),
          onPressed: () => _openBulkImportDialog(context),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Event'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () => context.push('/admin/events/new'),
          ),
        ),
      ],
      body: Column(
        children: [
          // Search + Filters bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _search = v),
                          decoration: InputDecoration(
                            hintText: 'Search events by name, location or city…',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            fillColor: AppColors.surfaceGlass,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.divider),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      eventsAsync.maybeWhen(
                        data: (events) => IconButton(
                          tooltip: 'Export CSV to Clipboard',
                          icon: const Icon(Icons.file_download_outlined, color: Colors.white70),
                          onPressed: () => _exportEventsCsv(events),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statusTabs.map((tab) {
                        final selected = _statusFilter == tab;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(tab == 'All' ? 'All' : tab.toLowerCase()),
                            selected: selected,
                            selectedColor: AppColors.neonPurple,
                            backgroundColor: AppColors.surfaceGlass,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              color: selected ? Colors.white : AppColors.textSecondary,
                            ),
                            onSelected: (_) => setState(() => _statusFilter = tab),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Events Table
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: LoadingView()),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(adminEventsProvider),
              ),
              data: (events) {
                final filtered = _filterEvents(events);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No events found. Click "+ Create Event" or "Excel / CSV Import" to add one.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppColors.surfaceGlass),
                        dataRowMinHeight: 64,
                        dataRowMaxHeight: 72,
                        columns: const [
                          DataColumn(label: Text('Event', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Dates', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Days', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Location', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filtered.map((event) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    NetworkImageBox(
                                      url: event.thumbnail ?? event.mainImage,
                                      height: 48,
                                      width: 48,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(event.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        if (event.featured)
                                          const Text('★ Featured', style: TextStyle(color: Colors.amber, fontSize: 10)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text('${event.startDate} → ${event.endDate}', style: const TextStyle(fontSize: 12))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.neonPurple.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${event.dayCount} ${event.dayCount == 1 ? "Day" : "Days"}',
                                    style: const TextStyle(color: AppColors.neonPink, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              DataCell(Text(event.city ?? event.location ?? '-', style: const TextStyle(fontSize: 12))),
                              DataCell(StatusBadge(status: event.status)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.share_outlined, size: 20),
                                      tooltip: 'Share / Copy Public Link',
                                      color: const Color(0xFF25D366),
                                      onPressed: () => _shareEventLink(context, event),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.calendar_month_outlined, size: 20),
                                      tooltip: 'Manage Days & Passes',
                                      color: AppColors.neonBlue,
                                      onPressed: () => context.push('/admin/events/${event.id}/days'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.layers_outlined, size: 20),
                                      tooltip: 'Content & Facilities',
                                      color: AppColors.neonPurple,
                                      onPressed: () => _openContentManagement(context, event),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                      tooltip: 'Edit Event',
                                      onPressed: () => context.push('/admin/events/${event.id}/edit'),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: 'Change Status',
                                      onSelected: (status) => _changeStatus(context, ref, event, status),
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(value: 'PUBLISHED', child: Text('Publish')),
                                        PopupMenuItem(value: 'UNPUBLISHED', child: Text('Unpublish')),
                                        PopupMenuItem(value: 'COMPLETED', child: Text('Mark completed')),
                                        PopupMenuItem(value: 'CANCELLED', child: Text('Mark cancelled')),
                                      ],
                                      icon: const Icon(Icons.more_vert, size: 20),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20),
                                      tooltip: 'Delete Event',
                                      color: AppColors.error,
                                      onPressed: () => _delete(context, ref, event),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Bulk Import Dialog allowing admin to paste CSV/Excel or JSON lines to create multiple events in one go
class _BulkImportEventsDialog extends ConsumerStatefulWidget {
  final VoidCallback onImportDone;

  const _BulkImportEventsDialog({required this.onImportDone});

  @override
  ConsumerState<_BulkImportEventsDialog> createState() => _BulkImportEventsDialogState();
}

class _BulkImportEventsDialogState extends ConsumerState<_BulkImportEventsDialog> {
  final _textController = TextEditingController(
    text: 'Name, Slug, StartDate, EndDate, City, Location, StartingPrice\n'
        'Navratri Nights 2026, navratri-nights-2026, 2026-10-15, 2026-10-19, Ahmedabad, Grand Arena, 499\n'
        'Celebrity Night Live, celebrity-night-live, 2026-10-22, 2026-10-22, Mumbai, Sky Lounge, 999\n'
        'DJ Night Goa Edition, dj-night-goa-edition, 2026-11-01, 2026-11-01, Goa, Beach Club, 799\n'
        'Garba Festival Night, garba-festival-night, 2026-10-16, 2026-10-18, Surat, Exhibition Ground, 399',
  );
  bool _importing = false;
  String? _statusMessage;

  Future<void> _processImport() async {
    setState(() {
      _importing = true;
      _statusMessage = 'Importing events...';
    });

    try {
      final lines = _textController.text.trim().split('\n');
      int count = 0;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty || line.toLowerCase().startsWith('name,')) continue; // skip header
        final parts = line.split(',').map((p) => p.trim()).toList();
        if (parts.length >= 4) {
          final name = parts[0];
          final slug = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
          final start = parts.length > 2 ? parts[2] : '2026-10-15';
          final end = parts.length > 3 ? parts[3] : start;
          final city = parts.length > 4 ? parts[4] : 'Ahmedabad';
          final location = parts.length > 5 ? parts[5] : 'Grand Arena';
          final price = parts.length > 6 ? double.tryParse(parts[6]) : 499.0;

          await ref.read(adminServiceProvider).createEvent({
            'name': name,
            'slug': slug,
            'startDate': start,
            'endDate': end,
            'city': city,
            'location': location,
            'startingPrice': price,
            'status': 'PUBLISHED',
            'featured': true,
          });
          count++;
        }
      }

      widget.onImportDone();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported $count events!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _importing = false;
          _statusMessage = 'Error during import: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Row(
        children: [
          Icon(Icons.upload_file, color: AppColors.neonPurple),
          SizedBox(width: 8),
          Text('Bulk Excel / CSV Event Import'),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste CSV or Excel rows (comma-separated):',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 6),
            const Text(
              'Format: Name, Slug, StartDate, EndDate, City, Location, StartingPrice',
              style: TextStyle(color: AppColors.neonPink, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              maxLines: 8,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                fillColor: AppColors.surfaceGlass,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 10),
              Text(_statusMessage!, style: const TextStyle(color: Colors.amber, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _importing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: _importing
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.flash_on, size: 16),
          label: Text(_importing ? 'Importing...' : 'Import Events Now'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonPurple),
          onPressed: _importing ? null : _processImport,
        ),
      ],
    );
  }
}
