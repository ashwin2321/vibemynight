import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/data_providers.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_footer.dart';
import '../../core/widgets/app_navbar.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/loading_view.dart';
import '../../models/artist.dart';
import '../../models/event_summary.dart';
import '../events/widgets/event_card.dart';

/// Full Showmates & Figma-faithful Home Page:
/// - 100% DYNAMIC: All Featured Nights, Upcoming Events, and Featured Artists
///   are loaded directly from the live Spring Boot Backend APIs.
/// - Hero with concert crowd background, "Events Now Live" pill, bold gradient typography & CTA buttons.
/// - Spotlight 3D Carousel on mobile view with adjacent posters peeking.
/// - Interactive Category Filter Chips Bar (Navratri 2026, DJ & EDM, Live Concerts, VIP Exclusives).
/// - Featured Nights: 2-Column Responsive 3:4 Poster Event Cards on mobile with floating date pills, price tags & neon glow.
/// - Circular "Events by Artist & DJs" strip with smooth left/right chevron navigation.
/// - Floating Bottom Navigation Bar on mobile with VIP Passes WhatsApp integration.
/// - Why VibeMyNight: 4 glass cards with neon icon badges.
/// - Shimmer Skeleton Loading: Zero blank screen lag.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const _heroImg =
      'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1600&h=900&fit=crop&auto=format';
  static const _ctaImg =
      'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=1600&h=700&fit=crop&auto=format';

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedCategory = 'All Events';
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      precacheImage(const NetworkImage(HomeScreen._heroImg), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(publishedEventsProvider);
    final artistsAsync = ref.watch(artistsProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final whatsappNumber = settingsAsync.value?.whatsappNumber ?? '917041615131';

    return Scaffold(
      backgroundColor: const Color(0xFF07070E),
      appBar: const AppNavbar(currentRoute: '/'),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(publishedEventsProvider);
          ref.invalidate(artistsProvider);
          ref.invalidate(appSettingsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. SHOWMATES HERO BANNER CAROUSEL (AS SEEN IN SROLL.MP4)
              _ShowmatesHeroCarousel(
                eventsAsync: eventsAsync,
                whatsappNumber: whatsappNumber,
              ),

              // 2. CATEGORY FILTER CHIPS BAR
              _CategoryFilterBar(
                selectedCategory: _selectedCategory,
                onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
              ),

              // 3. FEATURED NIGHTS SECTION (DYNAMIC 3:4 POSTERS - 2 COLUMNS ON MOBILE)
              _FeaturedNightsSection(
                eventsAsync: eventsAsync,
                selectedCategory: _selectedCategory,
              ),

              // 4. CIRCULAR FEATURED ARTISTS & DJS SLIDER (SHOWMATES STYLE)
              _FeaturedArtistsSection(artistsAsync: artistsAsync),

              // 5. UPCOMING EVENTS SECTION (DYNAMIC)
              _UpcomingEventsSection(eventsAsync: eventsAsync),

              // 6. WHY VIBEMYNIGHT SECTION
              const _WhyVibeMyNightSection(),

              // 7. EVENT EXPERIENCES SECTION
              const _EventExperiencesSection(),

              // 8. FINAL CTA SECTION
              const _FinalCtaSection(),

              // 9. FOOTER
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 1. SHOWMATES HERO BANNER CAROUSEL (AS SEEN IN SROLL.MP4)
// ==========================================
class _ShowmatesHeroCarousel extends StatefulWidget {
  final AsyncValue<List<EventSummary>> eventsAsync;
  final String whatsappNumber;

  const _ShowmatesHeroCarousel({
    required this.eventsAsync,
    required this.whatsappNumber,
  });

  @override
  State<_ShowmatesHeroCarousel> createState() => _ShowmatesHeroCarouselState();
}

class _ShowmatesHeroCarouselState extends State<_ShowmatesHeroCarousel> {
  int _activeIndex = 0;
  late final PageController _pageController;

  static const _defaultEvents = [
    EventSummary(
      id: 1,
      name: 'SANKALP NAGRI GARBA & MANDLI',
      slug: 'sankalp-nagri-garba-mandli-2026',
      startDate: 'Sun 11 Oct',
      endDate: 'Tue 20 Oct',
      location: 'Sankalp Nagri Ground',
      city: 'Ahmedabad',
      dayCount: 9,
      startingPrice: 499,
      featured: true,
      status: 'PUBLISHED',
      mainImage: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1200&fit=crop&auto=format',
      thumbnail: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1200&fit=crop&auto=format',
    ),
    EventSummary(
      id: 2,
      name: 'AFTER 11:59 GARBA NIGHT',
      slug: 'after-11-59-garba-night-2026',
      startDate: 'Fri 16 Oct',
      endDate: 'Sun 25 Oct',
      location: 'The Grand Bhagwati Lawn',
      city: 'Ahmedabad',
      dayCount: 10,
      startingPrice: 799,
      featured: true,
      status: 'PUBLISHED',
      mainImage: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1200&fit=crop&auto=format',
      thumbnail: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1200&fit=crop&auto=format',
    ),
    EventSummary(
      id: 3,
      name: 'SWARNIM NAGARI AC DOME GARBA 2026',
      slug: 'swarnim-nagari-ac-dome-garba-2026',
      startDate: 'Wed 14 Oct',
      endDate: 'Fri 23 Oct',
      location: 'Swarnim AC Dome Complex',
      city: 'Gandhinagar',
      dayCount: 9,
      startingPrice: 599,
      featured: true,
      status: 'PUBLISHED',
      mainImage: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=1200&fit=crop&auto=format',
      thumbnail: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=1200&fit=crop&auto=format',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.74);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<EventSummary> _getDisplayEvents() {
    final liveEvents = widget.eventsAsync.value;
    if (liveEvents != null && liveEvents.isNotEmpty) {
      return liveEvents.take(8).toList();
    }
    return _defaultEvents;
  }

  void _nextPage(int total) {
    if (!_pageController.hasClients || total <= 1) return;
    final next = (_activeIndex + 1) % total;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void _prevPage(int total) {
    if (!_pageController.hasClients || total <= 1) return;
    final prev = (_activeIndex - 1 + total) % total;
    _pageController.animateToPage(
      prev,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _launchWhatsApp() async {
    final clean = widget.whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 960;
    final isTablet = size.width >= 650 && size.width < 960;

    final events = _getDisplayEvents();
    final safeIndex = _activeIndex.clamp(0, events.length - 1);
    final activeEvent = events[safeIndex];

    final activeImage = activeEvent.mainImage ??
        activeEvent.thumbnail ??
        'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1200&fit=crop&auto=format';

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: isDesktop ? 560 : (isTablet ? 480 : 440),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Ambient Blurred Backdrop Image (Smooth Cross-fade effect)
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              child: SizedBox(
                key: ValueKey<String>(activeImage),
                width: double.infinity,
                height: double.infinity,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                  child: Image.network(
                    activeImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0F0B1E)),
                  ),
                ),
              ),
            ),
          ),

          // 2. Luxury Dark Gradient Overlay & Vignette
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xF207070E),
                    const Color(0xDC07070E),
                    const Color(0x8A07070E),
                    const Color(0xF207070E),
                  ],
                  stops: const [0.0, 0.35, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // 3. Top-left Neon Glow Blob
          Positioned(
            top: -40,
            left: isDesktop ? 60 : 10,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 4. Hero Content: Split Layout on Desktop, Vertical Stack on Mobile
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 48 : (isTablet ? 24 : 16),
              vertical: isDesktop ? 42 : 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1320),
                child: isDesktop
                    ? _buildDesktopSplitLayout(events, activeEvent, safeIndex)
                    : _buildMobileLayout(events, activeEvent, safeIndex, isTablet),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DESKTOP SPLIT LAYOUT (MATCHING SROLL.MP4)
  // ==========================================
  Widget _buildDesktopSplitLayout(
    List<EventSummary> events,
    EventSummary activeEvent,
    int activeIdx,
  ) {
    final eventRoute = '/events/${activeEvent.slug.isNotEmpty ? activeEvent.slug : activeEvent.id}';

    final locParts = [
      if (activeEvent.location != null && activeEvent.location!.isNotEmpty) activeEvent.location!,
      if (activeEvent.city != null && activeEvent.city!.isNotEmpty) activeEvent.city!,
    ].where((s) => s.isNotEmpty).join(', ');
    final displayLoc = locParts.isEmpty ? 'Venue To Be Announced' : locParts;

    final dateText = [
      if (activeEvent.startDate.isNotEmpty) activeEvent.startDate,
      if (activeEvent.endDate.isNotEmpty && activeEvent.endDate != activeEvent.startDate)
        '- ${activeEvent.endDate}',
    ].join(' ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // LEFT COLUMN: Title, Dates, Venue, CTA & Arrow Controls
        SizedBox(
          width: 440,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFC084FC),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFC084FC),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'FEATURED NIGHT',
                      style: TextStyle(
                        color: Color(0xFFC084FC),
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Large Bold Event Title (with smooth crossfade)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.08),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Text(
                  activeEvent.name.toUpperCase(),
                  key: ValueKey<int>(activeEvent.id),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Date & Venue Subtitle
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Column(
                  key: ValueKey<int>(activeEvent.id + 1000),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dateText.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: Color(0xFFC084FC), size: 15),
                          const SizedBox(width: 8),
                          Text(
                            dateText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Color(0xFF60A5FA), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            displayLoc,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Primary CTA Button + WhatsApp
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  GradientButton(
                    label: 'GET TICKETS',
                    icon: Icons.confirmation_number_outlined,
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    onPressed: () => context.push(eventRoute),
                  ),
                  InkWell(
                    onTap: _launchWhatsApp,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 16),
                          SizedBox(width: 8),
                          Text(
                            'VIP Inquiries',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Bottom-Left Navigation Arrows (As shown in sroll.mp4)
              Row(
                children: [
                  _CarouselArrowButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => _prevPage(events.length),
                  ),
                  const SizedBox(width: 12),
                  _CarouselArrowButton(
                    icon: Icons.arrow_forward_rounded,
                    onTap: () => _nextPage(events.length),
                  ),
                  const SizedBox(width: 18),
                  // Current slide counter (e.g. 01 / 05)
                  Text(
                    '${(activeIdx + 1).toString().padLeft(2, '0')} / ${events.length.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 36),

        // RIGHT COLUMN: Horizontal PageView with Peeking Banner Card
        Expanded(
          child: SizedBox(
            height: 380,
            child: PageView.builder(
              controller: _pageController,
              itemCount: events.length,
              onPageChanged: (idx) => setState(() => _activeIndex = idx),
              itemBuilder: (context, index) {
                final ev = events[index];
                final isCurrent = index == activeIdx;
                final targetRoute = '/events/${ev.slug.isNotEmpty ? ev.slug : ev.id}';

                return AnimatedScale(
                  scale: isCurrent ? 1.0 : 0.92,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: isCurrent ? 1.0 : 0.72,
                    duration: const Duration(milliseconds: 320),
                    child: GestureDetector(
                      onTap: () {
                        if (isCurrent) {
                          context.push(targetRoute);
                        } else {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isCurrent
                                ? const Color(0xFF8B5CF6)
                                : Colors.white.withValues(alpha: 0.12),
                            width: isCurrent ? 2.0 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isCurrent
                                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.45)
                                  : Colors.black.withValues(alpha: 0.6),
                              blurRadius: isCurrent ? 24 : 10,
                              offset: const Offset(0, 8),
                              spreadRadius: isCurrent ? 2 : 0,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Banner Image
                              Image.network(
                                ev.mainImage ?? ev.thumbnail ?? HomeScreen._heroImg,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF16102A),
                                  child: const Center(
                                    child: Icon(Icons.nightlife, color: Colors.white24, size: 56),
                                  ),
                                ),
                              ),

                              // Bottom gradient shadow
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.3),
                                      const Color(0xFF07070E).withValues(alpha: 0.85),
                                    ],
                                    stops: const [0.5, 0.75, 1.0],
                                  ),
                                ),
                              ),

                              // Floating Top Date Pill & Price Pill
                              Positioned(
                                top: 16,
                                left: 16,
                                right: 16,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (ev.startDate.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.75),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.calendar_month, color: Color(0xFFC084FC), size: 13),
                                            const SizedBox(width: 5),
                                            Text(
                                              ev.startDate,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (ev.startingPrice != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          'FROM ₹${ev.startingPrice!.toInt()}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Bottom mini action pill on hover/focus
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? const Color(0xFFA855F7)
                                        : Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      if (isCurrent)
                                        BoxShadow(
                                          color: const Color(0xFFA855F7).withValues(alpha: 0.4),
                                          blurRadius: 10,
                                        ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isCurrent ? 'BOOK PASS' : 'VIEW',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // MOBILE & TABLET RESPONSIVE HERO LAYOUT
  // ==========================================
  Widget _buildMobileLayout(
    List<EventSummary> events,
    EventSummary activeEvent,
    int activeIdx,
    bool isTablet,
  ) {
    final eventRoute = '/events/${activeEvent.slug.isNotEmpty ? activeEvent.slug : activeEvent.id}';

    final locParts = [
      if (activeEvent.location != null && activeEvent.location!.isNotEmpty) activeEvent.location!,
      if (activeEvent.city != null && activeEvent.city!.isNotEmpty) activeEvent.city!,
    ].where((s) => s.isNotEmpty).join(', ');
    final displayLoc = locParts.isEmpty ? 'Venue To Be Announced' : locParts;

    final dateText = [
      if (activeEvent.startDate.isNotEmpty) activeEvent.startDate,
      if (activeEvent.endDate.isNotEmpty && activeEvent.endDate != activeEvent.startDate)
        '- ${activeEvent.endDate}',
    ].join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Pill Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department, color: Color(0xFFC084FC), size: 13),
                  SizedBox(width: 4),
                  Text(
                    'FEATURED NIGHTS',
                    style: TextStyle(
                      color: Color(0xFFC084FC),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            // Slide counter (01/05)
            Text(
              '${(activeIdx + 1).toString().padLeft(2, '0')} / ${events.length.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Horizontal Banner Carousel with Peeking Card
        SizedBox(
          height: isTablet ? 270 : 210,
          child: PageView.builder(
            controller: _pageController,
            itemCount: events.length,
            onPageChanged: (idx) => setState(() => _activeIndex = idx),
            itemBuilder: (context, index) {
              final ev = events[index];
              final isCurrent = index == activeIdx;
              final targetRoute = '/events/${ev.slug.isNotEmpty ? ev.slug : ev.id}';

              return AnimatedScale(
                scale: isCurrent ? 1.0 : 0.93,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: GestureDetector(
                  onTap: () {
                    if (isCurrent) {
                      context.push(targetRoute);
                    } else {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFF8B5CF6)
                            : Colors.white.withValues(alpha: 0.12),
                        width: isCurrent ? 1.8 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isCurrent
                              ? const Color(0xFF8B5CF6).withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.5),
                          blurRadius: isCurrent ? 16 : 8,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            ev.mainImage ?? ev.thumbnail ?? HomeScreen._heroImg,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF16102A)),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.4),
                                  const Color(0xFF07070E).withValues(alpha: 0.8),
                                ],
                                stops: const [0.4, 0.75, 1.0],
                              ),
                            ),
                          ),
                          if (ev.startingPrice != null)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '₹${ev.startingPrice!.toInt()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // Active Event Title & Location
        Text(
          activeEvent.name.toUpperCase(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),

        Row(
          children: [
            if (dateText.isNotEmpty) ...[
              const Icon(Icons.calendar_month, color: Color(0xFFC084FC), size: 13),
              const SizedBox(width: 4),
              Text(
                dateText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(width: 12),
            ],
            const Icon(Icons.location_on, color: Color(0xFF60A5FA), size: 14),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                displayLoc,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // CTA Button + Prev/Next Controls Row
        Row(
          children: [
            Expanded(
              child: GradientButton(
                label: 'GET TICKETS',
                icon: Icons.confirmation_number_outlined,
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                onPressed: () => context.push(eventRoute),
              ),
            ),
            const SizedBox(width: 10),
            _CarouselArrowButton(
              icon: Icons.arrow_back_rounded,
              size: 44,
              iconSize: 18,
              onTap: () => _prevPage(events.length),
            ),
            const SizedBox(width: 8),
            _CarouselArrowButton(
              icon: Icons.arrow_forward_rounded,
              size: 44,
              iconSize: 18,
              onTap: () => _nextPage(events.length),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Dots Pagination Indicator
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(events.length, (idx) {
              final isCur = idx == activeIdx;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isCur ? 18 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: isCur ? const Color(0xFFA855F7) : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// CAROUSEL ARROW BUTTON (FROSTED GLASS WITH PURPLE HOVER)
// ==========================================
class _CarouselArrowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const _CarouselArrowButton({
    required this.icon,
    required this.onTap,
    this.size = 46,
    this.iconSize = 20,
  });

  @override
  State<_CarouselArrowButton> createState() => _CarouselArrowButtonState();
}

class _CarouselArrowButtonState extends State<_CarouselArrowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered
                ? const Color(0xFFA855F7).withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFFA855F7)
                  : Colors.white.withValues(alpha: 0.2),
              width: 1.2,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: const Color(0xFFA855F7).withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              widget.icon,
              color: _isHovered ? Colors.white : Colors.white70,
              size: widget.iconSize,
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. CATEGORY FILTER CHIPS BAR (SHOWMATES STYLE)
// ==========================================
class _CategoryFilterBar extends StatefulWidget {
  final ValueChanged<String>? onCategorySelected;
  final String selectedCategory;

  const _CategoryFilterBar({
    this.onCategorySelected,
    this.selectedCategory = 'All Events',
  });

  @override
  State<_CategoryFilterBar> createState() => _CategoryFilterBarState();
}

class _CategoryFilterBarState extends State<_CategoryFilterBar> {
  late String _selected;

  static const _categories = [
    {'label': 'All Events', 'icon': '🔥'},
    {'label': 'Navratri 2026', 'icon': '💃'},
    {'label': 'DJ & EDM', 'icon': '🎧'},
    {'label': 'Live Concerts', 'icon': '🎤'},
    {'label': 'Club Nights', 'icon': '🍸'},
    {'label': 'VIP Exclusives', 'icon': '🎟️'},
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedCategory;
  }

  @override
  void didUpdateWidget(covariant _CategoryFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _selected = widget.selectedCategory;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 48 : 16,
        isDesktop ? 28 : 14,
        isDesktop ? 48 : 16,
        isDesktop ? 12 : 8,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selected == cat['label'];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selected = cat['label']!);
                      widget.onCategorySelected?.call(cat['label']!);
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                              )
                            : null,
                        color: isSelected ? null : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFA855F7)
                              : Colors.white.withValues(alpha: 0.12),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFA855F7).withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cat['icon']!, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Text(
                            cat['label']!,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. FEATURED NIGHTS SECTION (DISTRICT BY ZOMATO STYLE HORIZONTAL SIDE-SCROLLING CAROUSEL)
// ==========================================
class _FeaturedNightsSection extends StatefulWidget {
  final AsyncValue<List<EventSummary>> eventsAsync;
  final String selectedCategory;

  const _FeaturedNightsSection({
    required this.eventsAsync,
    this.selectedCategory = 'All Events',
  });

  @override
  State<_FeaturedNightsSection> createState() => _FeaturedNightsSectionState();
}

class _FeaturedNightsSectionState extends State<_FeaturedNightsSection> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollBy(double offset) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + offset).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1000;
    final isTablet = size.width >= 600 && size.width < 1000;

    final cardWidth = isDesktop ? 260.0 : (isTablet ? 220.0 : 190.0);
    final imageHeight = isDesktop ? 290.0 : (isTablet ? 250.0 : 215.0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 16,
        vertical: isDesktop ? 32 : 18,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Title + Left/Right Chevron Navigation Buttons + View All
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "DON'T MISS",
                          style: TextStyle(
                            color: Color(0xFFA855F7),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Featured Nights',
                          style: TextStyle(
                            fontSize: isDesktop ? 32 : 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (isDesktop) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Discover the most happening events and book official passes',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Actions: Left/Right Arrows + View All Link
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Left Arrow Button (Desktop & Tablet)
                      if (!isDesktop ? false : true) ...[
                        _NavArrowButton(
                          icon: Icons.arrow_back_rounded,
                          onPressed: () => _scrollBy(-(cardWidth * 2)),
                        ),
                        const SizedBox(width: 8),
                        _NavArrowButton(
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () => _scrollBy(cardWidth * 2),
                        ),
                        const SizedBox(width: 16),
                      ],

                      // View All Link
                      InkWell(
                        onTap: () => context.push('/events'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View All',
                                style: TextStyle(
                                  color: const Color(0xFFA855F7),
                                  fontWeight: FontWeight.w700,
                                  fontSize: isDesktop ? 14 : 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, color: Color(0xFFA855F7), size: 15),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Horizontal Side-Scrolling Events Slider
              widget.eventsAsync.when(
                loading: () => SizedBox(
                  height: isDesktop ? 440 : 360,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (_, __) => Container(
                      width: cardWidth,
                      decoration: BoxDecoration(
                        color: const Color(0xFF15102A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                    ),
                  ),
                ),
                error: (err, _) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.refresh_rounded, size: 36, color: Color(0xFFA855F7)),
                        const SizedBox(height: 10),
                        const Text(
                          'Updating latest schedule...',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap below to refresh upcoming events or reach out on WhatsApp.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (events) {
                  if (events.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFA855F7).withValues(alpha: 0.12),
                            const Color(0xFFEC4899).withValues(alpha: 0.06),
                            Colors.white.withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_fire_department, size: 16, color: Color(0xFFF59E0B)),
                                SizedBox(width: 6),
                                Text(
                                  'SEASON 2026 LINEUPS DROPPING SOON',
                                  style: TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Exclusive Passes & VIP Tables Releasing Shortly!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Filter by category if selected
                  var filtered = events;
                  if (widget.selectedCategory == 'Navratri 2026') {
                    filtered = events.where((e) => e.name.toLowerCase().contains('garba') || e.name.toLowerCase().contains('navratri') || (e.location?.toLowerCase().contains('garba') ?? false)).toList();
                  } else if (widget.selectedCategory == 'DJ & EDM') {
                    filtered = events.where((e) => e.name.toLowerCase().contains('dj') || e.name.toLowerCase().contains('edm') || (e.featuredArtistName?.toLowerCase().contains('dj') ?? false)).toList();
                  } else if (widget.selectedCategory == 'Live Concerts') {
                    filtered = events.where((e) => e.name.toLowerCase().contains('concert') || e.name.toLowerCase().contains('live') || (e.featuredArtistName?.isNotEmpty ?? false)).toList();
                  } else if (widget.selectedCategory == 'VIP Exclusives') {
                    filtered = events.where((e) => e.featured).toList();
                  }
                  if (filtered.isEmpty) filtered = events;

                  return ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: filtered.map((event) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 16, bottom: 4),
                            child: SizedBox(
                              width: cardWidth,
                              child: EventCard(
                                event: event,
                                imageHeight: imageHeight,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _NavArrowButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

// ==========================================
// 3. UPCOMING EVENTS SECTION (DYNAMIC - 2 COLUMNS ON MOBILE)
// ==========================================
class _UpcomingEventsSection extends StatelessWidget {
  final AsyncValue<List<EventSummary>> eventsAsync;

  const _UpcomingEventsSection({required this.eventsAsync});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;
    final isTablet = size.width >= 600 && size.width < 900;
    final cols = isDesktop ? 3 : (isTablet ? 2 : 2);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CALENDAR',
                        style: TextStyle(
                          color: Color(0xFF60A5FA),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upcoming Events',
                        style: TextStyle(
                          fontSize: isDesktop ? 32 : 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => context.push('/events'),
                    child: const Row(
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            color: Color(0xFF60A5FA),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, color: Color(0xFF60A5FA), size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Dynamic Grid
              eventsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (events) {
                  if (events.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = (constraints.maxWidth - (cols - 1) * 16) / cols;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: events.take(6).map((ev) {
                          final img = ev.thumbnail ??
                              ev.mainImage ??
                              'https://images.unsplash.com/photo-1618176581836-9dcf475e2b4a?w=400&h=280&fit=crop&auto=format';
                          final targetRoute = '/events/${ev.slug.isNotEmpty ? ev.slug : ev.id}';

                          return SizedBox(
                            width: itemWidth,
                            child: InkWell(
                              onTap: () => context.push(targetRoute),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.07),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        img,
                                        width: 76,
                                        height: 76,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 76,
                                          height: 76,
                                          color: const Color(0xFF1E1E38),
                                          child: const Icon(Icons.nightlife, color: Colors.white24),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ev.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '📍 ${ev.location ?? ''}${ev.location != null && ev.city != null ? ', ' : ''}${ev.city ?? ''}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white.withValues(alpha: 0.4),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '📅 ${ev.startDate}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white.withValues(alpha: 0.4),
                                                ),
                                              ),
                                              Text(
                                                ev.startingPrice != null ? '₹${ev.startingPrice!.toInt()}' : '₹499',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFFA855F7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 4. WHY VIBEMYNIGHT SECTION
// ==========================================
class _WhyVibeMyNightSection extends StatelessWidget {
  const _WhyVibeMyNightSection();

  static const _whyCards = [
    {
      'icon': '✦',
      'title': 'Discover',
      'desc': 'Find amazing events, concerts and festival nights near you.',
    },
    {
      'icon': '★',
      'title': 'Experience',
      'desc': 'Live artists, laser shows and unforgettable nights.',
    },
    {
      'icon': '◈',
      'title': 'Easy Inquiry',
      'desc': 'Request your pass in seconds — no complex checkout.',
    },
    {
      'icon': '◆',
      'title': 'Trusted',
      'desc': 'Simple, transparent booking confirmed via WhatsApp.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;
    final isTablet = size.width >= 600 && size.width < 900;
    final cols = isDesktop ? 4 : (isTablet ? 2 : 1);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const Text(
                'WHY US',
                style: TextStyle(
                  color: Color(0xFFEC4899),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Why VibeMyNight?',
                style: TextStyle(
                  fontSize: isDesktop ? 32 : 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 36),

              // Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - (cols - 1) * 16) / cols;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: _whyCards.map((c) {
                      return Container(
                        width: itemWidth,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                c['icon']!,
                                style: const TextStyle(
                                  color: Color(0xFFC084FC),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              c['title']!,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              c['desc']!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.5),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 4. CIRCULAR FEATURED ARTISTS & DJS SLIDER (SHOWMATES STYLE)
// ==========================================
class _FeaturedArtistsSection extends StatefulWidget {
  final AsyncValue<List<Artist>> artistsAsync;

  const _FeaturedArtistsSection({required this.artistsAsync});

  @override
  State<_FeaturedArtistsSection> createState() => _FeaturedArtistsSectionState();
}

class _FeaturedArtistsSectionState extends State<_FeaturedArtistsSection> {
  final ScrollController _scrollController = ScrollController();

  void _scroll(double offset) {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      (_scrollController.offset + offset).clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artists = widget.artistsAsync.valueOrNull;
    if (widget.artistsAsync.hasValue && (artists == null || artists.isEmpty)) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              // Header with Left/Right Scroll Chevron Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FEATURED LINEUP',
                          style: TextStyle(
                            color: Color(0xFFA855F7),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Events by Artists & DJs',
                          style: TextStyle(
                            fontSize: isDesktop ? 32 : 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Discover nights curated by your favourite performers',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Left / Right Scroll Buttons (Showmates style)
                  Row(
                    children: [
                      _ScrollArrowButton(
                        icon: Icons.chevron_left,
                        onTap: () => _scroll(-260),
                      ),
                      const SizedBox(width: 8),
                      _ScrollArrowButton(
                        icon: Icons.chevron_right,
                        onTap: () => _scroll(260),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Dynamic Circular Artist Strip with Shimmer
              widget.artistsAsync.when(
                loading: () => const ShimmerArtistSlider(count: 6),
                error: (_, __) => const SizedBox.shrink(),
                data: (artists) {
                  if (artists.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: artists.map((a) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: _CircularArtistCard(artist: a),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScrollArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ScrollArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _CircularArtistCard extends StatefulWidget {
  final Artist artist;

  const _CircularArtistCard({required this.artist});

  @override
  State<_CircularArtistCard> createState() => _CircularArtistCardState();
}

class _CircularArtistCardState extends State<_CircularArtistCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.artist;
    final img = a.photoUrl ??
        'https://images.unsplash.com/photo-1496337589254-7e19d01cec44?w=300&h=300&fit=crop&auto=format';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.push('/artists'),
        child: SizedBox(
          width: 120,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular Avatar with Glowing Neon Ring
              AnimatedScale(
                scale: _isHovered ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Container(
                  width: 104,
                  height: 104,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isHovered
                          ? const [Color(0xFFA855F7), Color(0xFFEC4899)]
                          : [
                              const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                              const Color(0xFFEC4899).withValues(alpha: 0.3),
                            ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isHovered
                            ? const Color(0xFFA855F7).withValues(alpha: 0.45)
                            : Colors.black.withValues(alpha: 0.3),
                        blurRadius: _isHovered ? 20 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1E1E38),
                        child: const Icon(Icons.person, color: Colors.white24, size: 40),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Artist Name
              Text(
                a.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _isHovered ? const Color(0xFFC084FC) : Colors.white,
                ),
              ),
              const SizedBox(height: 3),

              // Genre / Type
              Text(
                a.type.isNotEmpty ? a.type : 'Live Performer',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 6. EVENT EXPERIENCES SECTION
// ==========================================
class _EventExperiencesSection extends StatelessWidget {
  const _EventExperiencesSection();

  static const _experiences = [
    {'label': 'Live Singer', 'icon': '🎤'},
    {'label': 'Celebrity Night', 'icon': '⭐'},
    {'label': 'DJ Night', 'icon': '🎧'},
    {'label': 'Laser Show', 'icon': '✨'},
    {'label': 'Massive Dance Floor', 'icon': '💃'},
    {'label': 'Premium Venue', 'icon': '🏛️'},
    {'label': 'Traditional Garba', 'icon': '🪔'},
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const Text(
                'WHAT AWAITS',
                style: TextStyle(
                  color: Color(0xFF60A5FA),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Event Experiences',
                style: TextStyle(
                  fontSize: isDesktop ? 32 : 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _experiences.map((exp) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.09),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(exp['icon']!, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          exp['label']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 7. FINAL CTA SECTION
// ==========================================
class _FinalCtaSection extends StatelessWidget {
  const _FinalCtaSection();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Image.network(
                    HomeScreen._ctaImg,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1E1038)),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xEB07070E),
                          Color(0x998B5CF6),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 48 : 24,
                    vertical: isDesktop ? 70 : 48,
                  ),
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Color(0xFFC084FC), Color(0xFFF472B6)],
                        ).createShader(bounds),
                        child: Text(
                          'YOUR NEXT NIGHT\nSTARTS HERE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isDesktop ? 48 : 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Don't wait. Your unforgettable experience is one click away.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 28),
                      GradientButton(
                        label: 'Explore Events',
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        onPressed: () => context.push('/events'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
