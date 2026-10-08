import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/api_constants.dart';
import '../theme/app_colors.dart';
import 'network_image_box.dart';

class ShareModal extends StatefulWidget {
  final String title;
  final String slug;
  final String? imageUrl;
  final String? date;
  final String? venue;
  final String? startingPrice;

  const ShareModal({
    super.key,
    required this.title,
    required this.slug,
    this.imageUrl,
    this.date,
    this.venue,
    this.startingPrice,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String slug,
    String? imageUrl,
    String? date,
    String? venue,
    String? startingPrice,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ShareModal(
        title: title,
        slug: slug,
        imageUrl: imageUrl,
        date: date,
        venue: venue,
        startingPrice: startingPrice,
      ),
    );
  }

  @override
  State<ShareModal> createState() => _ShareModalState();
}

class _ShareModalState extends State<ShareModal> {
  bool _copied = false;

  String get _eventUrl => '${ApiConstants.publicAppUrl}/events/${widget.slug}';

  String get _shareText {
    final buffer = StringBuffer();
    buffer.writeln('🔥 Check out *${widget.title}* on VibeMyNight!');
    if (widget.date != null && widget.date!.isNotEmpty) {
      buffer.writeln('🗓️ *Date:* ${widget.date}');
    }
    if (widget.venue != null && widget.venue!.isNotEmpty) {
      buffer.writeln('📍 *Venue:* ${widget.venue}');
    }
    if (widget.startingPrice != null && widget.startingPrice!.isNotEmpty) {
      buffer.writeln('🎟️ *Passes from:* ${widget.startingPrice} (0% Convenience Fee)');
    }
    buffer.writeln('👉 Book Passes: $_eventUrl');
    return buffer.toString().trim();
  }

  Future<void> _shareWhatsApp() async {
    final url = 'https://api.whatsapp.com/send?text=${Uri.encodeComponent(_shareText)}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _shareFacebook() async {
    final url = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(_eventUrl)}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _shareTwitter() async {
    final text = '🔥 Check out ${widget.title} on @VibeMyNight! Book passes with 0% convenience fee:';
    final url = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}&url=${Uri.encodeComponent(_eventUrl)}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _shareTelegram() async {
    final url = 'https://t.me/share/url?url=${Uri.encodeComponent(_eventUrl)}&text=${Uri.encodeComponent(_shareText)}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _shareInstagram() async {
    await Clipboard.setData(ClipboardData(text: _shareText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caption & link copied! Paste in your Instagram story or message 📸'),
          duration: Duration(seconds: 3),
          backgroundColor: Color(0xFFE1306C),
        ),
      );
    }
    const url = 'https://instagram.com';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _eventUrl));
    setState(() => _copied = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event link copied to clipboard! 📋'),
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.neonPurple,
        ),
      );
    }
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF141324),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Share Event',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Event Mini Preview Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1B33),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 54,
                      height: 54,
                      child: NetworkImageBox(
                        url: widget.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (widget.date != null && widget.date!.isNotEmpty)
                          Text(
                            widget.date!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (widget.venue != null && widget.venue!.isNotEmpty)
                          Text(
                            widget.venue!,
                            style: TextStyle(
                              color: AppColors.neonPurple.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (widget.startingPrice != null && widget.startingPrice!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.neonPurple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        widget.startingPrice!,
                        style: const TextStyle(
                          color: Color(0xFFC4B5FD),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Share Options Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SocialShareButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: _shareWhatsApp,
                ),
                _SocialShareButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Instagram',
                  color: const Color(0xFFE1306C),
                  onTap: _shareInstagram,
                ),
                _SocialShareButton(
                  icon: Icons.facebook,
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  onTap: _shareFacebook,
                ),
                _SocialShareButton(
                  icon: Icons.send_rounded,
                  label: 'Telegram',
                  color: const Color(0xFF229ED9),
                  onTap: _shareTelegram,
                ),
                _SocialShareButton(
                  icon: Icons.alternate_email_rounded,
                  label: 'X (Twitter)',
                  color: const Color(0xFF1DA1F2),
                  onTap: _shareTwitter,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Copy Link Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0B17),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: Colors.white54, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _eventUrl,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _copyLink,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _copied ? const Color(0xFF10B981) : AppColors.neonPurple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _copied ? Icons.check : Icons.copy,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _copied ? 'Copied' : 'Copy',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _SocialShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
