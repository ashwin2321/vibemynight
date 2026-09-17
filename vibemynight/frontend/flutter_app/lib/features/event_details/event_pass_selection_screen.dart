import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/data_providers.dart';
import '../../core/providers/dome_layout_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_footer.dart';
import '../../core/widgets/app_navbar.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/network_image_box.dart';
import '../../models/event_day_detail.dart';
import '../../models/event_detail.dart';
import '../../models/ticket_category.dart';
import 'widgets/interactive_venue_layout_map.dart';

/// Dedicated Date & Pass Tier Selection Screen (Desktop & Mobile):
/// - Step 1: Select Event Date / Night (Day 1, Day 2, etc.)
/// - Step 2: Choose Pass Category (Regular, Couple, VIP) with instant counter [- 1 +]
/// - Desktop: Split layout with Left Pass selection & Right Sticky Booking Breakdown
/// - Mobile: Horizontal date pills, pass cards list, and floating bottom booking bar
class EventPassSelectionScreen extends ConsumerStatefulWidget {
  final String slug;
  final int? initialDayId;

  const EventPassSelectionScreen({
    super.key,
    required this.slug,
    this.initialDayId,
  });

  @override
  ConsumerState<EventPassSelectionScreen> createState() => _EventPassSelectionScreenState();
}

