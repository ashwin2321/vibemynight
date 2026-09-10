import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_footer.dart';
import '../../core/widgets/app_navbar.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/fade_in.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/network_image_box.dart';
import 'widgets/artist_card.dart';

/// Public artist list screen matching Figma Artists layout.
class ArtistsScreen extends ConsumerWidget {
  const ArtistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(artistsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppNavbar(currentRoute: '/artists'),
      bottomNavigationBar: const AppBottomNav(currentRoute: '/artists'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FEATURED TALENT',
                        style: TextStyle(color: AppColors.neonPurple, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2),
                      ),
                      const SizedBox(height: 6),
                      const Text('Artists & Performers', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 6),
                      const Text('Discover the top artists and performers headlining upcoming nights.', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                      const SizedBox(height: 32),
                      artistsAsync.when(
                        loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: LoadingView())),
                        error: (err, _) => ErrorView(message: err.toString(), onRetry: () => ref.invalidate(artistsProvider)),
                        data: (artists) {
                          if (artists.isEmpty) {
                            return const Center(child: Padding(padding: EdgeInsets.all(48), child: Text('No artists announced yet.', style: TextStyle(color: AppColors.textSecondary))));
                          }
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final crossAxisCount = width > 900 ? 4 : (width > 600 ? 3 : 2);
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.78,
                                ),
                                itemCount: artists.length,
                                itemBuilder: (context, index) => FadeIn(
                                  delay: Duration(milliseconds: index * 40),
                                  child: ArtistCard(artist: artists[index]),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}

/// Artist detail screen matching Figma ArtistDetailsPage.tsx.
class ArtistDetailsScreen extends ConsumerWidget {
  final int artistId;

  const ArtistDetailsScreen({super.key, required this.artistId});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistAsync = ref.watch(artistByIdProvider(artistId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppNavbar(currentRoute: '/artists'),
      body: artistAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(artistByIdProvider(artistId)),
        ),
        data: (artist) => SingleChildScrollView(
          child: Column(
            children: [
              // Hero Banner & Portrait Card
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 280,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.neonPurple.withValues(alpha: 0.3),
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 650;
                            final portraitWidget = Container(
                              width: isWide ? 180 : 130,
                              height: isWide ? 220 : 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.5), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.neonPurple.withValues(alpha: 0.25),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: NetworkImageBox(url: artist.photoUrl, fit: BoxFit.cover),
                              ),
                            );

                            final infoWidget = Column(
                              crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.neonPurple.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    artist.type.toUpperCase(),
                                    style: const TextStyle(color: Color(0xFFC084FC), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  artist.name,
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                                  textAlign: isWide ? TextAlign.left : TextAlign.center,
                                ),
                                if (artist.shortBio != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    artist.shortBio!,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                    textAlign: isWide ? TextAlign.left : TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
                                  children: [
                                    if (artist.instagramUrl != null && artist.instagramUrl!.isNotEmpty)
                                      _SocialBadge(label: 'Instagram', color: const Color(0xFFE1306C), onTap: () => _launchUrl(artist.instagramUrl!)),
                                    if (artist.facebookUrl != null && artist.facebookUrl!.isNotEmpty)
                                      _SocialBadge(label: 'Facebook', color: const Color(0xFF1877F2), onTap: () => _launchUrl(artist.facebookUrl!)),
                                    if (artist.youtubeUrl != null && artist.youtubeUrl!.isNotEmpty)
                                      _SocialBadge(label: 'YouTube', color: const Color(0xFFFF0000), onTap: () => _launchUrl(artist.youtubeUrl!)),
                                  ],
                                ),
                              ],
                            );

                            if (isWide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  portraitWidget,
                                  const SizedBox(width: 32),
                                  Expanded(child: infoWidget),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  portraitWidget,
                                  const SizedBox(height: 20),
                                  infoWidget,
                                ],
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Main Details and Sidebar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 750;
                        final mainContent = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (artist.fullBio != null && artist.fullBio!.isNotEmpty) ...[
                              const Text('About', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 12),
                              Text(
                                artist.fullBio!,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.6),
                              ),
                              const SizedBox(height: 32),
                            ],
                            const Text('Live Experience', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 12),
                            const Text(
                              'Catch this artist performing live at our curated nights. Passes are limited and sell out quickly.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.5),
                            ),
                            const SizedBox(height: 24),
                            GradientButton(
                              label: 'Explore Upcoming Events',
                              onPressed: () => context.push('/events'),
                            ),
                          ],
                        );

                        final sidebarContent = GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Watch Live', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                              const SizedBox(height: 8),
                              Text('Experience ${artist.name} live on stage with full lights, sound and energy.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                              const SizedBox(height: 20),
                              GradientButton(
                                label: 'Browse Events',
                                onPressed: () => context.push('/events'),
                              ),
                            ],
                          ),
                        );

                        if (isDesktop) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: mainContent),
                              const SizedBox(width: 32),
                              Expanded(flex: 2, child: sidebarContent),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              mainContent,
                              const SizedBox(height: 32),
                              sidebarContent,
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 64),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialBadge extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialBadge({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
