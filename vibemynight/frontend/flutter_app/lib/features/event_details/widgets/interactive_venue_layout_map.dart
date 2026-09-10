import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/ticket_category.dart';

/// District.in & Showmates-inspired Interactive Venue / Seating & Standing Layout Map
/// Features:
/// 1. Visual Stage with T-catwalk extension
/// 2. Dynamic Stand Blocks mapped directly to event passes with actual Pass Names & Prices
/// 3. Side Seating Wings & Standing Arena designations
/// 4. 1-Tap Filter chips in sync with stand selection and sticky pass summary
class InteractiveVenueLayoutMap extends StatefulWidget {
  final List<TicketCategory> passes;
  final int? selectedPassId;
  final ValueChanged<TicketCategory> onPassSelected;

  const InteractiveVenueLayoutMap({
    super.key,
    required this.passes,
    required this.selectedPassId,
    required this.onPassSelected,
  });

  @override
  State<InteractiveVenueLayoutMap> createState() => _InteractiveVenueLayoutMapState();
}

class _StandTierConfig {
  final String key;
  final String defaultTitle;
  final Color activeBg;
  final Color idleBg;
  final Color activeBorder;
  final Color idleBorder;
  final Color activeText;
  final Color idleText;
  final Color badgeBg;
  final Color badgeText;

  const _StandTierConfig({
    required this.key,
    required this.defaultTitle,
    required this.activeBg,
    required this.idleBg,
    required this.activeBorder,
    required this.idleBorder,
    required this.activeText,
    required this.idleText,
    required this.badgeBg,
    required this.badgeText,
  });
}

class _InteractiveVenueLayoutMapState extends State<InteractiveVenueLayoutMap> {
  int? _activePassId;

  static const _tierThemes = [
    // 0: Fanpit / Front Stage (Purple / Lavender)
    _StandTierConfig(
      key: 'FANPIT',
      defaultTitle: 'FANPIT',
      activeBg: Color(0xFFD8D1FF),
      idleBg: Color(0xFFEDE9FE),
      activeBorder: Color(0xFF7C3AED),
      idleBorder: Color(0xFFDDD6FE),
      activeText: Color(0xFF432C81),
      idleText: Color(0xFF6D28D9),
      badgeBg: Color(0xFF7C3AED),
      badgeText: Colors.white,
    ),
    // 1: Diamond / Mid Arena (Rose / Pink)
    _StandTierConfig(
      key: 'DIAMOND',
      defaultTitle: 'DIAMOND',
      activeBg: Color(0xFFFAD2DB),
      idleBg: Color(0xFFFCE7F3),
      activeBorder: Color(0xFFE11D48),
      idleBorder: Color(0xFFFECDD3),
      activeText: Color(0xFF831843),
      idleText: Color(0xFFBE123C),
      badgeBg: Color(0xFFE11D48),
      badgeText: Colors.white,
    ),
    // 2: Gold / Rear Arena (Warm Amber / Gold)
    _StandTierConfig(
      key: 'GOLD',
      defaultTitle: 'GOLD',
      activeBg: Color(0xFFFCE09B),
      idleBg: Color(0xFFFEF3C7),
      activeBorder: Color(0xFFD97706),
      idleBorder: Color(0xFFFDE68A),
      activeText: Color(0xFF78350F),
      idleText: Color(0xFFB45309),
      badgeBg: Color(0xFFD97706),
      badgeText: Colors.white,
    ),
    // 3: Silver / VIP General (Cyan / Teal)
    _StandTierConfig(
      key: 'SILVER',
      defaultTitle: 'SILVER / GENERAL',
      activeBg: Color(0xFFCFFAFE),
      idleBg: Color(0xFFECFEFF),
      activeBorder: Color(0xFF0891B2),
      idleBorder: Color(0xFFA5F3FC),
      activeText: Color(0xFF155E75),
      idleText: Color(0xFF0E7490),
      badgeBg: Color(0xFF0891B2),
      badgeText: Colors.white,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _activePassId = widget.selectedPassId ?? (widget.passes.isNotEmpty ? widget.passes.first.id : null);
  }

  @override
  void didUpdateWidget(covariant InteractiveVenueLayoutMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPassId != oldWidget.selectedPassId) {
      setState(() {
        _activePassId = widget.selectedPassId;
      });
    }
  }

  void _onSelectPass(TicketCategory pass) {
    setState(() {
      _activePassId = pass.id;
    });
    widget.onPassSelected(pass);
  }

  _StandTierConfig _getThemeForPass(TicketCategory pass, int index) {
    final name = '${pass.name} ${pass.type}'.toUpperCase();
    if (name.contains('FANPIT') || name.contains('VVIP') || name.contains('STAGE')) {
      return _tierThemes[0];
    } else if (name.contains('DIAMOND') || name.contains('VIP') || name.contains('PLATINUM')) {
      return _tierThemes[1];
    } else if (name.contains('GOLD') || name.contains('PREMIUM')) {
      return _tierThemes[2];
    }
    return _tierThemes[index % _tierThemes.length];
  }

