import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Network image with rounded corners, a loading state, and a graceful
/// fallback box (never a broken-image icon) when [url] is null/empty or
/// fails to load - covers the "no fake functionality" spirit for
/// still-empty admin-uploaded image fields during early data entry.
class NetworkImageBox extends StatelessWidget {
  final String? url;
  final double? height;
  final double? width;
  final BorderRadius borderRadius;
  final BoxFit fit;

  const NetworkImageBox({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _fallback();
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        url!,
        height: height,
        width: width,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _fallback(loading: true);
        },
        errorBuilder: (context, error, stack) => _fallback(),
      ),
    );
  }

  Widget _fallback({bool loading = false}) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        height: height,
        width: width,
        color: AppColors.surface,
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.image_outlined, color: AppColors.textSecondary),
      ),
    );
  }
}
