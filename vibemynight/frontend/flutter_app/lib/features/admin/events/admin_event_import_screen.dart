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

enum _ImportMode { url, excel }

/// Admin Event Builder & Multi-Platform Auto-Importer
/// Allows admins to:
/// 1. 🌐 1-Click Scrape & Auto-Fill events from BookMyShow, District/Insider, Showmates, or web links.
/// 2. 📁 Upload Excel (.xlsx) workbooks containing complete event hierarchies.
/// Inspect live preview with validation badges across 5 tabs and atomically create complete events in one click.
class AdminEventImportScreen extends ConsumerStatefulWidget {
  const AdminEventImportScreen({super.key});

  @override
  ConsumerState<AdminEventImportScreen> createState() => _AdminEventImportScreenState();
}

class _AdminEventImportScreenState extends ConsumerState<AdminEventImportScreen> with SingleTickerProviderStateMixin {
  _ImportMode _mode = _ImportMode.url;
  final TextEditingController _urlController = TextEditingController();
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
    _urlController.dispose();
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

  Future<void> _scrapeUrl() async {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) {
      setState(() => _errorMessage = 'Please enter or paste a valid event URL.');
      return;
    }

    setState(() {
      _isParsing = true;
      _errorMessage = null;
      _preview = null;
    });

    try {
      final preview = await ref.read(adminServiceProvider).scrapeEventUrl(rawUrl);
      setState(() {
        _preview = preview;
        _isParsing = false;
      });
    } catch (e) {
      setState(() {
        _isParsing = false;
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
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
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
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
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Event Auto-Importer & Builder',
      currentPath: '/admin/events',
      actions: [
        if (_mode == _ImportMode.excel)
          OutlinedButton.icon(
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Download Excel Template'),
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
            // Mode Selector Banner
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surfaceGlass,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeSelectorButton(
                      icon: Icons.language_rounded,
                      title: '1-Click Web URL Import',
                      subtitle: 'BookMyShow • District • Showmates • Web',
                      isSelected: _mode == _ImportMode.url,
                      onTap: () => setState(() {
                        _mode = _ImportMode.url;
                        _errorMessage = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ModeSelectorButton(
                      icon: Icons.table_chart_rounded,
                      title: 'Excel (.xlsx) Import',
                      subtitle: 'Bulk multi-day spreadsheet upload',
                      isSelected: _mode == _ImportMode.excel,
                      onTap: () => setState(() {
                        _mode = _ImportMode.excel;
                        _errorMessage = null;
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mode 1: 1-Click URL Scraper
            if (_mode == _ImportMode.url) ...[
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: AppColors.neonPurple, size: 22),
                        SizedBox(width: 8),
                        Text(
                          '1-Click Multi-Platform Event Importer',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Paste any event link from BookMyShow, District by Zomato, Showmates, or any ticketing webpage. We will extract the full poster, 16:9 banner, date range, venue, artists, and prices automatically.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // Supported Brand Badges
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PlatformBadge(label: 'BookMyShow', icon: Icons.movie_outlined, color: Color(0xFFE11D48)),
                        _PlatformBadge(label: 'District by Zomato', icon: Icons.local_activity_outlined, color: Color(0xFFF97316)),
                        _PlatformBadge(label: 'Showmates', icon: Icons.theater_comedy_outlined, color: Color(0xFF84CC16)),
                        _PlatformBadge(label: 'Any Event Webpage', icon: Icons.public, color: Color(0xFF60A5FA)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Input & Action
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _urlController,
                            enabled: !_isParsing && !_isCreating,
                            decoration: InputDecoration(
                              hintText: 'https://showmates.in/events/... or https://www.district.in/...',
                              prefixIcon: const Icon(Icons.link_rounded, color: AppColors.neonPurple),
                              suffixIcon: _urlController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () => setState(() => _urlController.clear()),
                                    )
                                  : null,
                            ),
                            onSubmitted: (_) => _scrapeUrl(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GradientButton(
                          label: _isParsing ? 'FETCHING...' : '⚡ FETCH & AUTO-FILL',
                          isLoading: _isParsing,
                          onPressed: _isParsing || _isCreating ? null : _scrapeUrl,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick Sample Link Chips for Easy Testing
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Try Sample:',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.theater_comedy, size: 14, color: Color(0xFF84CC16)),
                          label: const Text('Showmates Dome Garba', style: TextStyle(fontSize: 11)),
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: Color(0xFF84CC16), width: 0.5),
                          onPressed: () {
                            setState(() {
                              _urlController.text = 'https://showmates.in/events/swarnim-nagari-ac-dome-garba-2026/B61D192';
                            });
                            _scrapeUrl();
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.local_activity, size: 14, color: Color(0xFFF97316)),
                          label: const Text('District Navratri', style: TextStyle(fontSize: 11)),
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: Color(0xFFF97316), width: 0.5),
                          onPressed: () {
                            setState(() {
                              _urlController.text = 'https://www.district.in/events/navratri-in-ahmedabad-book-tickets';
                            });
                            _scrapeUrl();
                          },
                        ),
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorBanner(_errorMessage!),
                    ],
                  ],
                ),
              ),
            ],

            // Mode 2: Excel File Upload
            if (_mode == _ImportMode.excel) ...[
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
                      _buildErrorBanner(_errorMessage!),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Loading State
            if (_isParsing)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: LoadingView(
                    message: _mode == _ImportMode.url
                        ? 'Connecting to source, extracting high-res posters, dates & lineup...'
                        : 'Parsing and validating Excel sheets...',
                  ),
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
                      height: 440,
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
                              _urlController.clear();
                              _preview = null;
                            }),
                    child: const Text('Discard & Start Over'),
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

  Widget _buildErrorBanner(String message) {
    return Container(
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
            child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
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
          const Text('Validation Feedback & Warnings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      m.sheet,
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      m.message,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
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
    if (event == null) return const Center(child: Text('No event header data found.'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoRow('Event Name', event.name),
        _buildInfoRow('Slug', event.slug ?? 'auto-generated'),
        _buildInfoRow('Dates', '${event.startDate ?? "TBD"} to ${event.endDate ?? "TBD"}'),
        _buildInfoRow('City / Venue', '${event.city ?? "Ahmedabad"} • ${event.venue ?? "TBD"}'),
        _buildInfoRow('Location / Address', event.location ?? event.address ?? 'Not specified'),
        _buildInfoRow('Organizer', '${event.organizer ?? "VibeMyNight"} (${event.contactNumber ?? "N/A"})'),
        _buildInfoRow('Status', event.status),
        _buildInfoRow('Description', event.description ?? 'N/A'),
        const SizedBox(height: 12),
        const Text('Media & Banners:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (event.mainImage != null) _buildThumbCard('3:4 Poster', event.mainImage!),
            if (event.banner != null) _buildThumbCard('16:9 Banner', event.banner!),
            if (event.thumbnail != null) _buildThumbCard('Thumbnail', event.thumbnail!),
          ],
        ),
      ],
    );
  }

  Widget _buildThumbCard(String label, String url) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.neonPurple)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              url,
              height: 70,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysTab(List<EventDayImportItem> days) {
    if (days.isEmpty) return const Center(child: Text('No days defined.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: days.length,
      itemBuilder: (context, i) {
        final day = days[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceGlass,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.neonPurple.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${day.dayNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.neonPurple),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${day.dayName ?? "Day ${day.dayNumber}"} • ${day.date ?? ""}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.programName ?? "Live Night"} (${day.startTime ?? "20:00"} - ${day.endTime ?? "00:00"}) • ${day.passes.length} Passes • ${day.artists.length} Artists',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

  Widget _buildPassesTab(List<EventDayImportItem> days) {
    final allPasses = <Map<String, dynamic>>[];
    for (final d in days) {
      for (final p in d.passes) {
        allPasses.add({'day': d.dayNumber, 'pass': p});
      }
    }
    if (allPasses.isEmpty) return const Center(child: Text('No passes configured.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allPasses.length,
      itemBuilder: (context, i) {
        final item = allPasses[i];
        final dayNum = item['day'];
        final pass = item['pass'] as PassImportItem;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceGlass,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neonPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Day $dayNum', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neonPurple)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pass.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (pass.benefits.isNotEmpty)
                      Text(pass.benefits.join(', '), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${pass.price.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.neonPink, fontSize: 16)),
                  Text('${pass.availableQuantity} qty', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArtistsTab(List<EventDayImportItem> days) {
    final allArtists = <Map<String, dynamic>>[];
    for (final d in days) {
      for (final a in d.artists) {
        allArtists.add({'day': d.dayNumber, 'artist': a});
      }
    }
    if (allArtists.isEmpty) {
      return const Center(
        child: Text('No performers/artists found in source. You can assign artists after creation.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allArtists.length,
      itemBuilder: (context, i) {
        final item = allArtists[i];
        final dayNum = item['day'];
        final a = item['artist'] as ArtistImportItem;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceGlass,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: a.photoUrl != null && a.photoUrl!.isNotEmpty ? NetworkImage(a.photoUrl!) : null,
                child: a.photoUrl == null || a.photoUrl!.isEmpty ? const Icon(Icons.person, size: 18) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.artistName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('${a.artistType} • Day $dayNum', style: const TextStyle(fontSize: 11, color: AppColors.neonPurple)),
                  ],
                ),
              ),
              if (a.isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.neonPink.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Headline Artist', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.neonPink)),
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
        const Text('Event Facilities & Amenities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: preview.eventFacilities
              .map((f) => Chip(
                    avatar: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                    label: Text(f.name, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.surfaceGlass,
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        const Text('Rules & Guidelines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        ...preview.rules.map((r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 14, color: AppColors.neonBlue),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r, style: const TextStyle(fontSize: 12, color: Colors.white70))),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ModeSelectorButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeSelectorButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.neonPurple : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.neonPurple : AppColors.textSecondary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _PlatformBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