class _EventPassSelectionScreenState extends ConsumerState<EventPassSelectionScreen> {
  int _selectedDayIndex = 0;
  int? _selectedPassId;
  int _quantity = 1;
  bool _dayInitialized = false;

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
                if (days.isEmpty) return null;
                final selectedDay = _selectedDayIndex < days.length ? days[_selectedDayIndex] : days.first;
                return _buildMobileBottomBar(
                  context,
                  event,
                  selectedDay.id,
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

          // Initial day lookup if initialDayId was provided
          if (!_dayInitialized && widget.initialDayId != null && days.isNotEmpty) {
            final idx = days.indexWhere((d) => d.id == widget.initialDayId);
            if (idx != -1) {
              _selectedDayIndex = idx;
            }
            _dayInitialized = true;
          }

          final selectedDaySummary = days.isNotEmpty && _selectedDayIndex < days.length
              ? days[_selectedDayIndex]
              : (days.isNotEmpty ? days.first : null);

          if (isDesktop) {
            return Column(
              children: [
                const AppNavbar(),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1360),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Pass & Date Selection Area
                            Expanded(
                              flex: 66,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(right: 24, bottom: 60),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildBreadcrumb(context, event),
                                    const SizedBox(height: 12),
                                    _buildHeader(event),
                                    const SizedBox(height: 24),
                                    _buildDateSelector(event),
                                    const SizedBox(height: 28),
                                    if (selectedDaySummary != null)
                                      _buildPassesSection(context, event, selectedDaySummary.id),
                                    const SizedBox(height: 60),
                                    const AppFooter(),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Right Sticky Pass Breakdown Sidebar
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

          // Mobile View
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppNavbar(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBreadcrumb(context, event),
                      const SizedBox(height: 8),
                      _buildHeader(event),
                      const SizedBox(height: 20),
                      _buildDateSelector(event),
                      const SizedBox(height: 24),
                      if (selectedDaySummary != null)
                        _buildPassesSection(context, event, selectedDaySummary.id),
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
    return Row(
      children: [
        InkWell(
          onTap: () => context.go('/events/${event.slug}'),
          borderRadius: BorderRadius.circular(6),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_ios_new, size: 13, color: AppColors.textSecondary),
                SizedBox(width: 6),
                Text('Event Details', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const Text('  /  ', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const Text('Select Passes', style: TextStyle(color: AppColors.neonPink, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildHeader(EventDetail event) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF130E26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E2452)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: NetworkImageBox(
              url: event.thumbnail ?? event.mainImage,
              height: 72,
              width: 72,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.neonBlue),
                        const SizedBox(width: 4),
                        Text(
                          event.venue ?? event.city ?? 'Ahmedabad',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 13, color: AppColors.neonPink),
                        const SizedBox(width: 4),
                        Text(
                          '${event.startDate} → ${event.endDate}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(EventDetail event) {
    if (event.days.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. Choose Event Date',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: -0.3),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select the date/night you wish to attend.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(event.days.length, (idx) {
              final d = event.days[idx];
              final isSelected = idx == _selectedDayIndex;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() {
                    _selectedDayIndex = idx;
                    _selectedPassId = null;
                    _quantity = 1;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : const Color(0xFF16102E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFF472B6) : const Color(0xFF2E2452),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFEC4899).withValues(alpha: 0.35),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.neonPurple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'DAY ${d.dayNumber}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Colors.white : AppColors.neonPink,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          d.date,
                          style: const TextStyle(
                            fontSize: 16,
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
      ],
    );
  }

  Widget _buildPassesSection(BuildContext context, EventDetail event, int dayId) {
    final dayAsync = ref.watch(eventDayDetailProvider(dayId));
    final isDomeEnabled = ref.watch(domeLayoutProvider).isEnabledFor(event);

    return dayAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: LoadingView())),
      error: (err, _) => Text('Error loading day passes: $err', style: const TextStyle(color: AppColors.error)),
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

        final headliner = day.primaryArtist;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day Headliner & Timing Strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF16102E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF38296B)),
              ),
              child: Row(
                children: [
                  if (headliner != null) ...[
                    NetworkImageBox(url: headliner.photoUrl, height: 48, width: 48, borderRadius: BorderRadius.circular(24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.neonPink.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '★ HEADLINER',
                                  style: TextStyle(color: AppColors.neonPink, fontSize: 9, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(headliner.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                          Text(headliner.type, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Text(
                        'Day ${day.dayNumber} Schedule & Passes',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                      ),
                    ),
                  ],
                  if (day.startTime != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2E2452)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 14, color: AppColors.neonBlue),
                          const SizedBox(width: 5),
                          Text(
                            '${day.startTime} - ${day.endTime ?? ""}',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Interactive Dome Layout if applicable
            if (isDomeEnabled && day.passes.isNotEmpty) ...[
              const Text('2. Select AC Dome Stand / Tier', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
              const SizedBox(height: 12),
              InteractiveVenueLayoutMap(
                passes: day.passes,
                selectedPassId: currentPass?.id,
                onPassSelected: (pass) {
                  setState(() {
                    _selectedPassId = pass.id;
                  });
                },
              ),
              const SizedBox(height: 18),
            ] else ...[
              const Text(
                '2. Choose Pass Category',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: -0.3),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select pass tier with instant WhatsApp QR pass delivery.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
              const SizedBox(height: 16),
            ],

            if (day.passes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF16102E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'No pass tiers released for this night yet. Chat on WhatsApp for priority booking assistance.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 580;
                  final cardWidth = isWide ? (constraints.maxWidth - 16) / 2 : double.infinity;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: day.passes.map((p) {
                      final isSelected = (currentPass?.id == p.id);
                      final isSoldOut = p.soldOut || p.availableQuantity == 0;
                      final isLowStock = p.lowStock;

                      return InkWell(
                        onTap: isSoldOut
                            ? null
                            : () {
                                setState(() {
                                  _selectedPassId = p.id;
                                });
                              },
                        borderRadius: BorderRadius.circular(18),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: cardWidth,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1E153D) : const Color(0xFF130E26),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFEC4899)
                                  : (isSoldOut ? const Color(0xFF261D45) : const Color(0xFF2B2050)),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFEC4899).withValues(alpha: 0.25),
                                      blurRadius: 20,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (p.type.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              p.type.toUpperCase(),
                                              style: const TextStyle(color: AppColors.neonPurple, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSoldOut)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(6)),
                                      child: const Text('SOLD OUT', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  else if (isLowStock)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                      child: Text('Only ${p.availableQuantity} left', style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                                      ),
                                      child: const Text('Fast Filling 🔥', style: TextStyle(color: Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '₹${p.price.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFF43F5E)),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('/ pass', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ),

                              const SizedBox(height: 12),
                              const Divider(height: 1, color: Color(0xFF261D45)),
                              const SizedBox(height: 12),

                              if (p.benefits.isNotEmpty)
                                ...p.benefits.map((b) => Padding(
                                      padding: const EdgeInsets.only(bottom: 5),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('✓ ', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                                          Expanded(child: Text(b, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3))),
                                        ],
                                      ),
                                    ))
                              else ...[
                                const Row(
                                  children: [
                                    Text('✓ ', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text('Guaranteed Entry to Arena', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Row(
                                  children: [
                                    Text('✓ ', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text('Instant Digital QR Delivery', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 14),

                              if (isSoldOut)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('UNAVAILABLE', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                                )
                              else if (isSelected)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.check_circle, size: 16, color: Color(0xFFEC4899)),
                                          SizedBox(width: 6),
                                          Text('Selected Pass', style: TextStyle(color: Color(0xFFF472B6), fontWeight: FontWeight.w800, fontSize: 12)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                                            borderRadius: BorderRadius.circular(4),
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: _quantity > 1 ? Colors.white24 : Colors.transparent,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Icon(Icons.remove, size: 14, color: _quantity > 1 ? Colors.white : Colors.white30),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            child: Text(
                                              '$_quantity',
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => setState(() => _quantity++),
                                            borderRadius: BorderRadius.circular(4),
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: Colors.white24,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Icon(Icons.add, size: 14, color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF261D45),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('Select Pass', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildStickySidebar(BuildContext context, EventDetail event, int? currentDayId, String? whatsappNumber) {
    if (currentDayId == null) return const SizedBox.shrink();
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Booking Summary',
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
                      Text(
                        currentPass.name,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        day.programName != null && day.programName!.isNotEmpty ? day.programName! : event.name,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Divider(height: 22, color: Color(0xFF2A204E)),
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

                const SizedBox(height: 18),

                GradientButton(
                  label: 'PROCEED TO INQUIRY',
                  height: 48,
                  onPressed: () => _proceedToInquiry(event, day, currentPass),
                ),
              ],

              const SizedBox(height: 12),

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
