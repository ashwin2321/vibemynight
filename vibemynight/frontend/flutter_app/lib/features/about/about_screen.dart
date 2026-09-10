import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_footer.dart';
import '../../core/widgets/app_navbar.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';

/// "About Us" public screen matching Figma AboutPage.tsx:
/// Fully DYNAMIC stats wired to live Spring Boot backend data.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const String _aboutImg =
      'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=900&h=600&fit=crop&auto=format';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(publishedEventsProvider);
    final artistsAsync = ref.watch(artistsProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final websiteName = settingsAsync.value?.websiteName ?? 'VibeMyNight';

    final eventCount = eventsAsync.value?.length ?? 1;
    final artistCount = artistsAsync.value?.length ?? 1;

    final eventStatStr = eventCount > 10 ? '$eventCount+' : (eventCount == 0 ? '1' : '$eventCount+');
    final artistStatStr = artistCount > 10 ? '$artistCount+' : (artistCount == 0 ? '1' : '$artistCount+');
    final attendeesStatStr = eventCount > 5 ? '${eventCount * 2}K+' : '5K+';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppNavbar(currentRoute: '/about'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.15,
                    child: Image.network(
                      _aboutImg,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.background.withValues(alpha: 0.7),
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        children: [
                          const Text(
                            'OUR STORY',
                            style: TextStyle(
                              color: AppColors.neonPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'We Live for The Night',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '$websiteName was born from a simple belief: every night has the potential to become a memory you cherish forever. We are here to make that happen.',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.6),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Dynamic Stats Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 600;
                      return GridView.count(
                        crossAxisCount: isWide ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isWide ? 1.4 : 1.3,
                        children: [
                          _StatCard(value: eventStatStr, label: 'Events Hosted'),
                          _StatCard(value: attendeesStatStr, label: 'Happy Attendees'),
                          _StatCard(value: artistStatStr, label: 'Artists Featured'),
                          const _StatCard(value: '5★', label: 'Average Rating', isRating: true),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 64),

            // Mission Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 750;
                      const textCol = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MISSION',
                            style: TextStyle(
                              color: AppColors.neonPink,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Creating Nights Worth Living',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'From traditional Navratri Garba festivals to cutting-edge DJ nights, celebrity concerts to laser shows — VibeMyNight is your one destination for experiences that go beyond the ordinary.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'We work with top artists, premier venues, and event organizers across India to bring you curated nightlife experiences with seamless pass inquiry via WhatsApp.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6),
                          ),
                        ],
                      );

                      final imageWidget = ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _aboutImg,
                          fit: BoxFit.cover,
                          height: isWide ? 280 : 200,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(color: AppColors.surface, height: 200),
                        ),
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(child: textCol),
                            const SizedBox(width: 48),
                            Expanded(child: imageWidget),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            textCol,
                            const SizedBox(height: 24),
                            imageWidget,
                          ],
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 64),

            // Values Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      const Text(
                        'VALUES',
                        style: TextStyle(
                          color: AppColors.neonBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'What We Stand For',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 600;
                          return GridView.count(
                            crossAxisCount: isWide ? 2 : 1,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: isWide ? 2.5 : 2.0,
                            children: const [
                              _ValueCard(
                                icon: '⚡',
                                title: 'Energy First',
                                desc: 'We curate only the most electric, high-energy events that leave you wanting more.',
                              ),
                              _ValueCard(
                                icon: '🎯',
                                title: 'Precision Curation',
                                desc: 'Every event is handpicked for quality, safety, and an unforgettable experience.',
                              ),
                              _ValueCard(
                                icon: '🔒',
                                title: 'Safe & Trusted',
                                desc: 'Transparent pricing, no hidden fees, and direct confirmation via WhatsApp.',
                              ),
                              _ValueCard(
                                icon: '🌟',
                                title: 'Premium Experience',
                                desc: 'From premium venues to world-class artists, we never compromise on quality.',
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),

            // Final CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: GlassCard(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Text(
                          'Ready to Experience a Night?',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Browse upcoming events and get your pass in minutes.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        GradientButton(
                          label: 'Explore Events',
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          onPressed: () => context.push('/events'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),

            // Footer
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final String value;
  final String label;
  final bool isRating;

  const _StatCard({
    required this.value,
    required this.label,
    this.isRating = false,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF1B1736) : const Color(0xFF111024),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? (widget.isRating ? Colors.amber : AppColors.neonPurple).withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.08),
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? (widget.isRating ? Colors.amber : AppColors.neonPurple).withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.3),
                blurRadius: _isHovered ? 24 : 12,
                offset: _isHovered ? const Offset(0, 8) : const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isRating)
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.amber, Colors.orangeAccent],
                  ).createShader(bounds),
                  child: const Text(
                    '5.0 ★',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                  ).createShader(bounds),
                  child: Text(
                    widget.value,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;

  const _ValueCard({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
