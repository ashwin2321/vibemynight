import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/data_providers.dart';
import '../../core/providers/dome_layout_provider.dart';
import '../../core/providers/service_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_footer.dart';
import '../../core/widgets/app_navbar.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/network_image_box.dart';
import '../../models/event_day_detail.dart';
import '../../models/event_detail.dart';
import '../../models/settings.dart';
import '../../models/ticket_category.dart';
import 'widgets/interactive_venue_layout_map.dart';

/// District.in & Showmates-inspired Modern Event Details Screen:
/// - 16:9 Clean Hero Banner with quick Share & Favorite actions
/// - Dynamic Category Tags & Live Engagement / Views counter
/// - Event Title & Rich Metadata (Dates, Venue, Organizer)
/// - Featured Headliner Artist Spotlight Card (District.in signature)
/// - Dynamic "Things to Know" Specifications Grid (Language, Duration, Dome Type, Age, Parking)
/// - About Event, Highlights Chips & Interactive Photo Gallery
/// - Multi-Day Horizontal Calendar Strip ("Choose Your Night")
/// - Selected Night Lineup & District-style Ticket Tier Cards
/// - Sticky Sidebar on Desktop with 0% convenience fee & trust badges
/// - Persistent Floating Bottom Bar on Mobile for 1-tap booking
class EventDetailsScreen extends ConsumerStatefulWidget {
  final String slug;

  const EventDetailsScreen({super.key, required this.slug});

  @override
  ConsumerState<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends ConsumerState<EventDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _daySectionKey = GlobalKey();

  int _selectedDayIndex = 0;
  final Map<int, int> _selectedQuantities = {}; // passId -> quantity
  int? _selectedPassId; // Fallback for single stand / dome view
  int _activeGalleryIndex = 0;
  bool _rulesExpanded = false;
  int? _openFaqIndex;

  int _getQuantity(int passId) => _selectedQuantities[passId] ?? 0;

  void _setQuantity(int passId, int qty, {int maxPerCustomer = 10, int availableQuantity = 100}) {
    setState(() {
      final maxLimit = (maxPerCustomer > 0 && maxPerCustomer < availableQuantity)
          ? maxPerCustomer
          : (availableQuantity > 0 ? availableQuantity : 100);
      final validQty = qty.clamp(0, maxLimit);
      if (validQty > 0) {
        _selectedQuantities[passId] = validQty;
        _selectedPassId = passId;
      } else {
        _selectedQuantities.remove(passId);
        if (_selectedPassId == passId) {
          _selectedPassId = _selectedQuantities.isNotEmpty ? _selectedQuantities.keys.first : null;
        }
      }
    });
  }

  int get _totalPassesCount => _selectedQuantities.values.fold(0, (sum, q) => sum + q);

  double _calculateTotal(List<TicketCategory> passes) {
    double total = 0.0;
    for (final p in passes) {
      final q = _getQuantity(p.id);
      if (q > 0) {
        total += p.price * q;
      }
    }
    return total;
  }

  static const _faqs = [
    {
      'q': 'Is this event family friendly?',
      'a': 'Yes, families and children are welcome. A dedicated family seating zone and security are available.',
    },
    {
      'q': 'What is the dress code?',
      'a': 'Traditional attire (Chaniya Choli / Kurta Pajama / Kediya) is preferred for Garba nights.',
    },
    {
      'q': 'How does pass confirmation work?',
      'a': 'After submitting your inquiry, our team connects with you on WhatsApp within minutes to confirm your passes and deliver your digital QR pass.',
    },
    {
      'q': 'Is parking & food available at the venue?',
      'a': 'Yes, managed 4-wheeler and 2-wheeler parking is available along with authentic live food counters.',
    },
    {
      'q': 'Can I transfer or cancel my pass?',
      'a': 'Passes are non-refundable but can be transferred to a friend by contacting our support before event day.',
    },
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _shareEvent(EventDetail event) {
    Clipboard.setData(ClipboardData(text: 'https://vibemynight.com/events/${event.slug}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard! 📋'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.neonPurple,
      ),
    );
  }

  void _openWhatsApp(String? number, EventDetail event, EventDayDetail? day, List<TicketCategory> passes) {
    final num = number ?? '917041615131';
    final cleanNum = num.length == 10 ? '91$num' : num;
    final dayText = day != null ? 'Day ${day.dayNumber} (${day.date})' : '';

    final selectedLines = <String>[];
    double total = 0.0;
    if (day != null) {
      for (final p in passes) {
        final q = _getQuantity(p.id);
        if (q > 0) {
          final itemTotal = p.price * q;
          total += itemTotal;
          selectedLines.add('- ${p.name} x $q (₹${itemTotal.toInt()})');
        }
      }
    }

    String passText = '';
    if (selectedLines.isNotEmpty) {
      passText = ':\n${selectedLines.join('\n')}\n*Estimated Total: ₹${total.toInt()}*';
    } else if (day != null && day.passes.isNotEmpty) {
      passText = ' (Pass: ${day.passes.first.name})';
    }

    final text = 'Hi VibeMyNight team, I want to book passes for *${event.name}* $dayText$passText.\nPlease confirm availability and share payment details!';
    final url = 'https://api.whatsapp.com/send?phone=$cleanNum&text=${Uri.encodeComponent(text)}';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _proceedToInquiry(EventDetail event, EventDayDetail day, List<TicketCategory> passes) {
    if (_totalPassesCount == 0) {
      if (passes.isNotEmpty) {
        // Auto-select 1 pass of the first available tier
        _setQuantity(passes.first.id, 1, maxPerCustomer: passes.first.maxPerCustomer, availableQuantity: passes.first.availableQuantity);
      } else {
        _scrollToDaySection();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least 1 pass first!'),
            backgroundColor: AppColors.neonPink,
          ),
        );
        return;
      }
    }

    // Find the first selected pass ID and total quantity for route parameter backwards compatibility
    int primaryPassId = passes.isNotEmpty ? passes.first.id : 1;
    int primaryQty = 1;
    for (final p in passes) {
      final q = _getQuantity(p.id);
      if (q > 0) {
        primaryPassId = p.id;
        primaryQty = q;
        break;
      }
    }

    context.push(
      '/inquiry?eventDayId=${day.id}&ticketCategoryId=$primaryPassId&quantity=$primaryQty',
    );
  }

