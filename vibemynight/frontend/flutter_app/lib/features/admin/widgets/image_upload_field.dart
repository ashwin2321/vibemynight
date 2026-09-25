import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/network_image_box.dart';

/// Premium, guided Image Upload Field with live Aspect Ratio preview box,
/// role badges ([16:9 BANNER], [3:4 POSTER], [1:1 SQUARE]), recommended dimensions,
/// and instant clear/upload controls.
class ImageUploadField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String label;
  final String folder;
  final double? aspectRatio;
  final String? badgeLabel;
  final String? recommendedSize;
  final String? helperText;
  final double previewHeight;

  const ImageUploadField({
    super.key,
    required this.controller,
    required this.label,
    required this.folder,
    this.aspectRatio,
    this.badgeLabel,
    this.recommendedSize,
    this.helperText,
    this.previewHeight = 160,
  });

  @override
  ConsumerState<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends ConsumerState<ImageUploadField> {
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

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

  bool get _isExternalUrl {
    final text = widget.controller.text.trim();
    return (text.startsWith('http://') || text.startsWith('https://')) &&
        !text.contains('/api/v1/uploads/') &&
        !text.contains('/uploads/');
  }

  Future<void> _saveExternalImageToServer() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final localUrl = await ref
          .read(adminServiceProvider)
          .uploadImageFromUrl(text, folder: widget.folder);
      widget.controller.text = localUrl;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image downloaded & saved to server!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save to server: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.controller.text.trim().isNotEmpty;
    final isStructured = widget.aspectRatio != null || widget.badgeLabel != null;

    if (!isStructured) {
      // Legacy / Compact simple row for standard admin forms
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
          if (_isExternalUrl)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: OutlinedButton.icon(
                onPressed: _uploading ? null : _saveExternalImageToServer,
                icon: const Icon(Icons.download_for_offline_outlined, size: 14, color: Color(0xFF10B981)),
                label: const Text('Save to Server (Permanent)', style: TextStyle(color: Color(0xFF10B981), fontSize: 11.5)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                ),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ),
          if (hasImage)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: NetworkImageBox(url: widget.controller.text.trim(), height: 80, width: 80),
            ),
        ],
      );
    }

    // Guided visual card with live aspect ratio frame & usage guidance
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF130F26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasImage
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Label + Aspect Ratio Badge + Recommended Size
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.badgeLabel != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    widget.badgeLabel!,
                    style: const TextStyle(
                      color: Color(0xFFC084FC),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (widget.recommendedSize != null)
                Text(
                  widget.recommendedSize!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),

          if (widget.helperText != null) ...[
            const SizedBox(height: 6),
            Text(
              widget.helperText!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Main Row: Live Aspect Ratio Preview Box + Upload/URL Controls
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Live Preview Box with Aspect Ratio
              Container(
                height: widget.previewHeight,
                width: widget.aspectRatio != null ? widget.previewHeight * widget.aspectRatio! : 140,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: hasImage
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            NetworkImageBox(
                              url: widget.controller.text.trim(),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () => widget.controller.clear(),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black87,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_outlined, color: Colors.white.withValues(alpha: 0.3), size: 28),
                              const SizedBox(height: 6),
                              Text(
                                'No image',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 16),

              // 2. Upload / Change / URL controls
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _uploading ? null : _pickAndUpload,
                          icon: _uploading
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.cloud_upload_outlined, size: 16),
                          label: Text(
                            _uploading
                                ? 'Uploading...'
                                : (hasImage ? 'Change Image' : 'Upload Image'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        if (hasImage) ...[
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => widget.controller.clear(),
                            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                            label: const Text('Remove', style: TextStyle(color: AppColors.error, fontSize: 12.5)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: widget.controller,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Or Paste Direct Image URL',
                        hintText: 'https://...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                      ),
                    ),
                    if (_isExternalUrl) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _uploading ? null : _saveExternalImageToServer,
                        icon: _uploading
                            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)))
                            : const Icon(Icons.download_for_offline_outlined, size: 15, color: Color(0xFF10B981)),
                        label: Text(
                          _uploading ? 'Downloading...' : '⚡ Save to Server (Permanent)',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 6),
                      Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 11.5)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

