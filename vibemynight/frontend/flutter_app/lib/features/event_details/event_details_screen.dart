import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/data_providers.dart';
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

/// Full event detail screen matching Figma EventDetailsPage.tsx:
/// - Hero banner with gradient overlay, title, location, dates, and starting price
/// - About Event with meta chips (Dates, Venue, City, Organizer)
/// - Highlights & Interactive Gallery
/// - "CHOOSE YOUR NIGHT" Day selector strip with neon glow
/// - Selected Day performing artists & pass categories with live inventory
/// - Quantity selector & live total calculations
/// - Venue card with directions link, facilities grid, rules accordion, and FAQ
/// - Desktop 2-column layout with sticky booking sidebar card & AppNavbar/AppFooter
class EventDetailsScreen extends ConsumerStatefulWidget {
  final String slug;

  const EventDetailsScreen({super.key, required this.slug});

  @override
  ConsumerState<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends ConsumerState<EventDetailsScreen> {
  int _selectedDayIndex = 0;
  int? _selectedPassId;
  int _quantity = 1;
  int _activeGalleryIndex = 0;
  bool _rulesExpanded = false;
  int? _openFaqIndex;

  static const _faqs = [
    {
      'q': 'Is this event family friendly?',
      'a': 'Yes, families and children are welcome. We have a dedicated family friendly zone and seating.',
    },
    {
      'q': 'What is the dress code?',
      'a': 'Traditional attire (chaniya choli / kurta) is preferred for Garba nights but not mandatory.',
    },
    {
      'q': 'How does the pass confirmation work?',
      'a': 'After submitting your inquiry, our team will instantly connect with you on WhatsApp to confirm your passes and payment.',
    },
    {
      'q': 'Is food & parking available at the venue?',
      'a': 'Yes, a variety of food stalls and managed parking spaces are available at the event venue.',
    },
  ];

  void _openWhatsApp(String? number) {
    final num = number ?? '917041615131';
    final url = 'https://wa.me/$num?text=${Uri.encodeComponent("Hi VibeMyNight team, I have a query regarding passes.")}';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _proceedToInquiry(EventDetail event, EventDayDetail day, TicketCategory? pass) {
    if (pass == null) return;
    context.push(
      '/inquiry?eventDayId=${day.id}&ticketCategoryId=${pass.id}&quantity=$_quantity',
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.slug));
    final settingsAsync = ref.watch(appSettingsProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: AppColors.background,
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

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Global App Navbar
                const AppNavbar(),

                // Hero Banner matching Figma
                Stack(
                  children: [
                    Container(
                      height: 380,
                      width: double.infinity,
                      foregroundDecoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            AppColors.background.withValues(alpha: 0.8),
                            AppColors.background,
                          ],
                        ),
                      ),
                      child: NetworkImageBox(
                        url: event.banner ?? event.mainImage,
                        height: 380,
                        width: double.infinity,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (event.city != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.neonPurple.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.5)),
                                    ),
                                    child: Text(
                                      event.city!.toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.neonPink,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  event.name,
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    if (event.location != null)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.location_on, size: 16, color: AppColors.neonPink),
                                          const SizedBox(width: 4),
                                          Text(event.location!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                        ],
                                      ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14, color: AppColors.neonBlue),
                                        const SizedBox(width: 4),
                                        Text('${event.startDate} → ${event.endDate}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.neonPurple.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${event.days.length} ${event.days.length == 1 ? "Night" : "Nights"}',
                                        style: const TextStyle(color: AppColors.neonPink, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Main Content Body (Desktop: 2 cols, Mobile: 1 col)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column (Col span 2)
                                Expanded(
                                  flex: 5,
                                  child: _buildMainColumn(context, event, selectedDaySummary?.id),
                                ),
                                const SizedBox(width: 32),
                                // Right Sticky Column (Col span 1)
                                Expanded(
                                  flex: 3,
                                  child: _buildSidebarBookingCard(context, event, selectedDaySummary?.id, settingsAsync.value?.whatsappNumber),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _buildMainColumn(context, event, selectedDaySummary?.id),
                                const SizedBox(height: 24),
                                _buildSidebarBookingCard(context, event, selectedDaySummary?.id, settingsAsync.value?.whatsappNumber),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Global Footer
                const AppFooter(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainColumn(BuildContext context, EventDetail event, int? currentDayId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // About Section
        if (event.description != null && event.description!.isNotEmpty) ...[
          const Text('About This Event', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 10),
          Text(
            event.description!,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 16),
        ],

        // 4 Metadata Cards
        Row(
          children: [
            Expanded(child: _buildMetaCard('📅 Dates', '${event.startDate.split('-').last} - ${event.endDate.split('-').last}', '${event.days.length} Nights')),
            const SizedBox(width: 10),
            Expanded(child: _buildMetaCard('📍 Venue', event.venue ?? 'Main Arena', event.city ?? '')),
            const SizedBox(width: 10),
            Expanded(child: _buildMetaCard('👤 Organizer', event.organizer ?? 'VibeMyNight', 'Verified')),
          ],
        ),

        const SizedBox(height: 32),

        // Highlights Section
        if (event.highlights.isNotEmpty) ...[
          const Text('Highlights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: event.highlights.map((h) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.neonPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✦ ', style: TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.bold)),
                    Text(h, style: const TextStyle(color: Color(0xFFC084FC), fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],

        // Interactive Gallery Section
        if (event.galleryImageUrls.isNotEmpty) ...[
          const Text('Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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

        // CHOOSE YOUR NIGHT Section (Figma core feature)
        const Text('Choose Your Night', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)),
        const SizedBox(height: 14),

        if (event.days.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Event schedule will be published soon.', style: TextStyle(color: AppColors.textSecondary)),
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
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Colors.white : Colors.white,
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

          const SizedBox(height: 20),

          // Selected Day Details & Passes
          if (currentDayId != null)
            _buildDayLiveContent(context, currentDayId),
        ],

        const SizedBox(height: 36),

        // Venue Card
        const Text('Venue & Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
          const Text('Facilities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
        const Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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

  Widget _buildMetaCard(String title, String val1, String val2) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 4),
            Text(val1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
            if (val2.isNotEmpty)
              Text(val2, style: const TextStyle(color: AppColors.neonPink, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayLiveContent(BuildContext context, int dayId) {
    final dayAsync = ref.watch(eventDayDetailProvider(dayId));

    return dayAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (err, _) => Text('Error loading day details: $err', style: const TextStyle(color: AppColors.error)),
      data: (day) {
        // Find selected pass object
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
                color: AppColors.neonPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DAY ${day.dayNumber} · ${day.date}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

            // Performing Artists
            if (day.artists.isNotEmpty) ...[
              const Text('Performing Artists', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
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
                        NetworkImageBox(url: a.photoUrl, height: 42, width: 42, borderRadius: BorderRadius.circular(21)),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(a.type, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                        if (a.isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

            // Choose Your Pass Category
            const Text('Choose Your Pass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),

            if (day.passes.isEmpty)
              const Text('No pass categories released for this night yet.', style: TextStyle(color: AppColors.textSecondary))
            else ...[
              // Grid of Passes
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: day.passes.map((p) {
                  final isSelected = (currentPass?.id == p.id);
                  final isSoldOut = p.soldOut || p.availableQuantity == 0;
                  final isLowStock = p.lowStock;

                  return InkWell(
                    onTap: isSoldOut ? null : () => setState(() => _selectedPassId = p.id),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 240,
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
                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹${p.price.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.neonPink),
                          ),
                          const SizedBox(height: 8),
                          if (p.benefits.isNotEmpty)
                            ...p.benefits.map((b) => Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Row(
                                    children: [
                                      const Text('✓ ', style: TextStyle(color: AppColors.neonBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                                      Expanded(child: Text(b, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11))),
                                    ],
                                  ),
                                )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Quantity Stepper
              if (currentPass != null && !currentPass.soldOut)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGlass,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Max ${currentPass.maxPerCustomer} per customer', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                          ),
                          Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _quantity < currentPass.maxPerCustomer ? () => setState(() => _quantity++) : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSidebarBookingCard(BuildContext context, EventDetail event, int? currentDayId, String? whatsappNumber) {
    if (currentDayId == null) return const SizedBox.shrink();
    final dayAsync = ref.watch(eventDayDetailProvider(currentDayId));

    return dayAsync.when(
      loading: () => const GlassCard(child: Padding(padding: EdgeInsets.all(24), child: LoadingView())),
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

        return GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pass Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),

                if (currentPass != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.neonPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${currentPass.name} · Day ${day.dayNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('${day.date} · ${day.programName ?? ""}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('₹${currentPass.price.toStringAsFixed(0)} × $_quantity', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.neonPink)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GradientButton(
                    label: 'INQUIRE PASSES',
                    onPressed: () => _proceedToInquiry(event, day, currentPass),
                  ),
                ] else ...[
                  const Text('Select a pass category on the left to proceed with booking.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],

                const SizedBox(height: 12),

                // Direct WhatsApp Button
                OutlinedButton.icon(
                  icon: const Icon(Icons.chat, size: 16, color: Color(0xFF25D366)),
                  label: const Text('Chat on WhatsApp', style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.bold, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: const Color(0xFF25D366).withValues(alpha: 0.5)),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: () => _openWhatsApp(whatsappNumber),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