  @override
  Widget build(BuildContext context) {
    // Sort passes descending by price (highest price / closest to stage first)
    final sortedPasses = List<TicketCategory>.from(widget.passes)
      ..sort((a, b) => b.price.compareTo(a.price));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0C091A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.neonPurple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.stadium_outlined, color: AppColors.neonPink, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AC Dome Stand & Stage Layout',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
                        ),
                        Text(
                          'Interactive 3D Arena View',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGlass,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.ac_unit, size: 12, color: AppColors.neonBlue),
                      SizedBox(width: 4),
                      Text('AC DOME', style: TextStyle(color: AppColors.neonBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.divider, height: 1),

          // ==========================================
          // VENUE MAP CANVAS (Matching Showmates / District layout)
          // ==========================================
          Container(
            color: const Color(0xFFF9FAFB),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. STAGE & CATWALK RUNWAY
                    _buildStageSection(),

                    const SizedBox(height: 4),

                    // 2. DYNAMIC STAND TIERS
                    if (sortedPasses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: const Text('No stands available for this night', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold)),
                      )
                    else ...[
                      // First / Stage-Front Pass (Fanpit style if >= 3 passes or named Fanpit)
                      if (_shouldRenderAsFanpitRow(sortedPasses.first, sortedPasses.length)) ...[
                        _buildFanpitRow(sortedPasses.first, _getThemeForPass(sortedPasses.first, 0)),
                        const SizedBox(height: 10),
                        // Remaining Passes
                        ...sortedPasses.skip(1).toList().asMap().entries.map((entry) {
                          final p = entry.value;
                          final idx = entry.key + 1;
                          final theme = _getThemeForPass(p, idx);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildTierBlock(pass: p, theme: theme),
                          );
                        }),
                      ] else ...[
                        // All passes as structured arena blocks
                        ...sortedPasses.asMap().entries.map((entry) {
                          final p = entry.value;
                          final idx = entry.key;
                          final theme = _getThemeForPass(p, idx);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildTierBlock(pass: p, theme: theme),
                          );
                        }),
                      ],
                    ],

                    const SizedBox(height: 8),

                    // CAPTION
                    const Text(
                      'ALL SECTIONS ARE STANDING WITH SEATING WINGS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Divider(color: AppColors.divider, height: 1),

          // ==========================================
          // BOTTOM FILTER STANDS BY BAR
          // ==========================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded, size: 18, color: Colors.white70),
                const SizedBox(width: 8),
                const Text(
                  'Filter stands by',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // "All" chip
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              if (widget.passes.isNotEmpty) {
                                _onSelectPass(widget.passes.first);
                              }
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: _activePassId == null ? const Color(0xFF0D1326) : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: _activePassId == null ? const Color(0xFF8B5CF6) : AppColors.divider,
                                  width: _activePassId == null ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                'All Stands',
                                style: TextStyle(
                                  color: _activePassId == null ? Colors.white : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Dynamic Price Chips for EVERY pass
                        ...sortedPasses.map((p) {
                          final isSelected = _activePassId == p.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => _onSelectPass(p),
                              borderRadius: BorderRadius.circular(24),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF0D1326) : Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFE5E7EB),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                                            blurRadius: 10,
                                          )
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '₹${p.price.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : const Color(0xFF111827),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      p.name,
                                      style: TextStyle(
                                        color: isSelected ? AppColors.neonPink : const Color(0xFF6B7280),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldRenderAsFanpitRow(TicketCategory pass, int totalPasses) {
    final name = pass.name.toUpperCase();
    return name.contains('FANPIT') || name.contains('STAGE FRONT') || (totalPasses >= 3 && name.contains('VIP'));
  }

  Widget _buildStageSection() {
    return Column(
      children: [
        Container(
          width: 150,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          alignment: Alignment.center,
          child: const Text(
            'STAGE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF4B5563),
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFanpitRow(TicketCategory pass, _StandTierConfig theme) {
    final isSelected = _activePassId == pass.id;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Fanpit
        Expanded(
          child: InkWell(
            onTap: () => _onSelectPass(pass),
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 82,
              decoration: BoxDecoration(
                color: isSelected ? theme.activeBg : theme.idleBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? theme.activeBorder : theme.idleBorder,
                  width: isSelected ? 2.5 : 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.activeBorder.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pass.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: isSelected ? theme.activeText : theme.idleText,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '₹${pass.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? theme.activeText : theme.idleText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Catwalk Runway Extension
        Container(
          width: 34,
          height: 82,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
        ),

        // Right Fanpit
        Expanded(
          child: InkWell(
            onTap: () => _onSelectPass(pass),
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 82,
              decoration: BoxDecoration(
                color: isSelected ? theme.activeBg : theme.idleBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? theme.activeBorder : theme.idleBorder,
                  width: isSelected ? 2.5 : 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.activeBorder.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pass.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: isSelected ? theme.activeText : theme.idleText,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '₹${pass.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? theme.activeText : theme.idleText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTierBlock({
    required TicketCategory pass,
    required _StandTierConfig theme,
  }) {
    final isSelected = _activePassId == pass.id;

    return InkWell(
      onTap: () => _onSelectPass(pass),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 84,
        decoration: BoxDecoration(
          color: isSelected ? theme.activeBg : theme.idleBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.activeBorder : theme.idleBorder,
            width: isSelected ? 2.5 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.activeBorder.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Left Seating Wing
            Container(
              width: 30,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? theme.activeBg : theme.idleBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? theme.activeText.withValues(alpha: 0.7) : theme.idleBorder,
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  'SEATING',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: isSelected ? theme.activeText : theme.idleText,
                  ),
                ),
              ),
            ),

            // Center Standing Arena
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pass.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: isSelected ? theme.activeText : theme.idleText,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '₹${pass.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? theme.activeText : theme.idleText,
                          ),
                        ),
                        if (pass.type.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isSelected ? theme.badgeBg : theme.idleBorder,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              pass.type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? theme.badgeText : theme.idleText,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Right Seating Wing
            Container(
              width: 30,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? theme.activeBg : theme.idleBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? theme.activeText.withValues(alpha: 0.7) : theme.idleBorder,
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  'SEATING',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: isSelected ? theme.activeText : theme.idleText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

