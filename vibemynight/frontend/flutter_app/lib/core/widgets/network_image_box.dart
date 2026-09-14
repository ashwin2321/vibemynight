import 'package:flutter/material.dart';

import '../constants/api_constants.dart';
import '../theme/app_colors.dart';

/// Network image with rounded corners, progressive loading state,
/// and graceful fallback (never broken-image icon or plain blank box).
class NetworkImageBox extends StatelessWidget {
  final String? url;
  final String? fallbackUrl;
  final double? height;
  final double? width;
  final BorderRadius borderRadius;
  final BoxFit fit;

  const NetworkImageBox({
    super.key,
    required this.url,
    this.fallbackUrl,
    this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.fit = BoxFit.cover,
  });

  static const List<String> defaultEventPosters = [
    'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&fit=crop&auto=format',
    'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800&fit=crop&auto=format',
    'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800&fit=crop&auto=format',
    'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=800&fit=crop&auto=format',
  ];

  static String? resolveUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final clean = raw.trim();
    if (clean.startsWith('/')) {
      final base = ApiConstants.baseUrl.replaceAll('/api/v1', '');
      return '$base$clean';
    }
    return clean;
  }

  @override
  Widget build(BuildContext context) {
    final rawUrl = (url != null && url!.trim().isNotEmpty)
        ? url!.trim()
        : (fallbackUrl != null && fallbackUrl!.trim().isNotEmpty ? fallbackUrl!.trim() : null);

    final effectiveUrl = resolveUrl(rawUrl);

    if (effectiveUrl == null) {
      return _renderStylizedFallback();
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        effectiveUrl,
        height: height,
        width: width,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _renderLoadingState();
        },
        errorBuilder: (context, error, stack) {
          if (fallbackUrl != null && fallbackUrl != effectiveUrl) {
            return Image.network(
              fallbackUrl!,
              height: height,
              width: width,
              fit: fit,
              errorBuilder: (_, __, ___) => _renderStylizedFallback(),
            );
          }
          return _renderStylizedFallback();
        },
      ),
    );
  }

  Widget _renderLoadingState() {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        height: height,
        width: width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF140E28), Color(0xFF1F163D), Color(0xFF140E28)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.neonPurple,
          ),
        ),
      ),
    );
  }

  Widget _renderStylizedFallback() {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1F1235),
              Color(0xFF110B22),
              Color(0xFF0D0819),
            ],
          ),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFA855F7).withValues(alpha: 0.12),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.nightlife_rounded,
                  color: Color(0xFFC084FC),
                  size: 32,
                ),
                const SizedBox(height: 6),
                Text(
                  'VIBEMYNIGHT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
