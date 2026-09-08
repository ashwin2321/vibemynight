import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/network_image_box.dart';

/// A URL text field plus an "Upload" button that picks an image (bytes, so
/// it works on Flutter Web too) and calls POST /admin/uploads, filling the
/// field with the returned URL. Used anywhere an admin form has an image
/// field (artist photo, event images, gallery) - see admin_artist_form_screen
/// for the reference wiring.
class ImageUploadField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String label;
  final String folder;

  const ImageUploadField({
    super.key,
    required this.controller,
    required this.label,
    required this.folder,
  });

  @override
  ConsumerState<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends ConsumerState<ImageUploadField> {
  bool _uploading = false;
  String? _error;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final picked = result?.files.single;
    if (picked == null || picked.bytes == null) return;

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final url = await ref
          .read(adminServiceProvider)
          .uploadImage(picked.bytes!, picked.name, folder: widget.folder);
      widget.controller.text = url;
      setState(() {});
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.controller,
                decoration: InputDecoration(labelText: widget.label),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _uploading ? null : _pickAndUpload,
                icon: _uploading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_outlined, size: 18),
                label: const Text('Upload'),
              ),
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
          ),
        if (widget.controller.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: NetworkImageBox(url: widget.controller.text, height: 80, width: 80),
          ),
      ],
    );
  }
}