  Future<void> _showUpiPaymentDialog(EventDetail event, EventDayDetail day, List<TicketCategory> passes, AppSettings settings) async {
    if (_totalPassesCount == 0) {
      if (passes.isNotEmpty) {
        _setQuantity(passes.first.id, 1, maxPerCustomer: passes.first.maxPerCustomer, availableQuantity: passes.first.availableQuantity);
      } else {
        _scrollToDaySection();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least 1 pass first!'),
            backgroundColor: AppColors.neonPink,
          ),
        );
        return;
      }
    }

    final totalAmount = _calculateTotal(passes);
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F0B1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool isInitiating = false;
        String? initError;

        return StatefulBuilder(
          builder: (_, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF10B981), size: 22),
                            SizedBox(width: 10),
                            Text(
                              'Instant Online UPI Payment',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1336),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF38296B)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${event.name} (Day ${day.dayNumber})',
                                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '₹${totalAmount.toInt()}',
                                style: const TextStyle(color: Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          const Divider(color: Color(0xFF2E2452), height: 16),
                          ...passes.where((p) => _getQuantity(p.id) > 0).map((p) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${p.name} × ${_getQuantity(p.id)}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                    Text('₹${(p.price * _getQuantity(p.id)).toInt()}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number *',
                        prefixIcon: Icon(Icons.phone_android_outlined, size: 20),
                        prefixText: '+91 ',
                      ),
                      validator: (v) => (v == null || v.trim().length != 10) ? 'Enter valid 10-digit mobile' : null,
                    ),
                    if (initError != null) ...[
                      const SizedBox(height: 12),
                      Text(initError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: isInitiating
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() {
                                  isInitiating = true;
                                  initError = null;
                                });
                                try {
                                  final res = await ref.read(paymentServiceProvider).initiateUpi(
                                    eventId: event.id,
                                    eventDayId: day.id,
                                    selectedQuantities: _selectedQuantities,
                                    customerName: nameController.text.trim(),
                                    customerMobile: mobileController.text.trim(),
                                  );

                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                  // Launch UPI URL on device
                                  final uri = Uri.parse(res.upiUrl);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }

                                  // Show post-initiation confirmation & WhatsApp delivery dialog
                                  if (!mounted) return;
                                  showDialog(
                                    context: context,
                                    builder: (dCtx) => AlertDialog(
                                          backgroundColor: const Color(0xFF130E26),
                                          title: const Row(
                                            children: [
                                              Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
                                              SizedBox(width: 10),
                                              Text('Payment Initiated', style: TextStyle(color: Colors.white, fontSize: 16)),
                                            ],
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Txn Ref: ${res.transactionReference}',
                                                style: const TextStyle(color: Color(0xFFF472B6), fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Total: ₹${res.totalAmount.toInt()} to ${res.upiVpa}',
                                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                              ),
                                              const SizedBox(height: 12),
                                              const Text(
                                                'Status: INITIATED. Please complete payment in your UPI app and share confirmation on WhatsApp for instant QR delivery.',
                                                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(dCtx),
                                              child: const Text('Close'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
                                              onPressed: () {
                                                Navigator.pop(dCtx);
                                                _openWhatsApp(settings.whatsappNumber, event, day, passes);
                                              },
                                              child: const Text('Open WhatsApp'),
                                            ),
                                          ],
                                        ),
                                      );
                                } catch (e) {
                                  setModalState(() {
                                    initError = e.toString();
                                    isInitiating = false;
                                  });
                                }
                              },
                        child: isInitiating
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('PAY VIA UPI APP (GPAY / PHONEPE)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _scrollToDaySection() {
    final context = _daySectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.slug));
    final settingsAsync = ref.watch(appSettingsProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 992;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: isDesktop
          ? null
          : eventAsync.maybeWhen(
              data: (event) {
                final days = event.days;
                final selectedDaySummary = days.isNotEmpty && _selectedDayIndex < days.length
                    ? days[_selectedDayIndex]
                    : null;
                if (selectedDaySummary == null) return null;

                return _buildMobileBottomBar(
                  context,
                  event,
                  selectedDaySummary.id,
                  settingsAsync.value?.whatsappNumber,
                );
              },
              orElse: () => null,
            ),
      body: eventAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(eventDetailProvider(widget.slug)),
        ),
        data: (event) {
          final days = event.days;
          final selectedDaySummary = days.isNotEmpty && _selectedDayIndex < days.length
              ? days[_selectedDayIndex]
              : null;

          if (isDesktop) {
            return Column(
              children: [
                // Global App Navbar (Fixed at top of screen)
                const AppNavbar(),

                // Desktop 2-Column Split: Left scrolls, Right Sidebar stays 100% Sticky in viewport!
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1360),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Main Scrollable Column
                            Expanded(
                              flex: 66,
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                padding: const EdgeInsets.only(right: 20, bottom: 60),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildBreadcrumb(context, event),
                                    const SizedBox(height: 8),
                                    _buildLeftColumn(context, event, selectedDaySummary?.id),
                                    const SizedBox(height: 60),
                                    const AppFooter(),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Right Sticky Pass Summary Sidebar (STATIONARY IN VIEWPORT)
                            SizedBox(
                              width: 380,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(top: 8, bottom: 20),
                                child: _buildStickySidebar(
                                  context,
                                  event,
                                  selectedDaySummary?.id,
                                  settingsAsync.value?.whatsappNumber,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Mobile View (Single scroll with bottom floating bar)
          return SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppNavbar(),
                _buildBreadcrumb(context, event),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _buildLeftColumn(context, event, selectedDaySummary?.id),
                      const SizedBox(height: 32),
                      _buildStickySidebar(
                        context,
                        event,
                        selectedDaySummary?.id,
                        settingsAsync.value?.whatsappNumber,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                const AppFooter(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBreadcrumb(BuildContext context, EventDetail event) {
    final isDesktop = MediaQuery.of(context).size.width >= 992;
    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => context.go('/events'),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_new, size: 13, color: AppColors.textSecondary),
                        SizedBox(width: 6),
                        Text('Events', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const Text('  /  ', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                Text(
                  event.name,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            // Step Indicators Matching Mockup
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF130E26),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2B2050)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('VibeMyNight (VMN)', style: TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.w900, fontSize: 11)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white38),
                  const SizedBox(width: 8),
                  const Text('1. Select Night', style: TextStyle(color: Color(0xFFD8B4FE), fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white38),
                  const SizedBox(width: 8),
                  Text(
                    '2. Choose Passes',
                    style: TextStyle(
                      color: _totalPassesCount > 0 ? AppColors.neonPink : Colors.white60,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white38),
                  const SizedBox(width: 8),
                  const Text('3. Confirm', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.go('/events'),
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios_new, size: 13, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Text('Events', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const Text('  /  ', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Expanded(
            child: Text(
              event.name,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 18, color: AppColors.neonPink),
            onPressed: () => _shareEvent(event),
            tooltip: 'Share Event',
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LEFT COLUMN (District.in & Showmates Layout)
  // ==========================================
  Widget _buildLeftColumn(BuildContext context, EventDetail event, int? currentDayId) {
    // Dynamic views count grounded on event ID
    final viewsCount = '${(14.2 + (event.id * 2.3) % 18).toStringAsFixed(1)}K interested';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Adaptive Banner supporting both wide 16:9 banners and vertical/square 3:4 posters seamlessly
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.width >= 992 ? 460 : 280,
                  minHeight: 180,
                ),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF15102A),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Blurred ambient backdrop for vertical/square posters
                    Positioned.fill(
                      child: Image.network(
                        NetworkImageBox.resolveUrl(event.banner ?? event.mainImage) ?? '',
                        fit: BoxFit.cover,
                        cacheWidth: 800,
                        cacheHeight: 450,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.65),
                      ),
                    ),
                    // Centered crisp image without cropping faces/logos/dates
                    Image.network(
                      NetworkImageBox.resolveUrl(event.banner ?? event.mainImage) ?? '',
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF15102A),
                        alignment: Alignment.center,
                        child: const Icon(Icons.celebration, color: AppColors.neonPurple, size: 48),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.neonPurple),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Minimal Share Button in Top Right
            Positioned(
              top: 14,
              right: 14,
              child: InkWell(
                onTap: () => _shareEvent(event),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.share_outlined, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Below-Banner Category Chips & Live Views Row (District.in Signature)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCategoryBadge('Garba Festival'),
                _buildCategoryBadge('Live Music'),
                if (event.name.toLowerCase().contains('ac dome') || (event.venue?.toLowerCase().contains('dome') ?? false))
                  _buildCategoryBadge('AC Dome'),
                if (event.city != null) _buildCategoryBadge(event.city!),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceGlass,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                mainAxisSize: dynamicViewsIconSize(),
                children: [
                  const Text('🔥 ', style: TextStyle(fontSize: 12)),
                  Text(viewsCount, style: const TextStyle(color: AppColors.neonPink, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Event Title
        Text(
          event.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 14),

        // Quick Meta Summary (Dates, Venue, Organizer)
        Wrap(
          spacing: 20,
          runSpacing: 10,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month, size: 18, color: AppColors.neonPink),
                const SizedBox(width: 6),
                Text(
                  '${event.startDate} → ${event.endDate}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (event.venue != null || event.location != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 18, color: AppColors.neonBlue),
                  const SizedBox(width: 6),
                  Text(
                    event.venue ?? event.location ?? 'Venue TBA',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            if (event.organizer != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, size: 18, color: AppColors.neonPurple),
                  const SizedBox(width: 6),
                  Text(
                    'By ${event.organizer!}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
          ],
        ),

        // Featured Headliner Artist Spotlight (District.in Featured Card)
        if (currentDayId != null)
          _buildHeadlinerSpotlight(context, currentDayId),

        const SizedBox(height: 28),

        // Dynamic "Things to Know" Specifications Grid (Showmates & District Style)
        _buildDynamicThingsToKnow(event),

        const SizedBox(height: 32),

        // About The Event Section
        if (event.description != null && event.description!.isNotEmpty) ...[
          const Text('About The Event', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.3)),
          const SizedBox(height: 12),
          Text(
            event.description!,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.65),
          ),
          const SizedBox(height: 28),
        ],

        // Highlights Badges
        if (event.highlights.isNotEmpty) ...[
          const Text('Event Highlights', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: event.highlights.map((h) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.neonPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✦ ', style: TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(h, style: const TextStyle(color: Color(0xFFD8B4FE), fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],

        // Interactive Gallery (if available)
        if (event.galleryImageUrls.isNotEmpty) ...[
          const Text('Gallery', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: NetworkImageBox(
                url: event.galleryImageUrls[_activeGalleryIndex.clamp(0, event.galleryImageUrls.length - 1)],
                height: double.infinity,
                width: double.infinity,
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: event.galleryImageUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final isSelected = idx == _activeGalleryIndex;
                return GestureDetector(
                  onTap: () => setState(() => _activeGalleryIndex = idx),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.neonPink : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Opacity(
                      opacity: isSelected ? 1.0 : 0.6,
                      child: NetworkImageBox(url: event.galleryImageUrls[idx], height: 64, width: 64),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 36),
        ],

        // ==========================================
        // CHOOSE YOUR NIGHT (Day Selector Strip)
        // ==========================================
        Container(key: _daySectionKey),
        const Text(
          'Choose Your Night',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select a night to view performing lineup and available pass tiers.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),

        if (event.days.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceGlass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.neonBlue, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Day-wise artist schedule & pass categories are being finalized. Chat on WhatsApp for priority booking assistance!',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          )
        else ...[
          // Horizontal Day Selector Strip
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(event.days.length, (idx) {
                final d = event.days[idx];
                final isSelected = idx == _selectedDayIndex;

                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() {
                      _selectedDayIndex = idx;
                      _selectedPassId = null;
                      _selectedQuantities.clear();
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : const Color(0xFF16102E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFF472B6) : const Color(0xFF2E2452),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFEC4899).withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.neonPurple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'DAY ${d.dayNumber}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isSelected ? Colors.white : AppColors.neonPink,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            d.date,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 24),

          // Selected Day Live Details, Artists & Passes
          if (currentDayId != null)
            _buildDayLiveContent(context, currentDayId, event),
        ],

        const SizedBox(height: 40),

        // Venue & Map Card
        const Text('Venue & Location', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        const SizedBox(height: 12),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.venue ?? 'Grand Arena', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(event.address ?? event.location ?? 'Ahmedabad, Gujarat', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                if (event.googleMapsUrl != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonBlue.withValues(alpha: 0.2),
                      foregroundColor: AppColors.neonBlue,
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.directions, size: 16),
                    label: const Text('Get Directions'),
                    onPressed: () => launchUrl(Uri.parse(event.googleMapsUrl!), mode: LaunchMode.externalApplication),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Facilities Tags
        if (event.facilities.isNotEmpty) ...[
          const Text('Facilities Available', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: event.facilities.map((f) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGlass,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(f.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],

        // Event Rules Accordion
        if (event.rules.isNotEmpty) ...[
          GlassCard(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Event Rules & Guidelines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  trailing: Icon(_rulesExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.neonPink),
                  onTap: () => setState(() => _rulesExpanded = !_rulesExpanded),
                ),
                if (_rulesExpanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: event.rules.map((r) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: AppColors.neonPink, fontSize: 16)),
                              Expanded(child: Text(r, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // FAQ Section
        const Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        const SizedBox(height: 12),
        Column(
          children: List.generate(_faqs.length, (idx) {
            final faq = _faqs[idx];
            final isOpen = _openFaqIndex == idx;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(faq['q']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      trailing: Icon(isOpen ? Icons.expand_less : Icons.expand_more, size: 20, color: AppColors.textSecondary),
                      onTap: () => setState(() => _openFaqIndex = isOpen ? null : idx),
                    ),
                    if (isOpen)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(faq['a']!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ==========================================
  // HEADLINER SPOTLIGHT CARD (District.in Style)
  // ==========================================
  Widget _buildHeadlinerSpotlight(BuildContext context, int dayId) {
    final dayAsync = ref.watch(eventDayDetailProvider(dayId));

    return dayAsync.maybeWhen(
      data: (day) {
        final headliner = day.primaryArtist;
        if (headliner == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.neonPurple.withValues(alpha: 0.2),
                  const Color(0xFF1B1438),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                // Glowing Headliner Avatar
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: NetworkImageBox(
                    url: headliner.photoUrl,
                    height: 56,
                    width: 56,
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.neonPink.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '★ FEATURED HEADLINER',
                              style: TextStyle(color: AppColors.neonPink, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        headliner.name,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
                      ),
                      Text(
                        headliner.type.isNotEmpty ? headliner.type : 'Lead Vocalist / Performing Artist',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildCategoryBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.neonPurple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFFD8B4FE), fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  // ==========================================
  // VERIFIED "THINGS TO KNOW" SPECIFICATIONS
  // ==========================================
  Widget _buildDynamicThingsToKnow(EventDetail event) {
    final List<({IconData icon, String title, String value})> specs = [];

    // 1. Duration (Deterministic from verified Event Days)
    if (event.days.isNotEmpty) {
      final nightCount = event.days.length;
      specs.add((
        icon: Icons.timer_outlined,
        title: 'Duration',
        value: '$nightCount ${nightCount == 1 ? 'Night' : 'Nights'} Scheduled',
      ));
    }

    // 2. Venue & Layout (From verified venue / address data)
    if (event.venue != null && event.venue!.trim().isNotEmpty) {
      specs.add((
        icon: Icons.stadium_outlined,
        title: 'Venue',
        value: event.venue!.trim(),
      ));
    } else if (event.location != null && event.location!.trim().isNotEmpty) {
      specs.add((
        icon: Icons.location_on_outlined,
        title: 'Location',
        value: event.location!.trim(),
      ));
    }

    // 3. Verified Facilities (Parking, AC, Seating, etc.)
    for (final facility in event.facilities) {
      final lowerName = facility.name.toLowerCase();
      IconData icon = Icons.check_circle_outline;
      String title = 'Facility';

      if (lowerName.contains('parking')) {
        icon = Icons.local_parking_outlined;
        title = 'Parking';
      } else if (lowerName.contains('ac') || lowerName.contains('air')) {
        icon = Icons.ac_unit_outlined;
        title = 'Comfort';
      } else if (lowerName.contains('food') || lowerName.contains('stall')) {
        icon = Icons.restaurant_outlined;
        title = 'Food & Drinks';
      } else if (lowerName.contains('security') || lowerName.contains('cctv')) {
        icon = Icons.shield_outlined;
        title = 'Safety';
      } else if (lowerName.contains('medical') || lowerName.contains('first aid')) {
        icon = Icons.medical_services_outlined;
        title = 'Medical Aid';
      } else if (lowerName.contains('wheelchair') || lowerName.contains('accessible')) {
        icon = Icons.accessible_outlined;
        title = 'Accessibility';
      }

      specs.add((icon: icon, title: title, value: facility.name));
    }

    // 4. Verified Event Rules (Age policy, dress code, entry requirements)
    for (final rule in event.rules) {
      final lowerRule = rule.toLowerCase();
      if (lowerRule.contains('age') || lowerRule.contains('kid') || lowerRule.contains('child') || lowerRule.contains('family')) {
        specs.add((
          icon: Icons.family_restroom,
          title: 'Age Policy',
          value: rule,
        ));
      } else if (lowerRule.contains('dress') || lowerRule.contains('attire') || lowerRule.contains('clothing')) {
        specs.add((
          icon: Icons.checkroom_outlined,
          title: 'Dress Code',
          value: rule,
        ));
      } else if (lowerRule.contains('entry') || lowerRule.contains('pass') || lowerRule.contains('wristband') || lowerRule.contains('id proof')) {
        specs.add((
          icon: Icons.confirmation_number_outlined,
          title: 'Entry Requirement',
          value: rule,
        ));
      } else if (lowerRule.contains('pet') || lowerRule.contains('food') || lowerRule.contains('alcohol') || lowerRule.contains('smoke')) {
        specs.add((
          icon: Icons.block_outlined,
          title: 'Venue Policy',
          value: rule,
        ));
      }
    }

    // If no verified specs exist, do not display empty or guessed content
    if (specs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Things to Know', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.2)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 500;
              return Wrap(
                spacing: 24,
                runSpacing: 16,
                children: specs.map((item) {
                  return _buildSpecItem(
                    icon: item.icon,
                    title: item.title,
                    value: item.value,
                    width: isWide ? (constraints.maxWidth - 24) / 2 : double.infinity,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem({
    required IconData icon,
    required String title,
    required String value,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.neonPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.neonPink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  MainAxisSize dynamicViewsIconSize() => MainAxisSize.min;

  // ==========================================
  // DAY LIVE CONTENT (Lineup + Passes)
  // ==========================================
  Widget _buildDayLiveContent(BuildContext context, int dayId, EventDetail event) {
    final dayAsync = ref.watch(eventDayDetailProvider(dayId));
    final isDomeEnabled = ref.watch(domeLayoutProvider).isEnabledFor(event);

    return dayAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (err, _) => Text('Error loading day details: $err', style: const TextStyle(color: AppColors.error)),
      data: (day) {
        TicketCategory? currentPass;
        if (_selectedPassId != null) {
          for (final p in day.passes) {
            if (p.id == _selectedPassId) {
              currentPass = p;
              break;
            }
          }
        }
        if (currentPass == null && day.passes.isNotEmpty) {
          currentPass = day.passes.first;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected Day Info Banner with time & program
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF16102E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF38296B)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'DAY ${day.dayNumber}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day.date,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                        ),
                        if (day.programName != null && day.programName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(day.programName!, style: const TextStyle(color: AppColors.neonPink, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ),
                  if (day.startTime != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2E2452)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 14, color: AppColors.neonBlue),
                          const SizedBox(width: 5),
                          Text(
                            '${day.startTime} - ${day.endTime ?? ""}',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Performing Artists Lineup
            if (day.artists.isNotEmpty) ...[
              const Text('Performing Artists Lineup', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: day.artists.map((a) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGlass,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NetworkImageBox(url: a.photoUrl, height: 44, width: 44, borderRadius: BorderRadius.circular(22)),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(a.type, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                        if (a.isPrimary) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.neonPurple, borderRadius: BorderRadius.circular(6)),
                            child: const Text('HEADLINER', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Interactive AC Dome Stand & Stage Layout (Unique booking view for AC Dome events)
            if (isDomeEnabled && day.passes.isNotEmpty) ...[
              InteractiveVenueLayoutMap(
                passes: day.passes,
                selectedPassId: currentPass?.id,
                onPassSelected: (pass) {
                  setState(() {
                    _selectedPassId = pass.id;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Selected Stand Info Card for AC Dome
              if (currentPass != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16102E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.neonPurple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.stadium_rounded, color: AppColors.neonPink, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  currentPass.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.neonPurple.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    currentPass.type,
                                    style: const TextStyle(color: AppColors.neonPink, fontSize: 10, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              currentPass.benefits.isNotEmpty
                                  ? currentPass.benefits.join(' · ')
                                  : 'Full Stand Entry · Instant WhatsApp Delivery',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${currentPass.price.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.neonPink),
                          ),
                          const Text('per pass', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
            ] else ...[
              // Standard Non-Dome Events (Lawn, Open Ground, Club Nights): Show standard Pass Category Cards
              const Text('Pass Categories', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.3)),
              const SizedBox(height: 4),
              const Text('Select your preferred pass tier with instant WhatsApp QR confirmation.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),

              if (day.passes.isEmpty)
                const Text('No pass categories released for this night yet.', style: TextStyle(color: AppColors.textSecondary))
              else ...[
                // Responsive Grid of High-Fidelity VMN Pass Tier Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 580;
                    final cardWidth = isWide ? (constraints.maxWidth - 16) / 2 : double.infinity;

                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: day.passes.map((p) {
                        final qty = _getQuantity(p.id);
                        final isSoldOut = p.soldOut || p.availableQuantity == 0;
                        final isLowStock = p.lowStock;
                        final isSelected = qty > 0;

                        return InkWell(
                          onTap: isSoldOut
                              ? null
                              : () {
                                  if (qty == 0) {
                                    _setQuantity(p.id, 1, maxPerCustomer: p.maxPerCustomer, availableQuantity: p.availableQuantity);
                                  }
                                },
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: cardWidth,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1E153D) : const Color(0xFF130E26),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFEC4899)
                                    : (isSoldOut ? const Color(0xFF261D45) : const Color(0xFF2B2050)),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFEC4899).withValues(alpha: 0.25),
                                        blurRadius: 20,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Title + Stock/Availability Badge
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (p.type.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Text(
                                                p.type.toUpperCase(),
                                                style: const TextStyle(color: AppColors.neonPurple, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isSoldOut)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(6)),
                                        child: const Text('SOLD OUT', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                      )
                                    else if (isLowStock)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                        child: Text('Only ${p.availableQuantity} left', style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                                        ),
                                        child: const Text('Fast Filling 🔥', style: TextStyle(color: Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Price Row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '₹${p.price.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFF43F5E)),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text('/ pass', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  ],
                                ),

                                const SizedBox(height: 12),
                                const Divider(height: 1, color: Color(0xFF261D45)),
                                const SizedBox(height: 12),

                                // Benefits list
                                if (p.benefits.isNotEmpty)
                                  ...p.benefits.map((b) => Padding(
                                        padding: const EdgeInsets.only(bottom: 5),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('✓ ', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                                            Expanded(child: Text(b, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3))),
                                          ],
                                        ),
                                      ))
                                else ...[
                                  const Row(
                                    children: [
                                      Text('✓ ', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                                      Text('Guaranteed Entry to Arena', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Row(
                                    children: [
                                      Text('✓ ', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                                      Text('Instant Digital QR Delivery', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                ],

                                const SizedBox(height: 14),

                                // Card Bottom Action (Select vs Selected + Counter)
                                if (isSoldOut)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text('UNAVAILABLE', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                                  )
                                else if (isSelected)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.4)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.check_circle, size: 15, color: Color(0xFFEC4899)),
                                            const SizedBox(width: 6),
                                            Text('Added ($qty)', style: const TextStyle(color: Color(0xFFF472B6), fontWeight: FontWeight.w800, fontSize: 12)),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            InkWell(
                                              onTap: () => _setQuantity(p.id, -1, maxPerCustomer: p.maxPerCustomer, availableQuantity: p.availableQuantity),
                                              borderRadius: BorderRadius.circular(4),
                                              child: Container(
                                                padding: const EdgeInsets.all(3),
                                                decoration: BoxDecoration(
                                                  color: Colors.white24,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Icon(Icons.remove, size: 14, color: Colors.white),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text(
                                                '$qty',
                                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => _setQuantity(p.id, 1, maxPerCustomer: p.maxPerCustomer, availableQuantity: p.availableQuantity),
                                              borderRadius: BorderRadius.circular(4),
                                              child: Container(
                                                padding: const EdgeInsets.all(3),
                                                decoration: BoxDecoration(
                                                  color: Colors.white24,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Icon(Icons.add, size: 14, color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  InkWell(
                                    onTap: () => _setQuantity(p.id, 1, maxPerCustomer: p.maxPerCustomer, availableQuantity: p.availableQuantity),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF261D45),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFF38296B)),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add, size: 14, color: Color(0xFFD8B4FE)),
                                          SizedBox(width: 4),
                                          Text('Add Pass', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  // ==========================================
  // RIGHT STICKY BOOKING SIDEBAR (Showmates Style)
  // ==========================================
  Widget _buildStickySidebar(BuildContext context, EventDetail event, int? currentDayId, String? whatsappNumber) {
    if (currentDayId == null) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0B1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF261D45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pass Summary', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.3, color: Colors.white)),
            const SizedBox(height: 12),
            const Text(
              'Schedule and pass rates for this event will be live shortly. You can connect with our team on WhatsApp for early pass reservations.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 18),
            InkWell(
              onTap: () => _openWhatsApp(whatsappNumber, event, null, const []),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2319),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.6), width: 1.2),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF22C55E)),
                    SizedBox(width: 8),
                    Text(
                      'Chat on WhatsApp',
                      style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final dayAsync = ref.watch(eventDayDetailProvider(currentDayId));
    final settings = ref.watch(appSettingsProvider).value;

    return dayAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0B1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF261D45)),
        ),
        child: const LoadingView(),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (day) {
        final selectedPasses = day.passes.where((p) => _getQuantity(p.id) > 0).toList();
        final total = _calculateTotal(day.passes);
        final totalCount = _totalPassesCount;

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0B1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF261D45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Pass Summary & 0% Fee badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pass Summary',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: -0.3),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                    ),
                    child: const Text('0% Fee', style: TextStyle(color: Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (selectedPasses.isNotEmpty) ...[
                // Selected Pass Inner Container with itemized line items
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1438),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF38296B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // DAY pill & Date
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('DAY ${day.dayNumber}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              day.date,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Itemized List of Selected Passes
                      ...selectedPasses.map((p) {
                        final q = _getQuantity(p.id);
                        final itemTotal = p.price * q;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${p.name} × $q',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '₹${itemTotal.toInt()}',
                                style: const TextStyle(color: Color(0xFFF472B6), fontSize: 13, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 20, color: Color(0xFF2A204E)),
                      // Total calculation row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total ($totalCount passes)',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '₹${total.toInt()}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.neonPink),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // PROCEED TO BOOK PASS CTA Button (Gradient)
                GradientButton(
                  label: 'PROCEED TO BOOK PASS',
                  height: 48,
                  onPressed: () => _proceedToInquiry(event, day, day.passes),
                ),
              ] else ...[
                // Empty state when 0 passes are selected
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16102E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2A204E)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('DAY ${day.dayNumber}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              day.date,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Select passes on the left to view breakdown and proceed with booking.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                GradientButton(
                  label: 'CHOOSE PASSES',
                  height: 48,
                  onPressed: () => _scrollToDaySection(),
                ),
              ],

              // Optional Online UPI Payment Option (Gated by admin settings)
              if (settings != null && settings.upiEnabled && totalCount > 0) ...[
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => _showUpiPaymentDialog(event, day, day.passes, settings),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flash_on_rounded, size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'PAY VIA UPI (INSTANT)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Chat on WhatsApp Button (Dark with green border and green text matching screenshot)
              InkWell(
                onTap: () => _openWhatsApp(settings?.whatsappNumber ?? whatsappNumber, event, day, day.passes),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2319),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.6), width: 1.2),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF22C55E)),
                      SizedBox(width: 8),
                      Text(
                        'Chat on WhatsApp',
                        style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(color: Color(0xFF261D45)),
              const SizedBox(height: 14),

              // Trust Badges matching screenshot
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TrustBadgeItem(icon: Icons.verified_user_outlined, text: '100% Genuine & Verified Passes'),
                  SizedBox(height: 10),
                  _TrustBadgeItem(icon: Icons.bolt_rounded, text: 'Instant WhatsApp Booking Assistance'),
                  SizedBox(height: 10),
                  _TrustBadgeItem(icon: Icons.money_off_outlined, text: 'Zero Hidden / Convenience Fees'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // MOBILE FLOATING BOTTOM BOOKING BAR (District / Showmates UX)
  // ==========================================
  Widget _buildMobileBottomBar(BuildContext context, EventDetail event, int dayId, String? whatsappNumber) {
    final dayAsync = ref.watch(eventDayDetailProvider(dayId));

    return dayAsync.maybeWhen(
      data: (day) {
        final total = _calculateTotal(day.passes);
        final totalCount = _totalPassesCount;

        final priceStr = totalCount > 0
            ? '₹${total.toInt()}'
            : (day.passes.isNotEmpty ? 'From ₹${day.passes.first.price.toInt()}' : 'Tickets TBA');

        final subtextStr = totalCount > 0
            ? '$totalCount passes selected · Day ${day.dayNumber}'
            : 'Day ${day.dayNumber} · ${day.date}';

        return Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0B1E),
            border: const Border(top: BorderSide(color: Color(0xFF261D45), width: 1.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        priceStr,
                        style: const TextStyle(
                          color: Color(0xFFF43F5E),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtextStr,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                ElevatedButton(
                  onPressed: () {
                    if (totalCount > 0) {
                      _proceedToInquiry(event, day, day.passes);
                    } else {
                      _scrollToDaySection();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                    shadowColor: const Color(0xFFE11D48).withValues(alpha: 0.5),
                  ),
                  child: Text(
                    totalCount > 0 ? 'BOOK PASSES ($totalCount)' : 'SELECT PASSES',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _TrustBadgeItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TrustBadgeItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.neonBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ),
      ],
    );
  }
}

class _PassQuantityStepper extends StatefulWidget {
  final int quantity;
  final int maxQuantity;
  final ValueChanged<int> onChanged;

  const _PassQuantityStepper({
    required this.quantity,
    required this.maxQuantity,
    required this.onChanged,
  });

  @override
  State<_PassQuantityStepper> createState() => _PassQuantityStepperState();
}

class _PassQuantityStepperState extends State<_PassQuantityStepper> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.quantity}');
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _validateAndSubmit(_controller.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _PassQuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity && !_focusNode.hasFocus) {
      _controller.text = '${widget.quantity}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validateAndSubmit(String val) {
    final parsed = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
    if (parsed == null || parsed < 1) {
      widget.onChanged(1);
      _controller.text = '1';
    } else {
      final maxLimit = widget.maxQuantity > 0 ? widget.maxQuantity : 100;
      final clamped = parsed.clamp(1, maxLimit);
      widget.onChanged(clamped);
      _controller.text = '$clamped';
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDec = widget.quantity > 1;
    final maxLimit = widget.maxQuantity > 0 ? widget.maxQuantity : 100;
    final canInc = widget.quantity < maxLimit;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF16102E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A204E)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Pass Quantity', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          Row(
            children: [
              InkWell(
                onTap: canDec
                    ? () {
                        final next = widget.quantity - 1;
                        widget.onChanged(next);
                        _controller.text = '$next';
                      }
                    : null,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: canDec ? AppColors.neonPink.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.remove, size: 16, color: canDec ? AppColors.neonPink : AppColors.textMuted),
                ),
              ),
              Container(
                width: 48,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    fillColor: const Color(0xFF23184A),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFF4C3888), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppColors.neonPurple, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFF38296A), width: 1),
                    ),
                  ),
                  onChanged: (val) {
                    final parsed = int.tryParse(val);
                    if (parsed != null && parsed >= 1) {
                      final clamped = parsed.clamp(1, maxLimit);
                      widget.onChanged(clamped);
                    }
                  },
                  onSubmitted: _validateAndSubmit,
                ),
              ),
              InkWell(
                onTap: canInc
                    ? () {
                        final next = widget.quantity + 1;
                        widget.onChanged(next);
                        _controller.text = '$next';
                      }
                    : null,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: canInc ? AppColors.neonBlue.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.add, size: 16, color: canInc ? AppColors.neonBlue : AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
