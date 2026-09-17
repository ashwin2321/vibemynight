import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
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
              // 1. UNIFIED VIBEMYNIGHT HERO & CATEGORY FILTER SECTION
              _VmnHeroCarousel(
                eventsAsync: eventsAsync,
                whatsappNumber: whatsappNumber,
                selectedCategory: _selectedCategory,
                onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
              ),

              // 2. FEATURED NIGHTS SECTION (DYNAMIC 3:4 POSTERS - 2 COLUMNS ON MOBILE)
              _FeaturedNightsSection(
                eventsAsync: eventsAsync,
                selectedCategory: _selectedCategory,
              ),

              // 3. CIRCULAR FEATURED ARTISTS & DJS SLIDER
              _FeaturedArtistsSection(artistsAsync: artistsAsync),

              // 4. UPCOMING EVENTS SECTION (DYNAMIC)
              _UpcomingEventsSection(eventsAsync: eventsAsync),

              // 5. WHY VIBEMYNIGHT SECTION
              const _WhyVibeMyNightSection(),

              // 6. EVENT EXPERIENCES SECTION
              const _EventExperiencesSection(),

              // 7. FINAL CTA SECTION
              const _FinalCtaSection(),

              // 8. FOOTER
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 1. VIBEMYNIGHT HERO BANNER CAROUSEL
// ==========================================
class _VmnHeroCarousel extends StatefulWidget {
  final AsyncValue<List<EventSummary>> eventsAsync;
  final String whatsappNumber;
  final String selectedCategory;
  final ValueChanged<String>? onCategorySelected;

  const _VmnHeroCarousel({
    required this.eventsAsync,
    required this.whatsappNumber,
    this.selectedCategory = 'All Events',
    this.onCategorySelected,
  });

  @override
  State<_VmnHeroCarousel> createState() => _VmnHeroCarouselState();
}

class _VmnHeroCarouselState extends State<_VmnHeroCarousel> {
  int _activeIndex = 0;
  late final PageController _pageController;
  late final PageController _mobilePageController;

