import 'dart:async';
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
import '../../core/widgets/network_image_box.dart';
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

  static const List<EventSummary> _defaultEvents = [
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
      mainImage: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1600&h=900&fit=crop&auto=format',
      thumbnail: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1600&h=900&fit=crop&auto=format',
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
      mainImage: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1600&h=900&fit=crop&auto=format',
      thumbnail: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1600&h=900&fit=crop&auto=format',
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
      mainImage: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=1600&h=900&fit=crop&auto=format',
      thumbnail: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=1600&h=900&fit=crop&auto=format',
    ),
  ];

  static const List<String> _heroFallbacks = [
    'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1600&h=900&fit=crop&auto=format',
    'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1600&h=900&fit=crop&auto=format',
    'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=1600&h=900&fit=crop&auto=format',
    'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=1600&h=900&fit=crop&auto=format',
    'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=1600&h=900&fit=crop&auto=format',
    'https://images.unsplash.com/photo-1571266028243-3716f02d2d2e?w=1600&h=900&fit=crop&auto=format',
    'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=1600&h=900&fit=crop&auto=format',
    'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=1600&h=900&fit=crop&auto=format',
  ];

  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoScrollTimer();
  }

  void _startAutoScrollTimer() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 4500), (_) {
      if (!mounted) return;
      final events = _getDisplayEvents();
      if (events.length > 1) {
        _nextPage(events.length, isAuto: true);
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
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

  void _nextPage(int total, {bool isAuto = false}) {
    if (total <= 1) return;
    if (!isAuto) _startAutoScrollTimer();
    final next = (_activeIndex + 1) % total;
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _prevPage(int total) {
    if (total <= 1) return;
    _startAutoScrollTimer();
    final prev = (_activeIndex - 1 + total) % total;
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        prev,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
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

    final activeImage = NetworkImageBox.resolveUrl(activeEvent.mainImage ?? activeEvent.thumbnail) ??
        _heroFallbacks[safeIndex % _heroFallbacks.length];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 24 : 14,
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
                    cacheWidth: 400,
                    cacheHeight: 250,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0F0B1E)),
                  ),
                ),
              ),
            ),
          ),

          // 2. Luxury Dark Gradient Overlay & Vignette
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xD907070E),
                    Color(0x8A07070E),
                    Color(0xF207070E),
                  ],
                  stops: [0.0, 0.5, 1.0],
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

          // 4. 16:9 Widescreen Banner Carousel (Edge-to-Edge Uncropped 16:9 BookMyShow Format)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : (isTablet ? 16 : 8),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1320),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 16:9 Aspect Ratio Widescreen Slider
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: events.length,
                            onPageChanged: (idx) => setState(() => _activeIndex = idx),
                            itemBuilder: (context, index) {
                              final ev = events[index];
                              final isCurrent = index == safeIndex;
                              final fallback = _heroFallbacks[index % _heroFallbacks.length];
                              return _buildBannerSlide(
                                context: context,
                                ev: ev,
                                index: index,
                                isCurrent: isCurrent,
                                isDesktop: isDesktop,
                                isTablet: isTablet,
                                fallback: fallback,
                              );
                            },
                          ),
                        ),

                        // Floating Left/Right Chevrons (Desktop & Tablet)
                        if (isDesktop || isTablet) ...[
                          Positioned(
                            left: 12,
                            child: _CarouselArrowButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () => _prevPage(events.length),
                            ),
                          ),
                          Positioned(
                            right: 12,
                            child: _CarouselArrowButton(
                              icon: Icons.arrow_forward_ios_rounded,
                              onTap: () => _nextPage(events.length),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Modern Slide Indicator & Navigation Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Slide Counter
                          Text(
                            '${(safeIndex + 1).toString().padLeft(2, '0')} / ${events.length.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Color(0xFFC084FC),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 1.5,
                            ),
                          ),

                          // Expanding Pill Indicators
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(events.length, (idx) {
                              final isCur = idx == safeIndex;
                              return GestureDetector(
                                onTap: () {
                                  _startAutoScrollTimer();
                                  _pageController.animateToPage(
                                    idx,
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeOutCubic,
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: isCur ? 26 : 7,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isCur ? const Color(0xFFA855F7) : Colors.white24,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: isCur
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFA855F7).withValues(alpha: 0.6),
                                              blurRadius: 6,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              );
                            }),
                          ),

                          // Mobile mini arrow controls or empty spacer on desktop
                          if (!isDesktop && !isTablet)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _CarouselArrowButton(
                                  icon: Icons.arrow_back_rounded,
                                  size: 32,
                                  iconSize: 15,
                                  onTap: () => _prevPage(events.length),
                                ),
                                const SizedBox(width: 8),
                                _CarouselArrowButton(
                                  icon: Icons.arrow_forward_rounded,
                                  size: 32,
                                  iconSize: 15,
                                  onTap: () => _nextPage(events.length),
                                ),
                              ],
                            )
                          else
                            const SizedBox(width: 48),
                        ],
                      ),
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

  // ==========================================
  // 16:9 WIDESCREEN BANNER SLIDE BUILDER
  // ==========================================
  Widget _buildBannerSlide({
    required BuildContext context,
    required EventSummary ev,
    required int index,
    required bool isCurrent,
    required bool isDesktop,
    required bool isTablet,
    required String fallback,
  }) {
    final eventRoute = '/events/${ev.slug.isNotEmpty ? ev.slug : ev.id}';
    final posterUrl = ev.mainImage ?? ev.thumbnail;

    final locParts = [
      if (ev.location != null && ev.location!.isNotEmpty) ev.location!,
      if (ev.city != null && ev.city!.isNotEmpty) ev.city!,
    ].where((s) => s.isNotEmpty).join(', ');
    final displayLoc = locParts.isEmpty ? 'Venue To Be Announced' : locParts;

    final dateText = [
      if (ev.startDate.isNotEmpty) ev.startDate,
      if (ev.endDate.isNotEmpty && ev.endDate != ev.startDate) '- ${ev.endDate}',
    ].join(' ');

    return AnimatedScale(
      scale: isCurrent ? 1.0 : 0.94,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: isCurrent ? 1.0 : 0.70,
        duration: const Duration(milliseconds: 320),
        child: GestureDetector(
          onTap: () {
            if (isCurrent) {
              context.push(eventRoute);
            } else {
              _startAutoScrollTimer();
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
              );
            }
          },
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: isDesktop ? 10 : 5,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isDesktop ? 22 : 14),
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
                      : Colors.black.withValues(alpha: 0.5),
                  blurRadius: isCurrent ? 24 : 10,
                  offset: const Offset(0, 8),
                  spreadRadius: isCurrent ? 2 : 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isDesktop ? 20 : 12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. 16:9 Widescreen Image (Maps 100% 16:9 uncropped)
                  NetworkImageBox(
                    url: posterUrl,
                    fallbackUrl: fallback,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),

                  // 2. Top subtle gradient for badges
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.35],
                      ),
                    ),
                  ),

                  // 3. Bottom gradient for text readability while leaving center artist clear
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.25),
                          const Color(0xFF07070E).withValues(alpha: 0.92),
                        ],
                        stops: const [0.42, 0.68, 1.0],
                      ),
                    ),
                  ),

                  // 4. Floating Top Badges
                  Positioned(
                    top: isDesktop ? 18 : 10,
                    left: isDesktop ? 18 : 10,
                    right: isDesktop ? 18 : 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 12 : 8,
                                vertical: isDesktop ? 6 : 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
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
                                  const SizedBox(width: 6),
                                  Text(
                                    'FEATURED NIGHT',
                                    style: TextStyle(
                                      color: const Color(0xFFC084FC),
                                      fontWeight: FontWeight.w800,
                                      fontSize: isDesktop ? 11 : 9.5,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (ev.startDate.isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 12 : 8,
                                  vertical: isDesktop ? 6 : 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_month, color: Color(0xFF60A5FA), size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      ev.startDate,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: isDesktop ? 11.5 : 9.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (ev.startingPrice != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 14 : 9,
                              vertical: isDesktop ? 6 : 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEC4899).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Text(
                              'FROM ₹${ev.startingPrice!.toInt()}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isDesktop ? 12 : 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 5. Bottom Overlay Content
                  Positioned(
                    bottom: isDesktop ? 18 : 8,
                    left: isDesktop ? 22 : 10,
                    right: isDesktop ? 22 : 10,
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ev.name.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded, color: Color(0xFF60A5FA), size: 15),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            displayLoc,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.8),
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (dateText.isNotEmpty) ...[
                                          const SizedBox(width: 10),
                                          Text('•', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                                          const SizedBox(width: 10),
                                          const Icon(Icons.calendar_today_rounded, color: Color(0xFFC084FC), size: 14),
                                          const SizedBox(width: 5),
                                          Text(
                                            dateText,
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.9),
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Wrap(
                                spacing: 10,
                                children: [
                                  GradientButton(
                                    label: 'GET TICKETS',
                                    icon: Icons.confirmation_number_outlined,
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    onPressed: () => context.push(eventRoute),
                                  ),
                                  InkWell(
                                    onTap: _launchWhatsApp,
                                    borderRadius: BorderRadius.circular(22),
                                    child: Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.22),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 15),
                                          SizedBox(width: 6),
                                          Text(
                                            'VIP Inquiries',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ev.name.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [displayLoc, if (dateText.isNotEmpty) dateText].join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 10.5,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Expanded(
                                    child: GradientButton(
                                      label: 'GET TICKETS',
                                      icon: Icons.confirmation_number_outlined,
                                      height: 32,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                      onPressed: () => context.push(eventRoute),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: _launchWhatsApp,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      height: 32,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 12),
                                          SizedBox(width: 4),
                                          Text(
                                            'VIP',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 10.5,
                                            ),
                                          ),
                                        ],
                                      ),
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
        ),
      ),
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

    final cardWidth = isDesktop ? 260.0 : 220.0;

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
                      if (isDesktop || isTablet) ...[
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

              // Dynamic Events Layout: 2-Column Grid on Mobile, Horizontal Scroll on Desktop/Tablet
              widget.eventsAsync.when(
                loading: () => SizedBox(
                  height: isDesktop ? 340 : 300,
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
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.refresh_rounded, size: 36, color: Color(0xFFA855F7)),
                        SizedBox(height: 10),
                        Text(
                          'Updating latest schedule...',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text(
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

                  // On Mobile: 2-Column Grid matching Showmates mobile UI
                  if (!isDesktop && !isTablet) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.54,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 14,
                      ),
                      itemBuilder: (context, index) {
                        return EventCard(
                          event: filtered[index],
                        );
                      },
                    );
                  }

                  // On Desktop & Tablet: Horizontal Smooth Slider with Nav Controls
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
                          final img = NetworkImageBox.resolveUrl(ev.thumbnail ?? ev.mainImage) ??
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
                                        cacheWidth: 200,
                                        cacheHeight: 200,
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
    final img = NetworkImageBox.resolveUrl(a.photoUrl) ??
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
                      cacheWidth: 250,
                      cacheHeight: 250,
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
