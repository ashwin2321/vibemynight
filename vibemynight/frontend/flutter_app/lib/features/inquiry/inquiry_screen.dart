import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/data_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_footer.dart';
import '../../core/widgets/app_navbar.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../models/inquiry.dart';

/// Full Name / Mobile / Email(optional) / Quantity / Message form matching Figma InquiryPage.tsx.
/// On submit, saves the inquiry via the backend (which computes price/total itself) then
/// routes to the success screen with the server response.
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

  @override
  Widget build(BuildContext context) {
    final dayAsync = ref.watch(eventDayDetailProvider(widget.eventDayId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppNavbar(currentRoute: '/events'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PASS INQUIRY',
                          style: TextStyle(
                            color: AppColors.neonPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Almost There',
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Fill in your details and we will confirm your booking via WhatsApp.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                        ),
                        const SizedBox(height: 28),

                        // Booking Summary Preview Card
                        dayAsync.maybeWhen(
                          data: (day) {
                            final category = day.passes.where((p) => p.id == widget.ticketCategoryId).firstOrNull ??
                                (day.passes.isNotEmpty ? day.passes.first : null);
                            final passName = category?.name ?? 'Standard Pass';
                            final passPrice = category?.price ?? 999.0;
                            final estimatedTotal = passPrice * _quantity;
                            return GlassCard(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Inquiry Summary',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Day & Date', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                            const SizedBox(height: 2),
                                            Text('Day ${day.dayNumber} · ${day.date}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Pass Type', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                            const SizedBox(height: 2),
                                            Text(passName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Quantity', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                            const SizedBox(height: 2),
                                            Text('$_quantity passes', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Estimated Total', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                            const SizedBox(height: 2),
                                            Text('₹${estimatedTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.neonPurple, fontSize: 16)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                          orElse: () => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 28),

                        // Full Name
                        const Text('Full Name *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(hintText: 'e.g. Rahul Sharma'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                        ),
                        const SizedBox(height: 20),

                        // Mobile Number
                        const Text('Mobile Number (WhatsApp) *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(hintText: '10-digit mobile number (e.g. 9876543210)'),
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) return 'Mobile number is required';
                            if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                              return 'Enter a valid 10-digit Indian mobile number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Email Address
                        const Text('Email Address (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(hintText: 'your@email.com'),
                        ),
                        const SizedBox(height: 20),

                        // Quantity Selector
                        const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceGlass,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Number of Passes', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.neonPurple),
                                  ),
                                  Text(
                                    '$_quantity',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                  ),
                                  IconButton(
                                    onPressed: () => setState(() => _quantity++),
                                    icon: const Icon(Icons.add_circle_outline, color: AppColors.neonPurple),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Message / Notes
                        const Text('Message (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _messageController,
                          maxLines: 3,
                          decoration: const InputDecoration(hintText: 'Any special requirements or questions...'),
                        ),
                        const SizedBox(height: 20),

                        // Note on payment
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: AppColors.neonBlue),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your inquiry will be saved and our team will contact you on WhatsApp for confirmation. No payment is required at this step.',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (_error != null) ...[
                          ErrorView(message: _error!),
                          const SizedBox(height: 16),
                        ],

                        GradientButton(
                          label: 'Submit Inquiry',
                          isLoading: _submitting,
                          onPressed: _submit,
                          height: 52,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}
