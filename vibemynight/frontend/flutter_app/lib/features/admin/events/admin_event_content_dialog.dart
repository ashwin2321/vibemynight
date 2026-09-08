import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/network_image_box.dart';
import '../widgets/image_upload_field.dart';

/// Content & Facilities management modal for an Event:
/// - Event Facilities (attach/detach)
/// - Event Highlights (add/delete)
/// - Event Rules (add/delete)
/// - Event Gallery images (add/upload/delete)
class AdminEventContentDialog extends ConsumerStatefulWidget {
  final int eventId;
  final String eventName;

  const AdminEventContentDialog({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  ConsumerState<AdminEventContentDialog> createState() => _AdminEventContentDialogState();
}

class _AdminEventContentDialogState extends ConsumerState<AdminEventContentDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Controllers for adding items
  final _highlightController = TextEditingController();
  final _ruleController = TextEditingController();
  final _galleryUrlController = TextEditingController();
  final _galleryCaptionController = TextEditingController();

  bool _actionLoading = false;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _highlightController.dispose();
    _ruleController.dispose();
    _galleryUrlController.dispose();
    _galleryCaptionController.dispose();
    super.dispose();
  }

  Future<void> _addHighlight() async {
    final text = _highlightController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _actionLoading = true;
      _actionError = null;
    });
    try {
      await ref.read(adminServiceProvider).addHighlight(widget.eventId, {'text': text});
      _highlightController.clear();
      ref.invalidate(adminEventDetailProvider(widget.eventId));
    } catch (e) {
      setState(() => _actionError = e.toString());
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _addRule() async {
    final text = _ruleController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _actionLoading = true;
      _actionError = null;
    });
    try {
      await ref.read(adminServiceProvider).addRule(widget.eventId, {'text': text});
      _ruleController.clear();
      ref.invalidate(adminEventDetailProvider(widget.eventId));
    } catch (e) {
      setState(() => _actionError = e.toString());
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _addGalleryImage() async {
    final url = _galleryUrlController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _actionLoading = true;
      _actionError = null;
    });
    try {
      await ref.read(adminServiceProvider).addGalleryImage(widget.eventId, {
        'imageUrl': url,
        if (_galleryCaptionController.text.trim().isNotEmpty)
          'caption': _galleryCaptionController.text.trim(),
      });
      _galleryUrlController.clear();
      _galleryCaptionController.clear();
      ref.invalidate(adminEventDetailProvider(widget.eventId));
    } catch (e) {
      setState(() => _actionError = e.toString());
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _toggleFacility(int facilityId, bool isAttached) async {
    try {
      if (isAttached) {
        await ref.read(adminServiceProvider).removeFacilityFromEvent(widget.eventId, facilityId);
      } else {
        await ref.read(adminServiceProvider).addFacilityToEvent(widget.eventId, facilityId);
      }
      ref.invalidate(adminEventDetailProvider(widget.eventId));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(adminEventDetailProvider(widget.eventId));
    final facilitiesAsync = ref.watch(adminFacilitiesProvider);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Event Content & Facilities',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.eventName,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.neonPurple,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(text: 'Facilities'),
                  Tab(text: 'Highlights'),
                  Tab(text: 'Rules'),
                  Tab(text: 'Gallery'),
                ],
              ),
              if (_actionError != null) ...[
                const SizedBox(height: 8),
                Text(_actionError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: eventAsync.when(
                  loading: () => const LoadingView(),
                  error: (err, _) => ErrorView(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(adminEventDetailProvider(widget.eventId)),
                  ),
                  data: (event) => TabBarView(
                    controller: _tabController,
                    children: [
                      // Facilities Tab
                      facilitiesAsync.when(
                        loading: () => const LoadingView(),
                        error: (err, _) => ErrorView(message: err.toString()),
                        data: (allFacilities) {
                          final attachedIds = event.facilities.map((f) => f.id).toSet();
                          if (allFacilities.isEmpty) {
                            return const Center(child: Text('No facilities created yet in Admin > Facilities.'));
                          }
                          return ListView.builder(
                            itemCount: allFacilities.length,
                            itemBuilder: (context, index) {
                              final f = allFacilities[index];
                              final isAttached = attachedIds.contains(f.id);
                              return CheckboxListTile(
                                value: isAttached,
                                title: Text(f.name),
                                subtitle: f.description != null ? Text(f.description!, style: const TextStyle(fontSize: 12)) : null,
                                activeColor: AppColors.neonPurple,
                                onChanged: (v) => _toggleFacility(f.id, isAttached),
                              );
                            },
                          );
                        },
                      ),

                      // Highlights Tab
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _highlightController,
                                  decoration: const InputDecoration(
                                    hintText: 'Add a highlight (e.g. Laser Show, Live Garba)',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _actionLoading ? null : _addHighlight,
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: event.highlights.isEmpty
                                ? const Center(child: Text('No highlights added yet.'))
                                : ListView.builder(
                                    itemCount: event.highlights.length,
                                    itemBuilder: (context, index) {
                                      final h = event.highlights[index];
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(Icons.bolt, color: AppColors.neonPink, size: 20),
                                        title: Text(h),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),

                      // Rules Tab
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _ruleController,
                                  decoration: const InputDecoration(
                                    hintText: 'Add an event rule (e.g. Traditional attire mandatory)',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _actionLoading ? null : _addRule,
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: event.rules.isEmpty
                                ? const Center(child: Text('No rules added yet.'))
                                : ListView.builder(
                                    itemCount: event.rules.length,
                                    itemBuilder: (context, index) {
                                      final r = event.rules[index];
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(Icons.rule, color: AppColors.neonBlue, size: 20),
                                        title: Text(r),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),

                      // Gallery Tab
                      Column(
                        children: [
                          ImageUploadField(
                            controller: _galleryUrlController,
                            label: 'Gallery Image URL',
                            folder: 'gallery',
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _galleryCaptionController,
                                  decoration: const InputDecoration(
                                    hintText: 'Optional caption',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _actionLoading ? null : _addGalleryImage,
                                child: const Text('Add Image'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: event.galleryImageUrls.isEmpty
                                ? const Center(child: Text('No gallery images added yet.'))
                                : GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemCount: event.galleryImageUrls.length,
                                    itemBuilder: (context, index) {
                                      final url = event.galleryImageUrls[index];
                                      return NetworkImageBox(url: url, borderRadius: BorderRadius.circular(8));
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
