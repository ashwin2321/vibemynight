import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_footer.dart';
import '../../core/widgets/app_navbar.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';

/// "About Us" public screen matching Figma AboutPage.tsx.
/// Hero, Stats cards, Mission story with image, Core Values, CTA, and Footer.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _aboutImg =
      'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=900&h=600&fit=crop&auto=format';

  @override
  Widget build(BuildContext context) {
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
                      child: const Column(
                        children: [
                          Text(
                            'OUR STORY',
                            style: TextStyle(
                              color: AppColors.neonPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'We Live for The Night',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'VibeMyNight was born from a simple belief: every night has the potential to become a memory you cherish forever. We are here to make that happen.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.6),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Stats Section
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
                        children: const [
                          _StatCard(value: '50+', label: 'Events Hosted'),
                          _StatCard(value: '20K+', label: 'Happy Attendees'),
                          _StatCard(value: '100+', label: 'Artists Featured'),
                          _StatCard(value: '5★', label: 'Average Rating'),
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

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.neonPurple,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
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