  static const List<EventSummary> _defaultEvents = [
    EventSummary(
      id: 1,
      name: 'SANKALP NAGRI GARBA & MANDLI',
      slug: 'sankalp-nagri-garba-mandli-2026',
      startDate: 'Sun 11 Oct',
      endDate: 'Tue 20 Oct',
      location: 'Sankalp nagri ground',
      city: 'Ahmedabad',
      dayCount: 9,
      startingPrice: 499,
      featured: true,
      status: 'PUBLISHED',
      mainImage: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1600&h=900&fit=crop&auto=format',
      thumbnail: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=900&h=1200&fit=crop&auto=format',
    ),
    EventSummary(
      id: 2,
      name: 'The Rangeelo Garbo',
      slug: 'the-rangeelo-garbo-2026',
      startDate: 'Fri 09 Oct',
      endDate: 'Sun 18 Oct',
      location: 'Venue To Be Announced',
      city: 'Ahmedabad',
      dayCount: 10,
      startingPrice: 799,
      featured: true,
      status: 'PUBLISHED',
      mainImage: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1600&h=900&fit=crop&auto=format',
      thumbnail: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=900&h=1200&fit=crop&auto=format',
    ),
    EventSummary(
      id: 3,
      name: 'MAA NI NAVRATRI',
      slug: 'maa-ni-navratri-2026',
      startDate: 'Sat 10 Oct',
      endDate: 'Tue 20 Oct',
      location: 'YASH FARM RESORT',
      city: 'Ahmedabad',
      dayCount: 10,
      startingPrice: 599,
      featured: true,
      status: 'PUBLISHED',
      mainImage: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=1600&h=900&fit=crop&auto=format',
      thumbnail: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=900&h=1200&fit=crop&auto=format',
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
    _pageController = PageController(viewportFraction: 0.78);
    _mobilePageController = PageController(viewportFraction: 0.72);
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
    _mobilePageController.dispose();
    super.dispose();
  }

  List<EventSummary> _getDisplayEvents() {
    final liveEvents = widget.eventsAsync.value;
    if (liveEvents != null && liveEvents.isNotEmpty) {
      final heroOnly = liveEvents.where((e) => e.showInHero).toList();
      if (heroOnly.isNotEmpty) {
        return heroOnly;
      }
      final featured = liveEvents.where((e) => e.featured).toList();
      if (featured.isNotEmpty) {
        return featured.take(8).toList();
      }
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
    if (_mobilePageController.hasClients) {
      _mobilePageController.animateToPage(
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
    if (_mobilePageController.hasClients) {
      _mobilePageController.animateToPage(
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

    return Container(
      width: double.infinity,
      color: const Color(0xFF07070E),
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 48 : (isTablet ? 24 : 16),
        isDesktop ? 36 : 18,
        isDesktop ? 48 : (isTablet ? 24 : 16),
        isDesktop ? 20 : 12,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              isDesktop
                  ? _buildDesktopSplitLayout(events, activeEvent, safeIndex)
                  : _buildMobileLayout(events, activeEvent, safeIndex),
              SizedBox(height: isDesktop ? 28 : 16),
              _buildIntegratedCategoryChips(context, isDesktop),
            ],
          ),
        ),
      ),
    );
  }

  static const _categories = [
    {'label': 'All Events', 'icon': '🔥'},
    {'label': 'Navratri 2026', 'icon': '💃'},
    {'label': 'DJ & EDM', 'icon': '🎧'},
    {'label': 'Live Concerts', 'icon': '🎤'},
    {'label': 'Club Nights', 'icon': '🍸'},
    {'label': 'VIP Exclusives', 'icon': '🎟️'},
  ];

  Widget _buildIntegratedCategoryChips(BuildContext context, bool isDesktop) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _categories.map((cat) {
          final isSelected = widget.selectedCategory == cat['label'];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => widget.onCategorySelected?.call(cat['label']!),
              borderRadius: BorderRadius.circular(30),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : AppColors.surfaceGlass,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.neonPurple
                        : Colors.white.withValues(alpha: 0.12),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.neonPurple.withValues(alpha: 0.4),
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
                        color: isSelected ? Colors.white : AppColors.textSecondary,
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
    );
  }

  // ==========================================
  // DESKTOP SPLIT LAYOUT (VMN NIGHTLIFE THEME)
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
    ].where((s) => s.isNotEmpty).join(' • ');
    final displayLoc = locParts.isEmpty ? 'Venue To Be Announced' : locParts;

    final dateText = [
      if (activeEvent.startDate.isNotEmpty) activeEvent.startDate,
      if (activeEvent.endDate.isNotEmpty && activeEvent.endDate != activeEvent.startDate)
        '- ${activeEvent.endDate}',
    ].join(' ');

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final rightWidth = (totalWidth - 390).clamp(420.0, 900.0);
        final cardWidth = rightWidth * 0.78;
        final carouselHeight = cardWidth / (16 / 9);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // LEFT COLUMN: Title, Date & Venue, VMN Primary Gradient Button & Chevrons
            SizedBox(
              width: 370,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Event Category Tag (VMN Neon Pill)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.neonPurple.withValues(alpha: 0.3),
                          AppColors.neonPink.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.neonPurple.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.neonPink, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'FEATURED EVENT',
                          style: TextStyle(
                            color: AppColors.textPrimary.withValues(alpha: 0.9),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bold Event Title
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      activeEvent.name,
                      key: ValueKey<int>(activeEvent.id),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.2,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Date & Venue Subtitle
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      key: ValueKey<int>(activeEvent.id + 1000),
                      children: [
                        if (dateText.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.neonPink),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dateText,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 15, color: AppColors.neonPurple),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                displayLoc,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // VMN Signature Primary Gradient [ GET TICKETS ] Button
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      InkWell(
                        onTap: () => context.push(eventRoute),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonPurple.withValues(alpha: 0.45),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'GET TICKETS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _launchWhatsApp,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceGlass,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 15),
                              SizedBox(width: 6),
                              Text(
                                'VIP Inquiries',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
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
                  const SizedBox(height: 32),

                  // Clean Arrow Buttons (←  →) with VMN Neon Hover Glow
                  Row(
                    children: [
                      _VmnArrowButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => _prevPage(events.length),
                      ),
                      const SizedBox(width: 14),
                      _VmnArrowButton(
                        icon: Icons.arrow_forward_rounded,
                        onTap: () => _nextPage(events.length),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // RIGHT COLUMN: 16:9 Landscape Banner Cards
            Expanded(
              child: SizedBox(
                height: carouselHeight + 16,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: events.length,
                  onPageChanged: (idx) => setState(() => _activeIndex = idx),
                  itemBuilder: (context, index) {
                    final ev = events[index];
                    final isCurrent = index == activeIdx;
                    final targetRoute = '/events/${ev.slug.isNotEmpty ? ev.slug : ev.id}';
                    final posterUrl = ev.mainImage ?? ev.thumbnail;
                    final fallback = _heroFallbacks[index % _heroFallbacks.length];

                    return Center(
                      child: AnimatedScale(
                        scale: isCurrent ? 1.0 : 0.94,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
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
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: isCurrent
                                    ? Border.all(
                                        color: AppColors.neonPurple.withValues(alpha: 0.5),
                                        width: 1.5,
                                      )
                                    : Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                boxShadow: [
                                  BoxShadow(
                                    color: isCurrent
                                        ? AppColors.neonPurple.withValues(alpha: 0.3)
                                        : Colors.black.withValues(alpha: 0.35),
                                    blurRadius: isCurrent ? 24 : 10,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: NetworkImageBox(
                                  url: posterUrl,
                                  fallbackUrl: fallback,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
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
      },
    );
  }

  // ==========================================
  // MOBILE HERO LAYOUT (VMN NIGHTLIFE THEME)
  // ==========================================
  Widget _buildMobileLayout(
    List<EventSummary> events,
    EventSummary activeEvent,
    int activeIdx,
  ) {
    final eventRoute = '/events/${activeEvent.slug.isNotEmpty ? activeEvent.slug : activeEvent.id}';

    final locParts = [
      if (activeEvent.location != null && activeEvent.location!.isNotEmpty) activeEvent.location!,
      if (activeEvent.city != null && activeEvent.city!.isNotEmpty) activeEvent.city!,
    ].where((s) => s.isNotEmpty).join(', ');
    final displayLoc = locParts.isEmpty ? 'Ahmedabad' : locParts;

    final dateText = [
      if (activeEvent.startDate.isNotEmpty) activeEvent.startDate,
      if (activeEvent.endDate.isNotEmpty && activeEvent.endDate != activeEvent.startDate)
        '- ${activeEvent.endDate}',
    ].join(' ');

    final viewsCount = '${(25 + (activeEvent.id * 3.7)).toStringAsFixed(1)}K';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 3:4 Poster Carousel with Spotlight peek
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth * 0.72;
            final cardHeight = cardWidth / (3 / 4);

            return SizedBox(
              height: cardHeight.clamp(280.0, 440.0) + 14,
              child: PageView.builder(
                controller: _mobilePageController,
                itemCount: events.length,
                onPageChanged: (idx) => setState(() => _activeIndex = idx),
                itemBuilder: (context, index) {
                  final ev = events[index];
                  final isCurrent = index == activeIdx;
                  final targetRoute = '/events/${ev.slug.isNotEmpty ? ev.slug : ev.id}';
                  final posterUrl = ev.thumbnail ?? ev.mainImage;
                  final fallback = _heroFallbacks[index % _heroFallbacks.length];

                  return Center(
                    child: AnimatedScale(
                      scale: isCurrent ? 1.0 : 0.88,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: GestureDetector(
                        onTap: () {
                          if (isCurrent) {
                            context.push(targetRoute);
                          } else {
                            _mobilePageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: isCurrent
                                  ? Border.all(
                                      color: AppColors.neonPurple.withValues(alpha: 0.6),
                                      width: 1.5,
                                    )
                                  : Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              boxShadow: [
                                BoxShadow(
                                  color: isCurrent
                                      ? AppColors.neonPurple.withValues(alpha: 0.35)
                                      : Colors.black.withValues(alpha: 0.3),
                                  blurRadius: isCurrent ? 20 : 8,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: NetworkImageBox(
                                url: posterUrl,
                                fallbackUrl: fallback,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 14),

        // Event Metadata below card (VMN Brand Style)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () => context.push(eventRoute),
            child: Column(
              children: [
                // Event Title
                Text(
                  activeEvent.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),

                // Date Range • Location Subtitle
                Text(
                  [
                    if (dateText.isNotEmpty) dateText,
                    displayLoc,
                  ].where((s) => s.isNotEmpty).join(' • '),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // Sleek VMN Views Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGlass,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.neonPurple.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.remove_red_eye_outlined,
                        color: AppColors.neonPink,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Views ($viewsCount)',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// VMN ARROW BUTTON
// ==========================================
class _VmnArrowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _VmnArrowButton({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_VmnArrowButton> createState() => _VmnArrowButtonState();
}

class _VmnArrowButtonState extends State<_VmnArrowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.neonPurple.withValues(alpha: 0.3)
                : AppColors.surfaceGlass,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered
                  ? AppColors.neonPink.withValues(alpha: 0.6)
                  : AppColors.divider,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.neonPurple.withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            widget.icon,
            color: _isHovered ? AppColors.neonPink : AppColors.textPrimary,
            size: 22,
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
