import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/data_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/network_image_box.dart';
import '../../../models/event_day_detail.dart';
import '../../../models/event_day_summary.dart';
import '../../../models/event_detail.dart';
import '../../../models/inquiry.dart';
import '../../../models/settings.dart';
import '../../../models/ticket_category.dart';

/// High-Converting Mobile-First 2-Step Pass Booking Modal:
/// Step 1: 📅 Select Date -> Shows Nightly Artist Spotlight + Pass Type & Prices + Quantity.
/// Step 2: 👤 Enter Customer Name & Mobile -> Instant 1-Tap WhatsApp Booking & Instant UPI.
class QuickBookingModal extends ConsumerStatefulWidget {
  final EventDetail event;
  final int initialDayIndex;
  final int? initialPassId;

  const QuickBookingModal({
    super.key,
    required this.event,
    this.initialDayIndex = 0,
    this.initialPassId,
  });

  static Future<void> show(
    BuildContext context, {
    required EventDetail event,
    int initialDayIndex = 0,
    int? initialPassId,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= 700;
    if (isDesktop) {
      return showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.75),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540, maxHeight: 760),
            child: QuickBookingModal(
              event: event,
              initialDayIndex: initialDayIndex,
              initialPassId: initialPassId,
            ),
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: FractionallySizedBox(
            heightFactor: 0.94,
            child: QuickBookingModal(
              event: event,
              initialDayIndex: initialDayIndex,
              initialPassId: initialPassId,
            ),
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<QuickBookingModal> createState() => _QuickBookingModalState();
}

class _QuickBookingModalState extends ConsumerState<QuickBookingModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();

  int _currentStep = 0; // 0 = Date, Artist & Pass Selection; 1 = Customer Details & Booking
  late int _selectedDayIndex;
  int? _selectedPassId;
  int _quantity = 1;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = widget.initialDayIndex.clamp(
      0,
      widget.event.days.isNotEmpty ? widget.event.days.length - 1 : 0,
    );
    _selectedPassId = widget.initialPassId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  EventDaySummary? get _currentDaySummary {
    if (widget.event.days.isEmpty) return null;
    if (_selectedDayIndex >= widget.event.days.length) return widget.event.days.first;
    return widget.event.days[_selectedDayIndex];
  }

  String _detectCategory(EventDetail event) {
    final name = event.name.toLowerCase();
    final slug = event.slug.toLowerCase();
    if (name.contains('ac dome') || slug.contains('ac-dome')) return 'AC DOME GARBA';
    if (name.contains('garba') || name.contains('navratri') || name.contains('dandiya')) return 'POPULAR GARBA';
    if (name.contains('edm') || name.contains('dj') || name.contains('club')) return 'EDM & NIGHTLIFE';
    if (name.contains('concert') || name.contains('live')) return 'LIVE CONCERT';
    return 'PREMIUM PASS';
  }

  Map<String, String> _parseDateComponents(String dateStr) {
    try {
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final dt = DateTime.tryParse(dateStr);
          if (dt != null) {
            const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
            return {
              'weekday': weekdays[dt.weekday - 1],
              'dayMonth': '${dt.day} ${months[dt.month - 1]}',
            };
          }
        }
      }
    } catch (_) {}

