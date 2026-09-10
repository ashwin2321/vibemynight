import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../models/artist.dart';
import '../widgets/admin_shell.dart';
import '../widgets/image_upload_field.dart';

class AdminCreateArtistScreen extends StatelessWidget {
  const AdminCreateArtistScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminArtistForm();
}

class AdminEditArtistScreen extends ConsumerWidget {
  final int artistId;

  const AdminEditArtistScreen({super.key, required this.artistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(adminArtistsProvider);
    return artistsAsync.when(
      loading: () => const AdminShell(title: 'Edit Artist', currentPath: '/admin/artists', body: LoadingView()),
      error: (err, _) => AdminShell(
        title: 'Edit Artist',
        currentPath: '/admin/artists',
        body: ErrorView(message: err.toString(), onRetry: () => ref.invalidate(adminArtistsProvider)),
      ),
      data: (artists) {
        Artist? artist;
        for (final a in artists) {
          if (a.id == artistId) {
            artist = a;
            break;
          }
        }
        if (artist == null) {
          return const AdminShell(
              title: 'Edit Artist', currentPath: '/admin/artists', body: Center(child: Text('Artist not found.')));
        }
        return _AdminArtistForm(artistId: artistId, initial: artist);
      },
    );
  }
}

class _AdminArtistForm extends ConsumerStatefulWidget {
  final int? artistId;
  final Artist? initial;

  const _AdminArtistForm({this.artistId, this.initial});

  @override
  ConsumerState<_AdminArtistForm> createState() => _AdminArtistFormState();
}

class _AdminArtistFormState extends ConsumerState<_AdminArtistForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _slug;
  late final TextEditingController _photoUrl;
  late final TextEditingController _shortBio;
  late final TextEditingController _fullBio;
  late final TextEditingController _instagramUrl;
  late final TextEditingController _facebookUrl;
  late final TextEditingController _youtubeUrl;
  String _type = 'SINGER';
  bool _featured = false;
  bool _submitting = false;
  String? _error;

  static const _types = ['SINGER', 'DJ', 'BAND', 'CELEBRITY', 'PERFORMER', 'LIVE_ARTIST', 'OTHER'];

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _name = TextEditingController(text: a?.name ?? '');
    _slug = TextEditingController(text: a?.slug ?? '');
    _photoUrl = TextEditingController(text: a?.photoUrl ?? '');
    _shortBio = TextEditingController(text: a?.shortBio ?? '');
    _fullBio = TextEditingController(text: a?.fullBio ?? '');
    _instagramUrl = TextEditingController(text: a?.instagramUrl ?? '');
    _facebookUrl = TextEditingController(text: a?.facebookUrl ?? '');
    _youtubeUrl = TextEditingController(text: a?.youtubeUrl ?? '');
    _type = a?.type ?? 'SINGER';
    _featured = a?.featured ?? false;
  }

  @override
  void dispose() {
    for (final c in [_name, _slug, _photoUrl, _shortBio, _fullBio, _instagramUrl, _facebookUrl, _youtubeUrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final body = {
      'name': _name.text.trim(),
      'slug': _slug.text.trim(),
      if (_photoUrl.text.trim().isNotEmpty) 'photoUrl': _photoUrl.text.trim(),
      'type': _type,
      if (_shortBio.text.trim().isNotEmpty) 'shortBio': _shortBio.text.trim(),
      if (_fullBio.text.trim().isNotEmpty) 'fullBio': _fullBio.text.trim(),
      if (_instagramUrl.text.trim().isNotEmpty) 'instagramUrl': _instagramUrl.text.trim(),
      if (_facebookUrl.text.trim().isNotEmpty) 'facebookUrl': _facebookUrl.text.trim(),
      if (_youtubeUrl.text.trim().isNotEmpty) 'youtubeUrl': _youtubeUrl.text.trim(),
      'featured': _featured,
    };
    try {
      final admin = ref.read(adminServiceProvider);
      if (widget.artistId != null) {
        await admin.updateArtist(widget.artistId!, body);
      } else {
        await admin.createArtist(body);
      }
      ref.invalidate(adminArtistsProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.artistId != null;
    return AdminShell(
      title: isEdit ? 'Edit Artist' : 'Create Artist',
      currentPath: '/admin/artists',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Artist Name *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _slug,
              decoration: const InputDecoration(labelText: 'Slug *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              decoration: const InputDecoration(labelText: 'Type *'),
              items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            ImageUploadField(controller: _photoUrl, label: 'Photo URL', folder: 'artists'),
            const SizedBox(height: 12),
            TextFormField(controller: _shortBio, decoration: const InputDecoration(labelText: 'Short Bio')),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fullBio,
              decoration: const InputDecoration(labelText: 'Full Bio'),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _instagramUrl, decoration: const InputDecoration(labelText: 'Instagram URL')),
            const SizedBox(height: 12),
            TextFormField(controller: _facebookUrl, decoration: const InputDecoration(labelText: 'Facebook URL')),
            const SizedBox(height: 12),
            TextFormField(controller: _youtubeUrl, decoration: const InputDecoration(labelText: 'YouTube URL')),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Featured'),
              value: _featured,
              onChanged: (v) => setState(() => _featured = v),
            ),
            const SizedBox(height: 20),
            if (_error != null) ErrorView(message: _error!),
            GradientButton(
              label: _submitting ? 'SAVING...' : (isEdit ? 'SAVE CHANGES' : 'CREATE ARTIST'),
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
