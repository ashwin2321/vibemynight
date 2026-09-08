import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/network_image_box.dart';
import '../../../models/artist.dart';
import '../widgets/admin_shell.dart';
import '../widgets/status_badge.dart';

enum _ArtistViewMode { grid, table }

/// Admin artists page (GET /admin/artists) with Grid & Table view toggles,
/// search, status toggle, edit, and delete - matching the Figma Admin Artists design.
class AdminArtistsScreen extends ConsumerStatefulWidget {
  const AdminArtistsScreen({super.key});

  @override
  ConsumerState<AdminArtistsScreen> createState() => _AdminArtistsScreenState();
}

class _AdminArtistsScreenState extends ConsumerState<AdminArtistsScreen> {
  String _query = '';
  _ArtistViewMode _viewMode = _ArtistViewMode.grid;

  Future<void> _toggleStatus(Artist artist) async {
    final newStatus = artist.status == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    try {
      await ref.read(adminServiceProvider).changeArtistStatus(artist.id, newStatus);
      ref.invalidate(adminArtistsProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _delete(Artist artist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${artist.name}?'),
        content: const Text('This will remove the artist from the system.'),
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
      await ref.read(adminServiceProvider).deleteArtist(artist.id);
      ref.invalidate(adminArtistsProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final artistsAsync = ref.watch(adminArtistsProvider);

    return AdminShell(
      title: 'Artists',
      currentPath: '/admin/artists',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Artist'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () => context.push('/admin/artists/new'),
          ),
        ),
      ],
      body: Column(
        children: [
          // Toolbar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Search artists by name or genre…',
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
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGlass,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.grid_view, size: 20),
                          tooltip: 'Grid view',
                          color: _viewMode == _ArtistViewMode.grid ? AppColors.neonPurple : AppColors.textSecondary,
                          onPressed: () => setState(() => _viewMode = _ArtistViewMode.grid),
                        ),
                        IconButton(
                          icon: const Icon(Icons.table_rows, size: 20),
                          tooltip: 'Table view',
                          color: _viewMode == _ArtistViewMode.table ? AppColors.neonPurple : AppColors.textSecondary,
                          onPressed: () => setState(() => _viewMode = _ArtistViewMode.table),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Artists list
          Expanded(
            child: artistsAsync.when(
              loading: () => const LoadingView(),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(adminArtistsProvider),
              ),
              data: (artists) {
                final filtered = _query.isEmpty
                    ? artists
                    : artists.where((a) =>
                        a.name.toLowerCase().contains(_query.toLowerCase()) ||
                        a.type.toLowerCase().contains(_query.toLowerCase())).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mic_off, size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        const Text('No artists found.', style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Artist'),
                          onPressed: () => context.push('/admin/artists/new'),
                        ),
                      ],
                    ),
                  );
                }

                if (_viewMode == _ArtistViewMode.grid) {
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final artist = filtered[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                NetworkImageBox(
                                  url: artist.photoUrl,
                                  height: 140,
                                  width: double.infinity,
                                  borderRadius: BorderRadius.zero,
                                ),
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: StatusBadge(status: artist.status),
                                ),
                                if (artist.featured)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.amber,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.star, size: 14, color: Colors.black),
                                    ),
                                  ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    artist.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    artist.type,
                                    style: const TextStyle(color: AppColors.neonPink, fontSize: 11, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            minimumSize: const Size(0, 30),
                                          ),
                                          onPressed: () => context.push('/admin/artists/${artist.id}/edit'),
                                          child: const Text('Edit', style: TextStyle(fontSize: 11)),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          artist.status == 'ACTIVE' ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                          size: 18,
                                          color: AppColors.textSecondary,
                                        ),
                                        tooltip: artist.status == 'ACTIVE' ? 'Deactivate' : 'Activate',
                                        onPressed: () => _toggleStatus(artist),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                        tooltip: 'Delete',
                                        onPressed: () => _delete(artist),
                                      ),
                                    ],
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

                // Table View
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppColors.surfaceGlass),
                        columns: const [
                          DataColumn(label: Text('Artist', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Featured', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filtered.map((artist) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    NetworkImageBox(
                                      url: artist.photoUrl,
                                      height: 38,
                                      width: 38,
                                      borderRadius: BorderRadius.circular(19),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(artist.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              DataCell(Text(artist.type)),
                              DataCell(
                                artist.featured
                                    ? const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star, color: Colors.amber, size: 16),
                                          SizedBox(width: 4),
                                          Text('Featured', style: TextStyle(color: Colors.amber, fontSize: 12)),
                                        ],
                                      )
                                    : const Text('-', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                              DataCell(StatusBadge(status: artist.status)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                      tooltip: 'Edit',
                                      onPressed: () => context.push('/admin/artists/${artist.id}/edit'),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        artist.status == 'ACTIVE' ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        size: 20,
                                        color: artist.status == 'ACTIVE' ? AppColors.success : AppColors.textSecondary,
                                      ),
                                      tooltip: artist.status == 'ACTIVE' ? 'Deactivate' : 'Activate',
                                      onPressed: () => _toggleStatus(artist),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                                      tooltip: 'Delete',
                                      onPressed: () => _delete(artist),
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
