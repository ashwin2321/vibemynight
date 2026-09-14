import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../models/event_import_models.dart';
import '../widgets/admin_shell.dart';
import '../widgets/status_badge.dart';

/// Admin Event Builder & Excel Import Screen
/// Allows admins to upload an Excel file containing the complete event structure (Event, Days, Passes, Artists, Facilities),
/// inspect the live preview with validation badges, and atomically create the entire event in one click.
class AdminEventImportScreen extends ConsumerStatefulWidget {
  const AdminEventImportScreen({super.key});

  @override
  ConsumerState<AdminEventImportScreen> createState() => _AdminEventImportScreenState();
}

class _AdminEventImportScreenState extends ConsumerState<AdminEventImportScreen> with SingleTickerProviderStateMixin {
  PlatformFile? _selectedFile;
  bool _isParsing = false;
  bool _isCreating = false;
  String? _errorMessage;
  EventImportPreview? _preview;
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

  Future<void> _downloadTemplate() async {
    try {
      final bytes = await ref.read(adminServiceProvider).downloadEventTemplate();
      if (bytes.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to download template')));
        return;
      }
      final base64Content = base64Encode(bytes);
      final uri = Uri.parse('data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64Content');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template download initiated. Check your downloads folder!')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading template: $e')));
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _errorMessage = null;
          _preview = null;
        });
        await _parseFile();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to select file: $e');
    }
  }

  Future<void> _parseFile() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) return;

    setState(() {
      _isParsing = true;
      _errorMessage = null;
    });

    try {
      final preview = await ref.read(adminServiceProvider).parseEventExcel(
            _selectedFile!.bytes!,
            _selectedFile!.name,
          );
      setState(() {
        _preview = preview;
        _isParsing = false;
      });
    } catch (e) {
      setState(() {
        _isParsing = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _confirmAndCreate() async {
    if (_preview == null || _preview!.hasBlockingErrors) return;

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final created = await ref.read(adminServiceProvider).confirmEventImport(_preview!);
      ref.invalidate(adminEventsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Event "${created.name}" created successfully with ${created.days.length} days!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/admin/events/${created.id}/days');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Event Import / Builder',
      currentPath: '/admin/events',
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text('Download Blank Template'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.neonBlue,
            side: const BorderSide(color: AppColors.neonBlue),
          ),
          onPressed: _downloadTemplate,
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Back to Events'),
          onPressed: () => context.go('/admin/events'),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceGlass,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.neonPurple.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.neonPurple, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bulk Event Builder (Excel .xlsx)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Create a complete multi-day event with all Days, Passes, Prices, Artists, and Facilities in seconds. Download our pre-formatted template, fill your details, and upload below.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Upload Box
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  InkWell(
                    onTap: _isParsing || _isCreating ? null : _pickFile,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedFile != null ? AppColors.neonPurple : AppColors.divider,
                          style: BorderStyle.solid,
                          width: _selectedFile != null ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedFile != null ? Icons.description_rounded : Icons.cloud_upload_outlined,
                            size: 48,
                            color: _selectedFile != null ? AppColors.neonPink : AppColors.neonPurple,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedFile != null ? _selectedFile!.name : 'Click or Drag & Drop Excel File Here (.xlsx)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedFile != null
                                ? '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB — Click to change file'
                                : 'Supports Microsoft Excel (.xlsx) workbooks with Event, Days, Passes, Artists, & Facilities sheets',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Parsing Loading State
            if (_isParsing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: LoadingView(message: 'Parsing and validating Excel sheets...'),
                ),
              ),

            // Live Interactive Preview
            if (_preview != null && !_isParsing) ...[
              _buildPreviewHeader(_preview!),
              const SizedBox(height: 16),

              // Validation Messages Box if any
              if (_preview!.validationMessages.isNotEmpty) ...[
                _buildValidationMessagesCard(_preview!.validationMessages),
                const SizedBox(height: 16),
              ],

              // Tabbed Content Preview
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.neonPurple,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      tabs: [
                        Tab(text: '📌 Event (${_preview!.event?.name ?? "Details"})'),
                        Tab(text: '📅 Days (${_preview!.totalDays})'),
                        Tab(text: '🎟️ Passes (${_preview!.totalPasses})'),
                        Tab(text: '🎤 Artists (${_preview!.totalArtists})'),
                        const Tab(text: '🛡️ Facilities & Rules'),
                      ],
                    ),
                    SizedBox(
                      height: 420,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildEventTab(_preview!.event),
                          _buildDaysTab(_preview!.days),
                          _buildPassesTab(_preview!.days),
                          _buildArtistsTab(_preview!.days),
                          _buildFacilitiesTab(_preview!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: _isCreating
                        ? null
                        : () => setState(() {
                              _selectedFile = null;
                              _preview = null;
                            }),
                    child: const Text('Discard & Re-upload'),
                  ),
                  GradientButton(
                    label: _isCreating ? 'Creating Event...' : '🚀 Confirm & Create Complete Event',
                    isLoading: _isCreating,
                    onPressed: _preview!.hasBlockingErrors ? null : _confirmAndCreate,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewHeader(EventImportPreview preview) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: preview.hasBlockingErrors ? AppColors.error : AppColors.success,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview.event?.name ?? 'Untitled Event',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '${preview.event?.city ?? "City"} • ${preview.event?.startDate ?? "?"} to ${preview.event?.endDate ?? "?"} • ${preview.totalDays} Days • ${preview.totalPasses} Passes • ${preview.totalArtists} Artists',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: preview.hasBlockingErrors
                  ? AppColors.error.withValues(alpha: 0.2)
                  : AppColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  preview.hasBlockingErrors ? Icons.error_rounded : Icons.check_circle_rounded,
                  color: preview.hasBlockingErrors ? AppColors.error : AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  preview.hasBlockingErrors ? 'Blocking Errors Found' : 'Ready for Creation',
                  style: TextStyle(
                    color: preview.hasBlockingErrors ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationMessagesCard(List<ValidationMessage> messages) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Validation Feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ...messages.map((m) {
            final color = m.isError ? AppColors.error : (m.isWarning ? AppColors.warning : AppColors.neonBlue);
            final icon = m.isError ? Icons.cancel : (m.isWarning ? Icons.warning_amber_rounded : Icons.info_outline);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '[${m.sheet}${m.row != null ? " Row ${m.row}" : ""}] ${m.message}',
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEventTab(EventHeaderImport? event) {
    if (event == null) return const Center(child: Text('No event header data'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _RowInfo('Event Name', event.name),
        _RowInfo('Slug', event.slug ?? '(Auto-generated)'),
        _RowInfo('Dates', '${event.startDate ?? "-"} to ${event.endDate ?? "-"}'),
        _RowInfo('City & Location', '${event.city ?? "-"}, ${event.location ?? "-"}'),
        _RowInfo('Venue', event.venue ?? '-'),
        _RowInfo('Address', event.address ?? '-'),
        _RowInfo('Organizer', '${event.organizer ?? "-"} (${event.contactNumber ?? "-"})'),
        _RowInfo('Status', event.status),
        _RowInfo('Featured', event.featured ? 'Yes' : 'No'),
        _RowInfo('Description', event.description ?? '-'),
      ],
    );
  }

  Widget _buildDaysTab(List<EventDayImportItem> days) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final d = days[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceGlass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Day ${d.dayNumber} — ${d.dayName ?? d.programName ?? "Schedule"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.neonPurple)),
                  Text(d.date ?? '-', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 6),
              Text('⏰ ${d.startTime ?? "TBD"} – ${d.endTime ?? "TBD"} • 📍 ${d.venue ?? "Main Venue"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Text('🎟️ ${d.passes.length} Passes • 🎤 ${d.artists.length} Artists', style: const TextStyle(fontSize: 12, color: AppColors.neonPink)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPassesTab(List<EventDayImportItem> days) {
    final allPasses = <Map<String, dynamic>>[];
    for (final d in days) {
      for (final p in d.passes) {
        allPasses.add({'day': d.dayNumber, 'pass': p});
      }
    }

    if (allPasses.isEmpty) return const Center(child: Text('No passes specified'));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surfaceGlass),
          columns: const [
            DataColumn(label: Text('Day', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Pass Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Benefits', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: allPasses.map((item) {
            final pass = item['pass'] as PassImportItem;
            return DataRow(
              cells: [
                DataCell(Text('Day ${item['day']}')),
                DataCell(Text(pass.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(StatusBadge(status: pass.type)),
                DataCell(Text('₹${pass.price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.bold))),
                DataCell(Text('${pass.availableQuantity}')),
                DataCell(Text(pass.benefits.join(', '), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildArtistsTab(List<EventDayImportItem> days) {
    final allArtists = <Map<String, dynamic>>[];
    for (final d in days) {
      for (final a in d.artists) {
        allArtists.add({'day': d.dayNumber, 'artist': a});
      }
    }

    if (allArtists.isEmpty) return const Center(child: Text('No artists specified'));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: allArtists.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final item = allArtists[i];
        final a = item['artist'] as ArtistImportItem;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surfaceGlass, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.neonPurple.withValues(alpha: 0.3),
                child: const Icon(Icons.music_note, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(a.artistName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 8),
                        if (a.isPrimary)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.neonPink.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4)),
                            child: const Text('HEADLINER', style: TextStyle(fontSize: 10, color: AppColors.neonPink, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    Text('Day ${item['day']} • ${a.artistType} • Order #${a.performanceOrder ?? 1} • ${a.performanceStartTime ?? "TBD"} – ${a.performanceEndTime ?? "TBD"}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                a.isExistingArtist ? '🟢 Matched' : '🟡 New Artist',
                style: TextStyle(fontSize: 11, color: a.isExistingArtist ? AppColors.success : AppColors.warning),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFacilitiesTab(EventImportPreview preview) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Event Facilities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.neonPurple)),
        const SizedBox(height: 8),
        if (preview.eventFacilities.isEmpty)
          const Text('No event-level facilities', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
        else
          ...preview.eventFacilities.map((f) => ListTile(
                dense: true,
                leading: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                title: Text(f.name),
                subtitle: Text(f.description ?? f.scope, style: const TextStyle(fontSize: 11)),
              )),
        const Divider(color: AppColors.divider),
        const Text('Highlights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.neonPurple)),
        const SizedBox(height: 8),
        ...preview.highlights.map((h) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 6),
                  Expanded(child: Text(h, style: const TextStyle(fontSize: 12))),
                ],
              ),
            )),
        const Divider(color: AppColors.divider),
        const Text('Rules & Guidelines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.neonPurple)),
        const SizedBox(height: 8),
        ...preview.rules.map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.neonBlue, size: 14),
                  const SizedBox(width: 6),
                  Expanded(child: Text(r, style: const TextStyle(fontSize: 12))),
                ],
              ),
            )),
      ],
    );
  }
}

class _RowInfo extends StatelessWidget {
  final String label;
  final String value;
  const _RowInfo(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}
