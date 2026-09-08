import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../models/inquiry.dart';

/// "Your inquiry has been received" screen matching Figma SuccessPage.tsx.
/// Opens WhatsApp automatically using the backend-built wa.me URL, with manual fallback.
class InquirySuccessScreen extends StatefulWidget {
  final InquiryResponse inquiry;

  const InquirySuccessScreen({super.key, required this.inquiry});

  @override
  State<InquirySuccessScreen> createState() => _InquirySuccessScreenState();
}

class _InquirySuccessScreenState extends State<InquirySuccessScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openWhatsApp());
  }

  Future<void> _openWhatsApp() async {
    final url = widget.inquiry.whatsappUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inquiry = widget.inquiry;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Radial glow background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.4),
                  radius: 0.8,
                  colors: [
                    AppColors.neonPurple.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing Check Icon Circle
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neonPurple.withValues(alpha: 0.15),
                        border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.5), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonPurple.withValues(alpha: 0.3),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.check, color: AppColors.neonPurple, size: 40),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'RECEIVED',
                      style: TextStyle(
                        color: AppColors.neonPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Inquiry Received!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hey ${inquiry.customerName}, your inquiry has been submitted.',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Inquiry ID Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.neonPurple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.confirmation_number_outlined, size: 16, color: AppColors.neonPurple),
                          const SizedBox(width: 8),
                          Text(
                            inquiry.inquiryNumber,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFFC084FC),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Booking Summary Card
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Booking Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SummaryRow(label: 'Event', value: inquiry.eventName),
                          _SummaryRow(
                            label: 'Day',
                            value: inquiry.dayNumber != null ? 'Day ${inquiry.dayNumber}' : 'Full Event',
                          ),
                          _SummaryRow(label: 'Pass', value: inquiry.ticketCategoryName),
                          _SummaryRow(label: 'Quantity', value: '${inquiry.quantity}'),
                          _SummaryRow(
                            label: 'Estimated Total',
                            value: '₹${inquiry.estimatedTotal.toStringAsFixed(0)}',
                            isTotal: true,
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: AppColors.divider),
                          const SizedBox(height: 8),
                          const Text(
                            'Our team will reach out to confirm your booking. Please keep your inquiry ID ready.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.chat_bubble, size: 18),
                            label: const Text(
                              'Continue on WhatsApp',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _openWhatsApp,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => context.go('/events'),
                            child: const Text('Back to Events', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 15 : 13,
              color: isTotal ? AppColors.neonPurple : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
