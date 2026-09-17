import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/providers/data_providers.dart';
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
  final Set<int> _selectedIds = {};
  bool _isBulkOperating = false;

  static const _statusTabs = ['All', 'PUBLISHED', 'DRAFT', 'COMPLETED', 'CANCELLED', 'UNPUBLISHED'];

  Future<void> _toggleHero(BuildContext context, WidgetRef ref, EventSummary event, bool value) async {
    try {
      await ref.read(adminServiceProvider).toggleHero(event.id, value);
      ref.invalidate(adminEventsProvider);
      ref.invalidate(publishedEventsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? '✨ "${event.name}" added to Hero Carousel!' : 'Removed "${event.name}" from Hero Carousel'),
            backgroundColor: AppColors.neonPurple,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _changeStatus(BuildContext context, WidgetRef ref, EventSummary event, String status) async {
    try {
      await ref.read(adminServiceProvider).changeEventStatus(event.id, status);
      ref.invalidate(adminEventsProvider);
      ref.invalidate(publishedEventsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _bulkChangeStatus(String targetStatus, List<EventSummary> allEvents) async {
    final selectedEvents = allEvents.where((e) => _selectedIds.contains(e.id)).toList();
    if (selectedEvents.isEmpty) return;

    setState(() => _isBulkOperating = true);
    int successCount = 0;
    try {
      for (final event in selectedEvents) {
        try {
          await ref.read(adminServiceProvider).changeEventStatus(event.id, targetStatus);
          successCount++;
        } catch (err) {
          debugPrint('Error updating event ${event.id}: $err');
        }
      }
      ref.invalidate(adminEventsProvider);
      ref.invalidate(publishedEventsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚡ Updated $successCount events to $targetStatus!'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() => _selectedIds.clear());
      }
    } finally {
      if (mounted) setState(() => _isBulkOperating = false);
    }
  }

  Future<void> _bulkDelete(List<EventSummary> allEvents) async {
    final selectedEvents = allEvents.where((e) => _selectedIds.contains(e.id)).toList();
    if (selectedEvents.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${selectedEvents.length} Events?'),
        content: Text(
          'Are you sure you want to permanently delete ${selectedEvents.length} selected events and all their days/passes? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('Delete ${selectedEvents.length} Events'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isBulkOperating = true);
    int deletedCount = 0;
    try {
      for (final event in selectedEvents) {
        try {
          await ref.read(adminServiceProvider).deleteEvent(event.id);
          deletedCount++;
        } catch (err) {
          debugPrint('Error deleting event ${event.id}: $err');
        }
      }
      ref.invalidate(adminEventsProvider);
      ref.invalidate(publishedEventsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ Successfully deleted $deletedCount events!'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() => _selectedIds.clear());
      }
    } finally {
      if (mounted) setState(() => _isBulkOperating = false);
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
      ref.invalidate(publishedEventsProvider);
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
                final uri = Uri.parse('https://api.whatsapp.com/send?text=$text');
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
          icon: const Icon(Icons.auto_awesome, size: 16),
          label: const Text('Import Event (Excel)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.neonBlue,
            side: const BorderSide(color: AppColors.neonBlue),
          ),
          onPressed: () => context.push('/admin/events/import'),
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

          // Bulk Action Bar (Visible when 1+ events are selected)
          if (_selectedIds.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.neonPurple.withValues(alpha: 0.25),
                    AppColors.neonPink.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.6), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.neonPurple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selectedIds.length} Selected',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  if (_isBulkOperating)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  else ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Publish Selected'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        final events = eventsAsync.valueOrNull ?? [];
                        _bulkChangeStatus('PUBLISHED', events);
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.pause_circle_outline, size: 16),
                      label: const Text('Unpublish / Draft'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        final events = eventsAsync.valueOrNull ?? [];
                        _bulkChangeStatus('UNPUBLISHED', events);
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                      label: const Text('Delete Selected'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        final events = eventsAsync.valueOrNull ?? [];
                        _bulkDelete(events);
                      },
                    ),
                  ],
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Clear Selection'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                    onPressed: () => setState(() => _selectedIds.clear()),
                  ),
                ],
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
                        showCheckboxColumn: true,
                        headingRowColor: WidgetStateProperty.all(AppColors.surfaceGlass),
                        dataRowMinHeight: 64,
                        dataRowMaxHeight: 72,
                        columns: const [
                          DataColumn(label: Text('Event', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Hero Banner', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Dates', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Days', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Location', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filtered.map((event) {
                          final isSelected = _selectedIds.contains(event.id);
                          return DataRow(
                            selected: isSelected,
                            onSelectChanged: (selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedIds.add(event.id);
                                } else {
                                  _selectedIds.remove(event.id);
                                }
                              });
                            },
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
                              DataCell(
                                Tooltip(
                                  message: event.showInHero ? 'Showing in Hero Carousel (Click to disable)' : 'Click to show in Hero Carousel',
                                  child: Transform.scale(
                                    scale: 0.8,
                                    child: Switch(
                                      value: event.showInHero,
                                      activeThumbColor: AppColors.neonPurple,
                                      activeTrackColor: AppColors.neonPurple.withValues(alpha: 0.5),
                                      onChanged: (val) => _toggleHero(context, ref, event, val),
                                    ),
                                  ),
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


