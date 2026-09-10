import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/data_providers.dart';
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
/// - Interactive Category Filter Chips Bar (Navratri 2026, DJ & EDM, Live Concerts, VIP Exclusives).
/// - Featured Nights: Responsive 3:4 Poster Event Cards with floating date pills, price tags & neon glow.
/// - Circular "Events by Artist & DJs" strip with smooth left/right chevron navigation.
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

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(publishedEventsProvider);
    final artistsAsync = ref.watch(artistsProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final whatsappNumber = settingsAsync.value?.whatsappNumber ?? '917041615131';

    return Scaffold(
      backgroundColor: const Color(0xFF07070E),
      appBar: const AppNavbar(currentRoute: '/'),
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
              // 1. HERO SECTION
              _HeroSection(whatsappNumber: whatsappNumber),

              // 2. CATEGORY FILTER CHIPS BAR
              _CategoryFilterBar(
                selectedCategory: _selectedCategory,
                onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
              ),

              // 3. FEATURED NIGHTS SECTION (DYNAMIC 3:4 POSTERS)
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
// 1. HERO SECTION
// ==========================================
class _HeroSection extends StatelessWidget {
  final String whatsappNumber;

  const _HeroSection({required this.whatsappNumber});

  Future<void> _launchWhatsApp() async {
    final clean = whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;
    final isSmallMobile = size.width < 400;

    return Container(
      constraints: BoxConstraints(
        minHeight: isDesktop ? 620 : 460,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background photo
          Positioned.fill(
            child: Image.network(
              HomeScreen._heroImg,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0F0B1E)),
            ),
          ),
          // Dark gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xEB07070E),
                    Color(0xB307070E),
                    Color(0x6607070E),
                  ],
                ),
              ),
            ),
          ),
          // Top glow blob
          Positioned(
            top: -40,
            left: isDesktop ? size.width * 0.3 : 20,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 48 : (isSmallMobile ? 16 : 20),
              vertical: isDesktop ? 80 : 36,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Events Now Live pill badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                        ),
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
                            'Events Now Live',
                            style: TextStyle(
                              color: Color(0xFFC084FC),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Big Headline: Experience The Night. Create The Memory.
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Experience The Night.\n',
                            style: TextStyle(
                              fontSize: isDesktop ? 54 : (isSmallMobile ? 28 : 34),
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -1,
                            ),
                          ),
                          WidgetSpan(
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFA855F7),
                                  Color(0xFFEC4899),
                                  Color(0xFF60A5FA),
                                ],
                              ).createShader(bounds),
                              child: Text(
                                'Create The Memory.',
                                style: TextStyle(
                                  fontSize: isDesktop ? 54 : (isSmallMobile ? 28 : 34),
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.1,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Subtitle
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 580),
                      child: Text(
                        'Discover the best events, artists and unforgettable experiences with VibeMyNight.',
                        style: TextStyle(
                          fontSize: isDesktop ? 18 : 15,
                          color: Colors.white.withValues(alpha: 0.65),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // CTA Buttons
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        GradientButton(
                          label: 'Explore Events',
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          onPressed: () => context.push('/events'),
                        ),
                        InkWell(
                          onTap: _launchWhatsApp,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 26),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Get Your Pass',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Scroll indicator
          Positioned(
            bottom: 16,
            child: Column(
              children: [
                Text(
                  'SCROLL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ],
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
        isDesktop ? 48 : 20,
        28,
        isDesktop ? 48 : 20,
        12,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
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
// 3. FEATURED NIGHTS SECTION (DYNAMIC 3:4 POSTERS)
// ==========================================
class _FeaturedNightsSection extends ConsumerWidget {
  final AsyncValue<List<EventSummary>> eventsAsync;
  final String selectedCategory;

  const _FeaturedNightsSection({
    required this.eventsAsync,
    this.selectedCategory = 'All Events',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1000;
    final isTablet = size.width >= 600 && size.width < 1000;
    final cols = isDesktop ? 4 : (isTablet ? 2 : 1);

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
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Featured Nights',
                          style: TextStyle(
                            fontSize: isDesktop ? 32 : 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Discover the most happening events and book official passes',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () => context.push('/events'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All Events',
                          style: TextStyle(
                            color: Color(0xFFA855F7),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, color: Color(0xFFA855F7), size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Dynamic Events Grid with 3:4 Poster EventCard
              eventsAsync.when(
                loading: () => ShimmerCardGrid(count: cols * 2, cardHeight: 380),
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
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh, size: 16),
                          onPressed: () => ref.invalidate(publishedEventsProvider),
                          label: const Text('Refresh Events'),
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
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 580),
                            child: const Text(
                              'We are curating the biggest AC Dome Garba nights, EDM concerts, and celebrity lineups for 2026. Connect on WhatsApp for early-bird booking alerts and VIP reservations.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                                label: const Text(
                                  'WhatsApp Pass Inquiries',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  final uri = Uri.parse(
                                    'https://wa.me/917041615131?text=Hi%20VibeMyNight!%20I%20want%20to%20inquire%20about%20upcoming%20passes%20and%20VIP%20tables.',
                                  );
                                  launchUrl(uri, mode: LaunchMode.externalApplication);
                                },
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.explore, size: 18, color: Colors.white),
                                label: const Text(
                                  'Explore Artists',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white24),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => context.push('/artists'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  // Filter by category if selected
                  var filtered = events;
                  if (selectedCategory == 'Navratri 2026') {
                    filtered = events.where((e) => e.name.toLowerCase().contains('garba') || e.name.toLowerCase().contains('navratri') || (e.location?.toLowerCase().contains('garba') ?? false)).toList();
                  } else if (selectedCategory == 'DJ & EDM') {
                    filtered = events.where((e) => e.name.toLowerCase().contains('dj') || e.name.toLowerCase().contains('edm') || (e.featuredArtistName?.toLowerCase().contains('dj') ?? false)).toList();
                  } else if (selectedCategory == 'Live Concerts') {
                    filtered = events.where((e) => e.name.toLowerCase().contains('concert') || e.name.toLowerCase().contains('live') || (e.featuredArtistName?.isNotEmpty ?? false)).toList();
                  } else if (selectedCategory == 'VIP Exclusives') {
                    filtered = events.where((e) => e.featured).toList();
                  }
                  if (filtered.isEmpty) filtered = events;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = (constraints.maxWidth - (cols - 1) * 16) / cols;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 20,
                        children: filtered.take(8).map((event) {
                          return SizedBox(
                            width: itemWidth,
                            child: EventCard(
                              event: event,
                              imageHeight: isDesktop ? 220 : 190,
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
// 3. UPCOMING EVENTS SECTION (DYNAMIC)
// ==========================================
class _UpcomingEventsSection extends StatelessWidget {
  final AsyncValue<List<EventSummary>> eventsAsync;

  const _UpcomingEventsSection({required this.eventsAsync});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;
    final isTablet = size.width >= 600 && size.width < 900;
    final cols = isDesktop ? 3 : (isTablet ? 2 : 1);

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