    final clean = dateStr.trim();
    return {
      'weekday': 'Day ${_selectedDayIndex + 1}',
      'dayMonth': clean.isNotEmpty ? clean : 'Oct 2026',
    };
  }

  Future<void> _sendWhatsAppBooking(
    AppSettings settings,
    EventDaySummary? daySummary,
    EventDayDetail? dayDetail,
    TicketCategory? pass,
    double total,
  ) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (daySummary == null || pass == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an event date and pass type to continue.'),
          backgroundColor: AppColors.neonPink,
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();

    setState(() => _submitting = true);

    // Save inquiry to backend so admin lead management is preserved
    try {
      final req = CreateInquiryRequest(
        customerName: name,
        customerMobile: mobile,
        eventDayId: daySummary.id,
        ticketCategoryId: pass.id,
        quantity: _quantity,
      );
      await ref.read(inquiryServiceProvider).submitInquiry(req);
    } catch (_) {
      // Don't block WhatsApp launch if network has a slight delay
    } finally {
      if (mounted) setState(() => _submitting = false);
    }

    final num = settings.whatsappNumber.isNotEmpty ? settings.whatsappNumber : '917041615131';
    final cleanNum = num.replaceAll(RegExp(r'[^0-9]'), '');
    final dayText = 'Day ${daySummary.dayNumber} (${daySummary.date})';
    final artistName = dayDetail?.primaryArtist?.name ?? daySummary.primaryArtistName ?? 'Celebrity Artist & Live Orchestra';
    final passName = pass.name;
    final venue = widget.event.venue ?? widget.event.location ?? 'Ahmedabad';

    final text = 'Hi VibeMyNight! My name is $name (+91 $mobile).\n\n'
        'I want to book passes:\n'
        '🎪 *Event:* ${widget.event.name}\n'
        '📍 *Venue:* $venue\n'
        '📅 *Date:* $dayText\n'
        '🎤 *Performing Artist:* $artistName\n'
        '🎟️ *Pass Type:* $passName\n'
        '🔢 *Quantity:* $_quantity ${_quantity > 1 ? "passes" : "pass"}\n'
        '💰 *Total Amount:* ₹${total.toInt()}\n\n'
        'Please confirm my pass booking and send confirmation!';

    final uri = Uri.parse('https://api.whatsapp.com/send?phone=$cleanNum&text=${Uri.encodeComponent(text)}');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openInstantUpiPayment(
    AppSettings settings,
    EventDaySummary? daySummary,
    EventDayDetail? dayDetail,
    TicketCategory? pass,
    double totalAmount,
  ) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (daySummary == null || pass == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an event date and pass type to continue.'),
          backgroundColor: AppColors.neonPink,
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();

    setState(() => _submitting = true);

    try {
      final req = CreateInquiryRequest(
        customerName: name,
        customerMobile: mobile,
        eventDayId: daySummary.id,
        ticketCategoryId: pass.id,
        quantity: _quantity,
      );
      final inquiryResp = await ref.read(inquiryServiceProvider).submitInquiry(req);

      final upiVpa = settings.upiVpa != null && settings.upiVpa!.trim().isNotEmpty
          ? settings.upiVpa!.trim()
          : 'vibemynight@icici';
      final merchantName = settings.upiMerchantName ?? 'VibeMyNight';

      final cleanEventName = widget.event.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final note = 'VMN-${cleanEventName.substring(0, cleanEventName.length.clamp(0, 10))}-${inquiryResp.inquiryNumber}';
      final dynamicUpiUrl = 'upi://pay?pa=$upiVpa&pn=${Uri.encodeComponent(merchantName)}&am=${totalAmount.toInt()}&cu=INR&tn=${Uri.encodeComponent(note)}';

      if (!mounted) return;

      _showDynamicUpiQrDialog(
        context,
        upiVpa: upiVpa,
        upiUrl: dynamicUpiUrl,
        total: totalAmount,
        inquiryNumber: inquiryResp.inquiryNumber,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not initialize UPI: $e'),
          backgroundColor: AppColors.neonPink,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showDynamicUpiQrDialog(
    BuildContext context, {
    required String upiVpa,
    required String upiUrl,
    required double total,
    required String inquiryNumber,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF100B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.neonPurple, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.qr_code_2_rounded, color: Color(0xFF10B981), size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Scan & Pay via UPI',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 20),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.network(
                'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(upiUrl)}',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 180,
                  height: 180,
                  child: Center(child: Icon(Icons.qr_code, size: 80, color: Colors.black)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Amount to Pay: ₹${total.toInt()}',
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'UPI ID: $upiVpa',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'Ref: #$inquiryNumber • Digital passes will be confirmed & sent to WhatsApp instantly.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.phone_android, size: 16),
            label: const Text('Open UPI App'),
            onPressed: () {
              launchUrl(Uri.parse(upiUrl), mode: LaunchMode.externalApplication);
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('I Have Paid', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = settingsAsync.valueOrNull ??
        const AppSettings(
          websiteName: 'VibeMyNight',
          whatsappNumber: '917041615131',
          phone: '+91 7041615131',
          currency: 'INR',
        );

    final currentDay = _currentDaySummary;
    final category = _detectCategory(widget.event);

    // Watch day detail provider to load passes and artists for current day
    final dayDetailAsync = currentDay != null ? ref.watch(eventDayDetailProvider(currentDay.id)) : null;

    final dayDetail = dayDetailAsync?.valueOrNull;
    final passes = dayDetail?.passes ?? [];
    final primaryArtist = dayDetail?.primaryArtist;

    // Auto-select pass if not selected or invalid for this day
    TicketCategory? selectedPass;
    if (passes.isNotEmpty) {
      if (_selectedPassId != null) {
        selectedPass = passes.where((p) => p.id == _selectedPassId).firstOrNull;
      }
      selectedPass ??= passes.first;
    }

    final passPrice = selectedPass?.price ?? currentDay?.startingPrice ?? 499.0;
    final totalAmount = passPrice * _quantity;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C091C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonPurple.withValues(alpha: 0.25),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ══════════════════════════════════════════════════════════════════
              // 1. MODAL HEADER (Poster, Title, Category Pill & Close)
              // ══════════════════════════════════════════════════════════════════
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF140E2E),
                  border: Border(bottom: BorderSide(color: Color(0xFF281C54), width: 1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Back button on Step 1 to return to Step 0
                    if (_currentStep > 0) ...[
                      InkWell(
                        onTap: () => setState(() => _currentStep = 0),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                        ),
                      ),
                    ],

                    // Event Poster
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 44,
                        height: 58,
                        child: NetworkImageBox(
                          url: widget.event.mainImage ?? widget.event.thumbnail,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Event Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.6), width: 0.8),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                color: Color(0xFFFFDF78),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Event Title
                          Text(
                            widget.event.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),

                          // Venue
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.textSecondary, size: 11),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  widget.event.venue ?? widget.event.location ?? 'Ahmedabad, Gujarat',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Close Button
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white70, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              // ══════════════════════════════════════════════════════════════════
              // 2. STEPPER BREADCRUMB INDICATOR
              // ══════════════════════════════════════════════════════════════════
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F0A24),
                  border: Border(bottom: BorderSide(color: Color(0xFF221646), width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _currentStep = 0),
                      child: _buildStepPill('1', 'Date, Artist & Pass', isActive: _currentStep == 0, isDone: _currentStep > 0),
                    ),
                    _buildStepDivider(),
                    _buildStepPill('2', 'Contact & Booking', isActive: _currentStep == 1, isDone: false),
                  ],
                ),
              ),

              // ══════════════════════════════════════════════════════════════════
              // 3. STEP CONTENT BODY (MOBILE-OPTIMIZED)
              // ══════════════════════════════════════════════════════════════════
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: _currentStep == 0
                      ? _buildStep1DateArtistPass(
                          currentDay: currentDay,
                          dayDetailAsync: dayDetailAsync,
                          dayDetail: dayDetail,
                          passes: passes,
                          selectedPass: selectedPass,
                          primaryArtist: primaryArtist,
                          passPrice: passPrice,
                        )
                      : _buildStep2CustomerDetails(
                          currentDay: currentDay,
                          dayDetail: dayDetail,
                          selectedPass: selectedPass,
                          totalAmount: totalAmount,
                        ),
                ),
              ),

              // ══════════════════════════════════════════════════════════════════
              // 4. BOTTOM ACTION FOOTER
              // ══════════════════════════════════════════════════════════════════
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F0A24),
                  border: Border(top: BorderSide(color: Color(0xFF281C54), width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_currentStep == 0) ...[
                      // Step 1 Footer: Total + Next Proceed Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOTAL AMOUNT',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '₹${totalAmount.toInt()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '($_quantity ${_quantity > 1 ? "passes" : "pass"})',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              if (selectedPass == null && passes.isNotEmpty) {
                                setState(() => _selectedPassId = passes.first.id);
                              }
                              setState(() => _currentStep = 1);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Proceed to Booking',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Step 2 Footer: Dual Action WhatsApp & UPI
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payable: ₹${totalAmount.toInt()} ($_quantity passes)',
                            style: const TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          InkWell(
                            onTap: _submitting
                                ? null
                                : () => _openInstantUpiPayment(
                                      settings,
                                      currentDay,
                                      dayDetail,
                                      selectedPass,
                                      totalAmount,
                                    ),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt, color: Color(0xFF10B981), size: 13),
                                  SizedBox(width: 3),
                                  Text(
                                    'Instant UPI',
                                    style: TextStyle(
                                      color: Color(0xFF34D399),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // WhatsApp Action Button
                      InkWell(
                        onTap: _submitting
                            ? null
                            : () => _sendWhatsAppBooking(
                                  settings,
                                  currentDay,
                                  dayDetail,
                                  selectedPass,
                                  totalAmount,
                                ),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF25D366).withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _submitting ? 'Connecting WhatsApp...' : 'Send Booking Request on WhatsApp',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),
                      const Text(
                        'Pass bookings & confirmations via WhatsApp & Instant UPI',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STEP 1 WIDGET: DATE + ARTIST SPOTLIGHT + PASS & QUANTITY
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildStep1DateArtistPass({
    required EventDaySummary? currentDay,
    required AsyncValue<EventDayDetail>? dayDetailAsync,
    required EventDayDetail? dayDetail,
    required List<TicketCategory> passes,
    required TicketCategory? selectedPass,
    required dynamic primaryArtist,
    required double passPrice,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. SELECT DATE HEADER
        Row(
          children: [
            const Text(
              '1. SELECT DATE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const Spacer(),
            _buildLegendItem(const Color(0xFF10B981), 'Available'),
            const SizedBox(width: 10),
            _buildLegendItem(const Color(0xFFF97316), 'Fast filling'),
          ],
        ),
        const SizedBox(height: 8),

        // Multi-Day Selector Grid
        if (widget.event.days.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(widget.event.days.length, (index) {
              final day = widget.event.days[index];
              final isSelected = _selectedDayIndex == index;
              final dateInfo = _parseDateComponents(day.date);
              final isFastFilling = index % 3 == 0;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDayIndex = index;
                    _selectedPassId = null;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 74,
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF281C54)
                        : const Color(0xFF130D2C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF10B981)
                          : const Color(0xFF2E225C),
                      width: isSelected ? 1.8 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.35),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dateInfo['weekday']!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                color: isSelected ? const Color(0xFF34D399) : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateInfo['dayMonth']!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isFastFilling ? const Color(0xFFF97316) : const Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'All Event Dates Open for Booking',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),

        const SizedBox(height: 14),

        // 2. NIGHTLY ARTIST SPOTLIGHT
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF24164C).withValues(alpha: 0.7),
                const Color(0xFF150D30).withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF4C338A), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.neonPurple, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonPurple.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: primaryArtist?.photoUrl != null && primaryArtist!.photoUrl!.isNotEmpty
                      ? NetworkImageBox(url: primaryArtist.photoUrl, fit: BoxFit.cover)
                      : (currentDay?.primaryArtistPhotoUrl != null && currentDay!.primaryArtistPhotoUrl!.isNotEmpty)
                          ? NetworkImageBox(url: currentDay.primaryArtistPhotoUrl, fit: BoxFit.cover)
                          : Container(
                              color: const Color(0xFF38236B),
                              child: const Icon(Icons.mic_external_on, color: Color(0xFFC084FC), size: 20),
                            ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.neonPurple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '⭐ TONIGHT\'S ARTIST',
                            style: TextStyle(
                              color: Color(0xFFE9D5FF),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '• 8:00 PM Live',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      primaryArtist?.name ?? currentDay?.primaryArtistName ?? 'Celebrity Artist & Live Orchestra',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 3. SELECT PASS TYPE
        const Text(
          '2. SELECT PASS TYPE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 7),

        if (passes.isNotEmpty)
          Column(
            children: passes.map((pass) {
              final isSelected = selectedPass?.id == pass.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPassId = pass.id;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF22164A)
                          : const Color(0xFF130D28),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF10B981)
                            : const Color(0xFF2D2056),
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : AppColors.textSecondary,
                          size: 17,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pass.name,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontSize: 13.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                ),
                              ),
                              if (pass.description != null && pass.description!.isNotEmpty)
                                Text(
                                  pass.description!,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${pass.price.toInt()}',
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF34D399) : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          )
        else if (dayDetailAsync?.isLoading ?? false)
          Container(
            padding: const EdgeInsets.all(14),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.neonPurple, strokeWidth: 2),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1C133C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.radio_button_checked, color: Color(0xFF10B981), size: 17),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'General Entry Pass',
                    style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '₹${passPrice.toInt()}',
                  style: const TextStyle(color: Color(0xFF34D399), fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // 4. NUMBER OF PASSES QUANTITY
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF140E2C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF281C54)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Number of Passes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  _buildQtyBtn(
                    icon: Icons.remove,
                    onTap: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _buildQtyBtn(
                    icon: Icons.add,
                    onTap: _quantity < 10
                        ? () => setState(() => _quantity++)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STEP 2 WIDGET: SUMMARY + CUSTOMER CONTACT DETAILS
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildStep2CustomerDetails({
    required EventDaySummary? currentDay,
    required EventDayDetail? dayDetail,
    required TicketCategory? selectedPass,
    required double totalAmount,
  }) {
    final dayText = currentDay != null ? 'Day ${currentDay.dayNumber} · ${currentDay.date}' : 'Selected Date';
    final artistName = dayDetail?.primaryArtist?.name ?? currentDay?.primaryArtistName ?? 'Celebrity Artist';
    final passName = selectedPass?.name ?? 'Standard Pass';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mini Order Confirmation Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                const Color(0xFFEC4899).withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Color(0xFFC084FC), size: 14),
                      const SizedBox(width: 5),
                      Text(
                        dayText,
                        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    '₹${totalAmount.toInt()}',
                    style: const TextStyle(color: Color(0xFF34D399), fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.mic, color: Color(0xFFE9D5FF), size: 12),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Artist: $artistName',
                      style: const TextStyle(color: Color(0xFFE9D5FF), fontSize: 11.5, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.confirmation_num_outlined, color: Colors.white70, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Pass: $passName × $_quantity passes',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Customer Inputs Card
        const Text(
          'ENTER CONTACT DETAILS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF140E2C),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF281C54)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full Name
              const Text(
                'Your Full Name *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'e.g. Rahul Sharma',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(Icons.person_outline, size: 18, color: Color(0xFFC084FC)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  filled: true,
                  fillColor: const Color(0xFF0F0A22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2E2055)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2E2055)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
              ),
              const SizedBox(height: 12),

              // WhatsApp Mobile Number
              const Text(
                'WhatsApp Mobile Number *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  hintText: '9876543210',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(Icons.phone_android_outlined, size: 18, color: Color(0xFF34D399)),
                  prefixText: '+91 ',
                  prefixStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  filled: true,
                  fillColor: const Color(0xFF0F0A22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2E2055)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2E2055)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                  ),
                ),
                validator: (v) => (v == null || v.trim().length != 10) ? 'Enter valid 10-digit mobile number' : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepPill(String num, String label, {required bool isActive, required bool isDone}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? const Color(0xFF10B981)
                : (isDone ? const Color(0xFF8B5CF6) : Colors.white24),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 11, color: Colors.white)
                : Text(
                    num,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : (isDone ? const Color(0xFFC084FC) : AppColors.textSecondary),
            fontSize: 11,
            fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 14,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.white24,
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
        ),
      ],
    );
  }

  Widget _buildQtyBtn({required IconData icon, VoidCallback? onTap}) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isEnabled ? const Color(0xFF281C54) : Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled ? const Color(0xFF4C358A) : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          color: isEnabled ? Colors.white : Colors.white30,
          size: 15,
        ),
      ),
    );
  }
}
