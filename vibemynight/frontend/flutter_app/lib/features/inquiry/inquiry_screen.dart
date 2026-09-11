import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/data_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_navbar.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../models/inquiry.dart';

/// Streamlined, Zero-Scroll Fast Booking & Inquiry Form:
/// - Fits completely within mobile viewport without tedious vertical scrolling.
/// - Clear booking summary pill with Day, Pass Name & Total.
/// - Clean Full Name & WhatsApp Number inputs.
/// - Inline Quantity +/- counter with live price computation.
/// - Collapsible optional fields (Email / Note) to preserve compact layout.
/// - Direct 1-Tap "Submit Inquiry" & "Book on WhatsApp" actions.
class InquiryScreen extends ConsumerStatefulWidget {
  final int eventDayId;
  final int ticketCategoryId;
  final int initialQuantity;

  const InquiryScreen({
    super.key,
    required this.eventDayId,
    required this.ticketCategoryId,
    this.initialQuantity = 1,
  });

  @override
  ConsumerState<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends ConsumerState<InquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  late int _quantity;
  bool _showOptionalFields = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity > 0 ? widget.initialQuantity : 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final request = CreateInquiryRequest(
        customerName: _nameController.text.trim(),
        customerMobile: _mobileController.text.trim(),
        customerEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        eventDayId: widget.eventDayId,
        ticketCategoryId: widget.ticketCategoryId,
        quantity: _quantity,
        message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
      );
      final response = await ref.read(inquiryServiceProvider).submitInquiry(request);
      if (!mounted) return;
      context.push('/inquiry/success', extra: response);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openWhatsAppDirect(String? whatsappNumber, String dayText, String passText, double total) {
    final num = whatsappNumber ?? '917041615131';
    final cleanNum = num.replaceAll(RegExp(r'[^0-9]'), '');
    final name = _nameController.text.trim();
    final namePart = name.isNotEmpty ? 'My name is $name. ' : '';
    final text = 'Hi VibeMyNight! $namePart'
        'I want to book *$passText* ($dayText) for *$_quantity passes* (Est. Total: ₹${total.toInt()}). '
        'Please confirm availability & payment link!';
    final uri = Uri.parse('https://api.whatsapp.com/send?phone=$cleanNum&text=${Uri.encodeComponent(text)}');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final dayAsync = ref.watch(eventDayDetailProvider(widget.eventDayId));
    final settingsAsync = ref.watch(appSettingsProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFF07070E),
      appBar: const AppNavbar(currentRoute: '/events'),
      bottomNavigationBar: isDesktop ? null : const AppBottomNav(currentRoute: '/events'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: isDesktop ? 28 : 12,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Back & Header Bar
                    Row(
                      children: [
                        InkWell(
                          onTap: () => context.pop(),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'QUICK PASS INQUIRY',
                                style: TextStyle(
                                  color: Color(0xFFA855F7),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                'Confirm Your Pass',
                                style: TextStyle(
                                  fontSize: isDesktop ? 22 : 19,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Compact Booking Summary Card
                    dayAsync.maybeWhen(
                      data: (day) {
                        final category = day.passes.where((p) => p.id == widget.ticketCategoryId).firstOrNull ??
                            (day.passes.isNotEmpty ? day.passes.first : null);
                        final passName = category?.name ?? 'Standard Pass';
                        final passPrice = category?.price ?? 499.0;
                        final estimatedTotal = passPrice * _quantity;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF8B5CF6).withValues(alpha: 0.16),
                                const Color(0xFFEC4899).withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_month, color: Color(0xFFC084FC), size: 13),
                                            const SizedBox(width: 5),
                                            Text(
                                              'Day ${day.dayNumber} · ${day.date}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          passName,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.75),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${passPrice.toInt()} / pass',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 10.5,
                                        ),
                                      ),
                                      Text(
                                        '₹${estimatedTotal.toInt()}',
                                        style: const TextStyle(
                                          color: Color(0xFFF43F5E),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 14),

                    // Main Glass Input Container
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Full Name
                          const Text(
                            'Full Name *',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'e.g. Rahul Sharma',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                              prefixIcon: const Icon(Icons.person_outline, size: 18, color: Color(0xFFC084FC)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.04),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFA855F7), width: 1.5),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                          ),
                          const SizedBox(height: 12),

                          // 2. Mobile Number (WhatsApp)
                          const Text(
                            'WhatsApp Mobile Number *',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: '10-digit mobile number',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                              prefixIcon: const Icon(Icons.phone_iphone, size: 18, color: Color(0xFF25D366)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.04),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                              ),
                            ),
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.isEmpty) return 'Mobile number is required';
                              final digits = value.replaceAll(RegExp(r'\D'), '');
                              if (digits.length < 10) return 'Enter valid 10-digit number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // 3. Inline Quantity Selector & Total
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Quantity',
                                  style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                                      icon: Icon(
                                        Icons.remove_circle_outline,
                                        color: _quantity > 1 ? const Color(0xFFC084FC) : Colors.white24,
                                        size: 22,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$_quantity',
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white),
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      onPressed: () => setState(() => _quantity++),
                                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFFC084FC), size: 22),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // 4. Expandable Optional Fields (Email & Message)
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => setState(() => _showOptionalFields = !_showOptionalFields),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    _showOptionalFields ? Icons.keyboard_arrow_up : Icons.add_circle_outline,
                                    size: 14,
                                    color: const Color(0xFFC084FC),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _showOptionalFields ? 'Hide optional details' : '+ Add Email or Special Note (Optional)',
                                    style: const TextStyle(
                                      color: Color(0xFFC084FC),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (_showOptionalFields) ...[
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Email Address (optional)',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                                prefixIcon: const Icon(Icons.email_outlined, size: 16, color: Colors.white54),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.04),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _messageController,
                              maxLines: 2,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Any special requests or VIP table inquiry...',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.04),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      ErrorView(message: _error!),
                    ],
                    const SizedBox(height: 14),

                    // Primary Submit Button
                    GradientButton(
                      label: 'Submit Instant Inquiry',
                      isLoading: _submitting,
                      onPressed: _submit,
                      height: 48,
                    ),
                    const SizedBox(height: 10),

                    // Direct WhatsApp 1-Tap Option
                    dayAsync.maybeWhen(
                      data: (day) {
                        final category = day.passes.where((p) => p.id == widget.ticketCategoryId).firstOrNull ??
                            (day.passes.isNotEmpty ? day.passes.first : null);
                        final passName = category?.name ?? 'Standard Pass';
                        final passPrice = category?.price ?? 499.0;
                        final total = passPrice * _quantity;

                        return OutlinedButton.icon(
                          onPressed: () => _openWhatsAppDirect(
                            settingsAsync.value?.whatsappNumber,
                            'Day ${day.dayNumber} (${day.date})',
                            passName,
                            total,
                          ),
                          icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 16),
                          label: const Text(
                            'Book Directly via WhatsApp',
                            style: TextStyle(
                              color: Color(0xFF25D366),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF25D366), width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 10),

                    // Trust Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified, size: 12, color: Color(0xFF60A5FA)),
                        const SizedBox(width: 4),
                        Text(
                          '100% Genuine · Instant Confirmation · Zero Extra Fee',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
