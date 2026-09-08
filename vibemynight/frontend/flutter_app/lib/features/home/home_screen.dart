import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/data_providers.dart';
import '../../core/widgets/app_footer.dart';
import '../../core/widgets/app_navbar.dart';
import '../../core/widgets/gradient_button.dart';
import '../../models/artist.dart';
import '../../models/event_summary.dart';

/// Full Figma-faithful Home Page matching Figma HomePage.tsx:
/// - 100% DYNAMIC: All Featured Nights, Upcoming Events, and Featured Artists
///   are loaded directly from the live Spring Boot Backend APIs.
/// - Hero with concert crowd background, "Events Now Live" pill, bold gradient typography, CTA buttons & scroll indicator.
/// - Featured Nights: Responsive grid of rich dynamic event cards with badges, prices, and direct links.
/// - Upcoming Events: Responsive grid of compact dynamic event cards.
/// - Why VibeMyNight: 4 glass cards with neon icon badges.
/// - Featured Artists: Live lineup cards loaded dynamically from backend.
/// - Event Experiences: Interactive pill tags.
/// - Final CTA: Nightclub banner with gradient headline.
/// - AppFooter: Full multi-column footer with dynamic settings.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _heroImg =
      'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=1600&h=900&fit=crop&auto=format';
  static const _ctaImg =
      'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=1600&h=700&fit=crop&auto=format';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

              // 2. FEATURED NIGHTS SECTION (100% DYNAMIC)
              _FeaturedNightsSection(eventsAsync: eventsAsync),

              // 3. UPCOMING EVENTS SECTION (100% DYNAMIC)
              _UpcomingEventsSection(eventsAsync: eventsAsync),

              // 4. WHY VIBEMYNIGHT SECTION
              const _WhyVibeMyNightSection(),

              // 5. FEATURED ARTISTS SECTION (100% DYNAMIC)
              _FeaturedArtistsSection(artistsAsync: artistsAsync),

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

    return Container(
      constraints: BoxConstraints(
        minHeight: isDesktop ? 620 : 500,
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
              horizontal: isDesktop ? 48 : 20,
              vertical: isDesktop ? 80 : 48,
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
                              fontSize: isDesktop ? 54 : 32,
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
                                  fontSize: isDesktop ? 54 : 32,
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
// 2. FEATURED NIGHTS SECTION (DYNAMIC)
// ==========================================
class _FeaturedNightsSection extends StatelessWidget {
  final AsyncValue<List<EventSummary>> eventsAsync;

  const _FeaturedNightsSection({required this.eventsAsync});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1000;
    final isTablet = size.width >= 600 && size.width < 1000;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 20,
        vertical: 48,
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
                  Column(
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
                        'Discover the most happening events right now.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => context.push('/events'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
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

              // Dynamic Events Grid
              eventsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Text('Unable to load events: $err', style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => context.push('/admin/events'),
                          child: const Text('Manage in Admin Panel'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (events) {
                  if (events.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.event_note, size: 48, color: Color(0xFFA855F7)),
                          const SizedBox(height: 12),
                          const Text(
                            'No published events yet.',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Create and publish events in the Admin panel to display them here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Create Event in Admin'),
                            onPressed: () => context.push('/admin/events/new'),
                          ),
                        ],
                      ),
                    );
                  }

                  final featuredList = events.where((e) => e.featured).toList();
                  final displayList = featuredList.isNotEmpty ? featuredList : events;
                  final count = isDesktop ? 4 : (isTablet ? 2 : 1);

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = (constraints.maxWidth - (count - 1) * 16) / count;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: displayList.take(4).map((event) {
                          return SizedBox(
                            width: itemWidth,
                            child: _DynamicEventCard(event: event),
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

class _DynamicEventCard extends StatelessWidget {
  final EventSummary event;

  const _DynamicEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final image = event.mainImage ??
        event.thumbnail ??
        'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&h=400&fit=crop&auto=format';
    final targetRoute = '/events/${event.slug.isNotEmpty ? event.slug : event.id}';

    return InkWell(
      onTap: () => context.push(targetRoute),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF12122A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badge
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1E1E38),
                      child: const Center(
                        child: Icon(Icons.nightlife, color: Colors.white30, size: 40),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xCC07070E), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: event.featured ? const Color(0xFFA855F7) : const Color(0xFFEC4899),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.featured ? 'FEATURED' : event.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📍 ${event.location ?? ''}${event.location != null && event.city != null ? ', ' : ''}${event.city ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '📅 ${event.startDate}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      Text(
                        '🎤 ${event.featuredArtistName ?? 'Live Artists'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0x1AFFFFFF)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'from',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          Text(
                            event.startingPrice != null ? '₹${event.startingPrice!.toInt()}' : '₹499',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFA855F7),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          'View Event',
                          style: TextStyle(
                            color: Color(0xFFC084FC),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
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
// 5. FEATURED ARTISTS SECTION (DYNAMIC)
// ==========================================
class _FeaturedArtistsSection extends StatelessWidget {
  final AsyncValue<List<Artist>> artistsAsync;

  const _FeaturedArtistsSection({required this.artistsAsync});

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
                'LINEUP',
                style: TextStyle(
                  color: Color(0xFFA855F7),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Featured Artists',
                style: TextStyle(
                  fontSize: isDesktop ? 32 : 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),

              // Dynamic Artist Strip
              artistsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (artists) {
                  if (artists.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'No artists registered yet.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: artists.map((a) {
                        final img = a.photoUrl ??
                            'https://images.unsplash.com/photo-1496337589254-7e19d01cec44?w=300&h=300&fit=crop&auto=format';

                        return Container(
                          width: 190,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF12122A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(
                                aspectRatio: 1,
                                child: Image.network(
                                  img,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFF1E1E38),
                                    child: const Center(
                                      child: Icon(Icons.person, color: Colors.white24, size: 48),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      a.type,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
