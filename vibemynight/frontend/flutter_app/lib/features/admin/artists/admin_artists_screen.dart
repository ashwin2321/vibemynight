import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/providers/artist_type_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/network_image_box.dart';
import '../../../models/artist.dart';
import '../widgets/admin_shell.dart';
import '../widgets/status_badge.dart';

enum _ArtistViewMode { grid, table }

/// Admin artists page (GET /admin/artists) with Grid & Table view toggles,
/// search, status toggle, dynamic artist types filter, edit, and delete.
class AdminArtistsScreen extends ConsumerStatefulWidget {
  const AdminArtistsScreen({super.key});

  @override
  ConsumerState<AdminArtistsScreen> createState() => _AdminArtistsScreenState();
}

class _AdminArtistsScreenState extends ConsumerState<AdminArtistsScreen> {
  String _query = '';
  String _selectedType = 'ALL';
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

  Future<void> _promptNewArtistType() async {
    final controller = TextEditingController();
    final newType = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider),
        ),
        title: const Row(
          children: [
            Icon(Icons.stars_rounded, color: AppColors.neonPurple, size: 22),
            SizedBox(width: 8),
            Text('Add Custom Artist Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter new artist category/type code (e.g. GARBA_SINGER, FLUTIST, CHOREOGRAPHER, SHAYAR, MAGICIAN, TABLA_PLAYER)',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Artist Type Name *',
                hintText: 'e.g. GARBA_SINGER',
                prefixIcon: Icon(Icons.mic, color: AppColors.neonPurple, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonPurple),
            onPressed: () {
              final text = controller.text.trim().toUpperCase().replaceAll(' ', '_');
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            child: const Text('Add Type'),
          ),
        ],
      ),
    );

    if (newType != null && newType.isNotEmpty) {
      final addedCode = await ref.read(artistTypesProvider.notifier).addArtistType(newType);
      setState(() => _selectedType = addedCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added new artist type "$addedCode" to catalog! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final artistsAsync = ref.watch(adminArtistsProvider);
    final artistTypes = ref.watch(artistTypesProvider);

    return AdminShell(
      title: 'Artists',
      currentPath: '/admin/artists',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.stars_rounded, size: 16),
            label: const Text('+ New Type'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.neonPurple,
              side: const BorderSide(color: AppColors.neonPurple),
            ),
            onPressed: _promptNewArtistType,
          ),
        ),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

          // Artist Type Filter Pills
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _TypeFilterChip(
                  label: 'All Types',
                  selected: _selectedType == 'ALL',
                  onTap: () => setState(() => _selectedType = 'ALL'),
                ),
                for (final typeCode in artistTypes)
                  _TypeFilterChip(
                    label: formatArtistType(typeCode),
                    selected: _selectedType == typeCode,
                    onTap: () => setState(() => _selectedType = typeCode),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Artists list
          Expanded(
            child: artistsAsync.when(
              loading: () => const LoadingView(),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(adminArtistsProvider),
              ),
              data: (artists) {
                var filtered = artists;
                if (_selectedType != 'ALL') {
                  filtered = filtered.where((a) {
                    final aType = a.type.toUpperCase().replaceAll(' ', '_');
                    return aType == _selectedType;
                  }).toList();
                }
                if (_query.isNotEmpty) {
                  final q = _query.toLowerCase();
                  filtered = filtered.where((a) =>
                      a.name.toLowerCase().contains(q) ||
                      a.type.toLowerCase().contains(q) ||
                      (a.shortBio?.toLowerCase().contains(q) ?? false)).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mic_off, size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        const Text('No artists found matching your criteria.', style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Artist'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonPurple),
                          onPressed: () => context.push('/admin/artists/new'),
                        ),
                      ],
                    ),
                  );
                }

                return _viewMode == _ArtistViewMode.grid
                    ? _buildGrid(filtered)
                    : _buildTable(filtered);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Artist> artists) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 800
                ? 3
                : constraints.maxWidth > 500
                    ? 2
                    : 1;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.78,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            final isActive = artist.status == 'ACTIVE';

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Photo with Status & Featured Badges
                  Expanded(
                    flex: 5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        NetworkImageBox(
                          url: artist.photoUrl,
                          fit: BoxFit.cover,
                        ),
                        // Top badges
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.neonPurple,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '★ Featured',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Artist Details
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artist.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatArtistType(artist.type),
                            style: const TextStyle(color: AppColors.neonPurple, fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (artist.shortBio != null && artist.shortBio!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Expanded(
                              child: Text(
                                artist.shortBio!,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else
                            const Spacer(),

                          // Actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isActive ? Icons.visibility : Icons.visibility_off,
                                  size: 18,
                                  color: isActive ? AppColors.success : AppColors.textSecondary,
                                ),
                                tooltip: isActive ? 'Deactivate' : 'Activate',
                                onPressed: () => _toggleStatus(artist),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: AppColors.neonPurple),
                                tooltip: 'Edit',
                                onPressed: () => context.push('/admin/artists/${artist.id}/edit'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                                tooltip: 'Delete',
                                onPressed: () => _delete(artist),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTable(List<Artist> artists) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Artist')),
            DataColumn(label: Text('Type / Role')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Featured')),
            DataColumn(label: Text('Actions')),
          ],
          rows: artists.map((artist) {
            final isActive = artist.status == 'ACTIVE';
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: artist.photoUrl != null && artist.photoUrl!.isNotEmpty
                            ? NetworkImage(artist.photoUrl!)
                            : null,
                        child: artist.photoUrl == null || artist.photoUrl!.isEmpty
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(artist.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                DataCell(Text(formatArtistType(artist.type))),
                DataCell(StatusBadge(status: artist.status)),
                DataCell(
                  artist.featured
                      ? const Text('★ Yes', style: TextStyle(color: AppColors.neonPurple, fontWeight: FontWeight.bold))
                      : const Text('No', style: TextStyle(color: AppColors.textSecondary)),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isActive ? Icons.visibility : Icons.visibility_off,
                          size: 18,
                          color: isActive ? AppColors.success : AppColors.textSecondary,
                        ),
                        tooltip: isActive ? 'Deactivate' : 'Activate',
                        onPressed: () => _toggleStatus(artist),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: AppColors.neonPurple),
                        tooltip: 'Edit',
                        onPressed: () => context.push('/admin/artists/${artist.id}/edit'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
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
    );
  }
}

class _TypeFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.textSecondary)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.neonPurple,
        backgroundColor: AppColors.surface,
        checkmarkColor: Colors.white,
        side: BorderSide(color: selected ? AppColors.neonPurple : AppColors.divider),
      ),
    );
  }
}
