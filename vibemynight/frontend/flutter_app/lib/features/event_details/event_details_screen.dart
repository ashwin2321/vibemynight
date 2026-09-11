import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/data_providers.dart';
import '../../core/providers/dome_layout_provider.dart';
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
  int? _selectedPassId;
  int _quantity = 1;
  int _activeGalleryIndex = 0;
  bool _rulesExpanded = false;
  int? _openFaqIndex;

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

  void _openWhatsApp(String? number, EventDetail event, EventDayDetail? day, TicketCategory? pass) {
    final num = number ?? '917041615131';
    final cleanNum = num.length == 10 ? '91$num' : num;
    final dayText = day != null ? 'Day ${day.dayNumber} (${day.date})' : '';
    final passText = pass != null ? '${pass.name} x $_quantity' : '';
    final text = 'Hi VibeMyNight team, I want to book passes for *${event.name}* $dayText $passText. Please share availability!';
    final url = 'https://api.whatsapp.com/send?phone=$cleanNum&text=${Uri.encodeComponent(text)}';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _proceedToInquiry(EventDetail event, EventDayDetail day, TicketCategory? pass) {
    if (pass == null) {
      _scrollToDaySection();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pass category first!'),
          backgroundColor: AppColors.neonPink,
        ),
      );
      return;
    }
    context.push(
      '/inquiry?eventDayId=${day.id}&ticketCategoryId=${pass.id}&quantity=$_quantity',
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
                        event.banner ?? event.mainImage ?? '',
                        fit: BoxFit.cover,
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
                      event.banner ?? event.mainImage ?? '',
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
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() {
                      _selectedDayIndex = idx;
                      _selectedPassId = null;
                      _quantity = 1;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppColors.primaryGradient : null,
                        color: isSelected ? null : AppColors.surfaceGlass,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.neonPurple : AppColors.divider,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.neonPurple.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'DAY ${d.dayNumber}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            d.date,
                            style: const TextStyle(
                              fontSize: 15,
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
  // DYNAMIC "THINGS TO KNOW" GRID (District & Showmates Style)
  // ==========================================
  Widget _buildDynamicThingsToKnow(EventDetail event) {
    // Dynamic Layout Type
    String layoutType = 'Outdoor Arena / Lawn';
    final nameVenue = '${event.name} ${event.venue ?? ""} ${event.description ?? ""}'.toLowerCase();
    if (nameVenue.contains('ac dome') || nameVenue.contains('dome')) {
      layoutType = 'AC Dome (Fully Air Conditioned)';
    } else if (nameVenue.contains('hall') || nameVenue.contains('indoor')) {
      layoutType = 'Indoor Air Conditioned Hall';
    } else if (nameVenue.contains('farm') || nameVenue.contains('resort') || nameVenue.contains('lawn')) {
      layoutType = 'Outdoor Open-Air Lawn & Farm';
    }

    // Dynamic Duration
    String duration = '5+ Hours Daily (Evening to Midnight)';
    if (event.days.isNotEmpty) {
      duration = '${event.days.length} Nights · 5+ Hours Nightly';
    }

    // Dynamic Parking
    String parking = 'Available at Venue';
    final hasParkingFacility = event.facilities.any((f) => f.name.toLowerCase().contains('parking'));
    if (hasParkingFacility) {
      parking = 'Managed Parking Available at Venue';
    }

    // Dynamic Age Policy
    String agePolicy = 'All Ages Allowed (Family Friendly)';
    final hasAgeRule = event.rules.any((r) => r.toLowerCase().contains('age') || r.toLowerCase().contains('kid'));
    if (hasAgeRule) {
      final rule = event.rules.firstWhere((r) => r.toLowerCase().contains('age') || r.toLowerCase().contains('kid'));
      agePolicy = rule;
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
                children: [
                  _buildSpecItem(
                    icon: Icons.translate,
                    title: 'Language',
                    value: 'Gujarati, Hindi',
                    width: isWide ? (constraints.maxWidth - 24) / 2 : double.infinity,
                  ),
                  _buildSpecItem(
                    icon: Icons.timer_outlined,
                    title: 'Duration',
                    value: duration,
                    width: isWide ? (constraints.maxWidth - 24) / 2 : double.infinity,
                  ),
                  _buildSpecItem(
                    icon: Icons.family_restroom,
                    title: 'Age Policy',
                    value: agePolicy,
                    width: isWide ? (constraints.maxWidth - 24) / 2 : double.infinity,
                  ),
                  _buildSpecItem(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Entry Requirement',
                    value: 'Digital QR Pass / Physical Wristband',
                    width: isWide ? (constraints.maxWidth - 24) / 2 : double.infinity,
                  ),
                  _buildSpecItem(
                    icon: Icons.stadium_outlined,
                    title: 'Venue Layout',
                    value: layoutType,
                    width: isWide ? (constraints.maxWidth - 24) / 2 : double.infinity,
                  ),
                  _buildSpecItem(
                    icon: Icons.local_parking_outlined,
                    title: 'Parking',
                    value: parking,
                    width: isWide ? (constraints.maxWidth - 24) / 2 : double.infinity,
                  ),
                  _buildSpecItem(
                    icon: Icons.checkroom_outlined,
                    title: 'Dress Code',
                    value: 'Traditional Garba Attire Recommended',
                    width: isWide ? (constraints.maxWidth - 24) / 2 : double.infinity,
                  ),
                  _buildSpecItem(
                    icon: Icons.pets_outlined,
                    title: 'Pets & Outside Food',
                    value: 'Not Allowed at Venue',
                    width: isWide ? (constraints.maxWidth - 24) / 2 : double.infinity,
                  ),
                ],
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
            // Selected Day Info Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.neonPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DAY ${day.dayNumber} · ${day.date}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        if (day.programName != null && day.programName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(day.programName!, style: const TextStyle(color: AppColors.neonPink, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ),
                  if (day.startTime != null)
                    Text('🕒 ${day.startTime} - ${day.endTime ?? ""}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
              const Text('Pass Categories', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 6),
              const Text('Select your preferred entry tier with instant WhatsApp QR confirmation.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 12),

              if (day.passes.isEmpty)
                const Text('No pass categories released for this night yet.', style: TextStyle(color: AppColors.textSecondary))
              else ...[
                // Grid of District.in Style Pass Cards
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: day.passes.map((p) {
                    final isSelected = (currentPass?.id == p.id);
                    final isSoldOut = p.soldOut || p.availableQuantity == 0;
                    final isLowStock = p.lowStock;

                    return InkWell(
                      onTap: isSoldOut ? null : () => setState(() => _selectedPassId = p.id),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 260,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.neonPurple.withValues(alpha: 0.15) : AppColors.surfaceGlass,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.neonPurple : (isSoldOut ? Colors.transparent : AppColors.divider),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.neonPurple.withValues(alpha: 0.25),
                                    blurRadius: 16,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    p.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSoldOut)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(4)),
                                    child: const Text('SOLD OUT', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                                  )
                                else if (isLowStock)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                    child: Text('Only ${p.availableQuantity} left', style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('Fast Filling 🔥', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '₹${p.price.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.neonPink),
                                ),
                                const SizedBox(width: 4),
                                const Text('/ pass', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (p.benefits.isNotEmpty)
                              ...p.benefits.map((b) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('✓ ', style: TextStyle(color: AppColors.neonBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                                        Expanded(child: Text(b, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3))),
                                      ],
                                    ),
                                  ))
                            else ...[
                              const Row(
                                children: [
                                  Text('✓ ', style: TextStyle(color: AppColors.neonBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                                  Text('Guaranteed Entry to Arena', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 3),
                              const Row(
                                children: [
                                  Text('✓ ', style: TextStyle(color: AppColors.neonBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                                  Text('Instant Digital QR Delivery', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
              onTap: () => _openWhatsApp(whatsappNumber, event, null, null),
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

        final total = currentPass != null ? currentPass.price * _quantity : 0.0;

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

              if (currentPass != null) ...[
                // Selected Pass Inner Container (matching screenshot)
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
                      const SizedBox(height: 10),
                      // Pass Name
                      Text(
                        currentPass.name,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      // Event / Program Name
                      Text(
                        day.programName != null && day.programName!.isNotEmpty
                            ? day.programName!
                            : event.name,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Divider(height: 22, color: Color(0xFF2A204E)),
                      // Quantity x Rate and Total Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${currentPass.price.toStringAsFixed(0)} × $_quantity passes',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '₹${total.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.neonPink),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Compact Quantity Stepper
                if (!currentPass.soldOut)
                  Container(
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
                              onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _quantity > 1 ? AppColors.neonPink.withValues(alpha: 0.15) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(Icons.remove, size: 16, color: _quantity > 1 ? AppColors.neonPink : AppColors.textMuted),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('$_quantity', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                            ),
                            InkWell(
                              onTap: _quantity < currentPass.maxPerCustomer ? () => setState(() => _quantity++) : null,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _quantity < currentPass.maxPerCustomer ? AppColors.neonBlue.withValues(alpha: 0.15) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(Icons.add, size: 16, color: _quantity < currentPass.maxPerCustomer ? AppColors.neonBlue : AppColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 18),

                // PROCEED TO INQUIRY CTA Button (Gradient)
                GradientButton(
                  label: 'PROCEED TO INQUIRY',
                  height: 48,
                  onPressed: () => _proceedToInquiry(event, day, currentPass),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16102E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2A204E)),
                  ),
                  child: const Text(
                    'Select a stand or pass on the left to proceed with inquiry.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Chat on WhatsApp Button (Dark with green border and green text matching screenshot)
              InkWell(
                onTap: () => _openWhatsApp(whatsappNumber, event, day, currentPass),
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

        final priceStr = currentPass != null
            ? '₹${(currentPass.price * _quantity).toInt()}'
            : (day.passes.isNotEmpty ? '₹${day.passes.first.price.toInt()}' : 'Tickets TBA');

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
                        currentPass != null ? '${currentPass.name} (×$_quantity)' : 'Day ${day.dayNumber} · ${day.date}',
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
                    if (currentPass != null) {
                      _proceedToInquiry(event, day, currentPass);
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
                  child: const Text(
                    'BOOK TICKETS',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, letterSpacing: 0.5),
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
