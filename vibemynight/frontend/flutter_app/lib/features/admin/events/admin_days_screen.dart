import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/providers/pass_template_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/network_image_box.dart';
import '../../../models/event_day_detail.dart';
import '../../../models/pass_template.dart';
import '../../../models/ticket_category.dart';
import '../widgets/admin_shell.dart';

/// "MANAGE DAYS & PASSES" - Full day-by-day management including
/// day schedule, direct pass/category pricing, artist line-ups, and facilities.
class AdminManageDaysScreen extends ConsumerWidget {
  final int eventId;

  const AdminManageDaysScreen({super.key, required this.eventId});

  Future<void> _deleteDay(BuildContext context, WidgetRef ref, int dayId, int dayNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete Day $dayNumber?'),
        content: const Text('This will permanently delete this day and all its passes, artist assignments, and facilities.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminServiceProvider).deleteEventDay(dayId);
      ref.invalidate(adminEventDetailProvider(eventId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Day $dayNumber deleted')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _openAddPassDialog(BuildContext context, int dayId, int dayNumber) {
    showDialog(
      context: context,
      builder: (context) => _QuickPassFormDialog(dayId: dayId, dayNumber: dayNumber, eventId: eventId),
    );
  }

  void _openEditPassDialog(BuildContext context, int dayId, int dayNumber, TicketCategory pass) {
    showDialog(
      context: context,
      builder: (context) => _QuickPassFormDialog(dayId: dayId, dayNumber: dayNumber, eventId: eventId, initial: pass),
    );
  }

  void _openArtistAssignment(BuildContext context, int dayId, int dayNumber) {
    showDialog(
      context: context,
      builder: (context) => _DayArtistAssignmentDialog(dayId: dayId, dayNumber: dayNumber, eventId: eventId),
    );
  }

  void _openDayFacilities(BuildContext context, int dayId, int dayNumber) {
    showDialog(
      context: context,
      builder: (context) => _DayFacilitiesDialog(dayId: dayId, dayNumber: dayNumber),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(adminEventDetailProvider(eventId));

    return AdminShell(
      title: 'Manage Days & Passes',
      currentPath: '/admin/events',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Event Day'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () => context.push('/admin/events/$eventId/days/new'),
          ),
        ),
      ],
      body: eventAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(adminEventDetailProvider(eventId)),
        ),
        data: (event) {
          if (event.days.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.neonPurple.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.neonPurple),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      event.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No event days have been added yet.\nAdd Day 1 to configure night schedule, artists, and pass prices.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Day 1'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () => context.push('/admin/events/$eventId/days/new'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: event.days.length,
            itemBuilder: (context, index) {
              final daySummary = event.days[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _DayDetailCard(
                  eventId: eventId,
                  dayId: daySummary.id,
                  dayNumber: daySummary.dayNumber,
                  dateString: daySummary.date,
                  programName: daySummary.programName,
                  onEditDay: () => context.push('/admin/event-days/${daySummary.id}/edit'),
                  onDeleteDay: () => _deleteDay(context, ref, daySummary.id, daySummary.dayNumber),
                  onAddPass: () => _openAddPassDialog(context, daySummary.id, daySummary.dayNumber),
                  onEditPass: (pass) => _openEditPassDialog(context, daySummary.id, daySummary.dayNumber, pass),
                  onAssignArtist: () => _openArtistAssignment(context, daySummary.id, daySummary.dayNumber),
                  onManageFacilities: () => _openDayFacilities(context, daySummary.id, daySummary.dayNumber),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Rich Day Card displaying Day info, live pass categories with quick presets,
/// performing artists, and facilities.
class _DayDetailCard extends ConsumerWidget {
  final int eventId;
  final int dayId;
  final int dayNumber;
  final String dateString;
  final String? programName;
  final VoidCallback onEditDay;
  final VoidCallback onDeleteDay;
  final VoidCallback onAddPass;
  final Function(TicketCategory) onEditPass;
  final VoidCallback onAssignArtist;
  final VoidCallback onManageFacilities;

  const _DayDetailCard({
    required this.eventId,
    required this.dayId,
    required this.dayNumber,
    required this.dateString,
    this.programName,
    required this.onEditDay,
    required this.onDeleteDay,
    required this.onAddPass,
    required this.onEditPass,
    required this.onAssignArtist,
    required this.onManageFacilities,
  });

  Future<void> _deletePass(BuildContext context, WidgetRef ref, int passId, String passName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete "$passName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminServiceProvider).deletePass(passId);
      ref.invalidate(eventDayDetailProvider(dayId));
      ref.invalidate(adminEventDetailProvider(eventId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _quickAddPreset(
    BuildContext context,
    WidgetRef ref,
    String name,
    String type,
    double price,
    int quantity,
    List<String> benefits,
  ) async {
    try {
      await ref.read(adminServiceProvider).createPass(dayId, {
        'name': name,
        'type': type,
        'price': price,
        'availableQuantity': quantity,
        'maxPerCustomer': 5,
        'benefits': benefits,
      });
      ref.invalidate(eventDayDetailProvider(dayId));
      ref.invalidate(adminEventDetailProvider(eventId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name (₹${price.toStringAsFixed(0)}) added to Day $dayNumber! ✅'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    }
  }

  Widget _buildQuickAddChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    String name,
    String type,
    double price,
    int quantity,
    List<String> benefits,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _quickAddPreset(context, ref, name, type, price, quantity, benefits),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.neonPurple.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neonPink),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayDetailAsync = ref.watch(eventDayDetailProvider(dayId));
    final passTemplates = ref.watch(passTemplatesProvider);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Day Number + Date + Actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.neonPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'DAY $dayNumber',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateString,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (programName != null && programName!.isNotEmpty)
                        Text(
                          programName!,
                          style: const TextStyle(color: AppColors.neonPink, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit Day Schedule',
                  onPressed: onEditDay,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                  tooltip: 'Delete Day',
                  onPressed: onDeleteDay,
                ),
              ],
            ),

            const Divider(height: 20, color: AppColors.divider),

            dayDetailAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              ),
              error: (err, _) => Text('Error loading day details: $err', style: const TextStyle(color: AppColors.error, fontSize: 12)),
              data: (day) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timings & Venue
                    if (day.startTime != null || day.venue != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            if (day.startTime != null) ...[
                              const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '${day.startTime}${day.endTime != null ? " - ${day.endTime}" : ""}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(width: 16),
                            ],
                            if (day.venue != null) ...[
                              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  day.venue!,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                    // Passes & Pricing Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.confirmation_number_outlined, size: 16, color: AppColors.neonPurple),
                            const SizedBox(width: 6),
                            Text(
                              'Pass Categories & Pricing (${day.passes.length})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.neonPink),
                          label: const Text('+ Add Custom Pass', style: TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: onAddPass,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    if (day.passes.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceGlass,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No passes added yet for this day. Click a preset below to add in 1 click!',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: day.passes.map((pass) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceGlass,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(pass.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppColors.neonPurple.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(pass.type, style: const TextStyle(color: AppColors.neonPink, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${pass.price.toStringAsFixed(0)} · Stock: ${pass.availableQuantity}',
                                      style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => onEditPass(pass),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.edit, size: 14, color: AppColors.textSecondary),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _deletePass(context, ref, pass.id, pass.name),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.close, size: 14, color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 10),

                    // Quick-Add Category Presets Bar (1-Click Add from Master Catalog!)
                    Row(
                      children: [
                        const Text('1-Click Add: ', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: passTemplates.map((tpl) {
                                return _buildQuickAddChip(
                                  context,
                                  ref,
                                  '+ ${tpl.name} (₹${tpl.price.toStringAsFixed(0)})',
                                  tpl.name,
                                  tpl.type,
                                  tpl.price,
                                  tpl.defaultQuantity,
                                  tpl.benefits,
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Performing Artists Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.mic_none_outlined, size: 16, color: AppColors.neonPink),
                            const SizedBox(width: 6),
                            Text(
                              'Artists Line-Up (${day.artists.length})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.person_add_outlined, size: 16, color: AppColors.neonBlue),
                          label: const Text('+ Assign Artist', style: TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: onAssignArtist,
                        ),
                      ],
                    ),

                    if (day.artists.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: day.artists.map((a) {
                            return Chip(
                              avatar: a.photoUrl != null
                                  ? ClipOval(child: Image.network(a.photoUrl!, width: 20, height: 20, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 16)))
                                  : const Icon(Icons.person, size: 16),
                              label: Text('${a.name}${a.isPrimary ? " (Headliner)" : ""}'),
                              backgroundColor: a.isPrimary ? AppColors.neonPurple.withValues(alpha: 0.2) : AppColors.surfaceGlass,
                              side: BorderSide(color: a.isPrimary ? AppColors.neonPurple : AppColors.divider),
                            );
                          }).toList(),
                        ),
                      ),

                    const SizedBox(height: 10),

                    // Facilities & Actions bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (day.facilities.isNotEmpty)
                          Expanded(
                            child: Text(
                              'Facilities: ${day.facilities.map((f) => f.name).join(", ")}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        else
                          const Text('No day-specific facilities attached.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.tune, size: 14),
                          label: const Text('Day Facilities', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          onPressed: onManageFacilities,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick Modal Dialog to Add or Edit Pass with 1-Tap Category Presets!
class _QuickPassFormDialog extends ConsumerStatefulWidget {
  final int dayId;
  final int dayNumber;
  final int eventId;
  final TicketCategory? initial;

  const _QuickPassFormDialog({
    required this.dayId,
    required this.dayNumber,
    required this.eventId,
    this.initial,
  });

  @override
  ConsumerState<_QuickPassFormDialog> createState() => _QuickPassFormDialogState();
}

class _QuickPassFormDialogState extends ConsumerState<_QuickPassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _availableQuantity;
  late final TextEditingController _maxPerCustomer;
  late final TextEditingController _description;
  late final TextEditingController _benefits;
  String _type = 'REGULAR';
  bool _submitting = false;
  bool _saveToMasterCatalog = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name ?? 'Regular Pass');
    _price = TextEditingController(text: p != null ? p.price.toStringAsFixed(0) : '499');
    _availableQuantity = TextEditingController(text: p != null ? p.availableQuantity.toString() : '500');
    _maxPerCustomer = TextEditingController(text: p != null ? p.maxPerCustomer.toString() : '5');
    _description = TextEditingController(text: p?.description ?? '');
    _benefits = TextEditingController(text: p != null ? p.benefits.join(', ') : 'General entry, Dance floor access');
    _type = p?.type ?? 'REGULAR';
  }

  Future<void> _promptAddCategory() async {
    final controller = TextEditingController();
    final newCat = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.divider)),
        title: const Row(
          children: [
            Icon(Icons.add_box_outlined, color: AppColors.neonPurple, size: 20),
            SizedBox(width: 8),
            Text('Add Custom Pass Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter custom category code (e.g. DIAMOND, GOLDEN_CIRCLE, VIP_LOUNGE, FEMALE, STUDENT)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Category Code *', hintText: 'e.g. DIAMOND'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonPurple),
            onPressed: () {
              final text = controller.text.trim().toUpperCase().replaceAll(' ', '_');
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            child: const Text('Add Category'),
          ),
        ],
      ),
    );
    if (newCat != null && newCat.isNotEmpty) {
      await ref.read(passCategoriesProvider.notifier).addCategory(newCat);
      if (mounted) {
        setState(() => _type = newCat);
      }
    }
  }

  void _applyTemplate(PassTemplate tpl) {
    setState(() {
      _name.text = tpl.name;
      _type = tpl.type;
      _price.text = tpl.price.toStringAsFixed(0);
      _availableQuantity.text = tpl.defaultQuantity.toString();
      _maxPerCustomer.text = tpl.maxPerCustomer.toString();
      if (tpl.description != null && tpl.description!.isNotEmpty) {
        _description.text = tpl.description!;
      }
      _benefits.text = tpl.benefits.join(', ');
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _availableQuantity.dispose();
    _maxPerCustomer.dispose();
    _description.dispose();
    _benefits.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final benefitsList = _benefits.text
        .split(',')
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty)
        .toList();

    final body = {
      'name': _name.text.trim(),
      'type': _type,
      'price': double.parse(_price.text.trim()),
      'availableQuantity': int.parse(_availableQuantity.text.trim()),
      'maxPerCustomer': int.parse(_maxPerCustomer.text.trim()),
      if (_description.text.trim().isNotEmpty) 'description': _description.text.trim(),
      'benefits': benefitsList,
    };

    try {
      final admin = ref.read(adminServiceProvider);
      if (widget.initial != null) {
        await admin.updatePass(widget.initial!.id, body);
      } else {
        await admin.createPass(widget.dayId, body);
      }

      if (_saveToMasterCatalog) {
        await ref.read(passTemplatesProvider.notifier).addTemplate(
          PassTemplate(
            id: 'tpl_${DateTime.now().millisecondsSinceEpoch}',
            name: _name.text.trim(),
            type: _type,
            price: double.parse(_price.text.trim()),
            defaultQuantity: int.parse(_availableQuantity.text.trim()),
            maxPerCustomer: int.parse(_maxPerCustomer.text.trim()),
            description: _description.text.trim().isNotEmpty ? _description.text.trim() : null,
            benefits: benefitsList,
          ),
        );
      }

      ref.invalidate(eventDayDetailProvider(widget.dayId));
      ref.invalidate(adminEventDetailProvider(widget.eventId));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initial != null ? 'Pass updated' : 'Pass added to Day ${widget.dayNumber}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final passTemplates = ref.watch(passTemplatesProvider);
    final categories = ref.watch(passCategoriesProvider);
    final allCategoryOptions = categories.contains(_type) ? categories : [_type, ...categories];

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Pass (Day ${widget.dayNumber})' : 'Add Pass for Day ${widget.dayNumber}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 12),

                // Preset Quick-Pick Chips (from Master Catalog)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Catalog Presets (1-Click Fill):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      onPressed: () => context.push('/admin/pass-templates'),
                      child: const Text('Manage Catalog ➔', style: TextStyle(fontSize: 11, color: AppColors.neonBlue)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: passTemplates.map((tpl) {
                    return ActionChip(
                      label: Text('${tpl.name} (₹${tpl.price.toStringAsFixed(0)})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      backgroundColor: AppColors.surfaceGlass,
                      side: const BorderSide(color: AppColors.divider),
                      onPressed: () => _applyTemplate(tpl),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 12),

                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                  const SizedBox(height: 10),
                ],

                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Pass Name *', hintText: 'e.g. Regular Pass, VIP Pass, Couple Pass'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _type,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        decoration: InputDecoration(
                          labelText: 'Pass Type *',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppColors.neonPink, size: 20),
                            tooltip: 'Add Custom Category',
                            onPressed: _promptAddCategory,
                          ),
                        ),
                        items: [
                          ...allCategoryOptions.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))),
                          const DropdownMenuItem(
                            value: '__ADD_NEW__',
                            child: Row(
                              children: [
                                Icon(Icons.add_circle, size: 16, color: AppColors.neonPink),
                                SizedBox(width: 6),
                                Text('+ Custom Type...', style: TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == '__ADD_NEW__') {
                            _promptAddCategory();
                          } else if (v != null) {
                            setState(() => _type = v);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Price (₹) *', prefixText: '₹ '),
                        validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter valid price' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _availableQuantity,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Total Quantity *'),
                        validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter valid quantity' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxPerCustomer,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Max Per Person *'),
                        validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter valid limit' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Description (Optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _benefits,
                  decoration: const InputDecoration(
                    labelText: 'Benefits & Inclusions (comma-separated)',
                    hintText: 'e.g. AC Dome Entry, Free Parking, Food Coupon',
                  ),
                ),
                const SizedBox(height: 14),

                CheckboxListTile(
                  value: _saveToMasterCatalog,
                  onChanged: (v) => setState(() => _saveToMasterCatalog = v ?? false),
                  title: const Text('Save to Master Catalog / Templates', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Re-use this pass type & price across any other event with 1-click', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),

                const SizedBox(height: 18),
                GradientButton(
                  label: _submitting ? 'SAVING...' : (isEdit ? 'SAVE CHANGES' : 'CREATE PASS (DAY ${widget.dayNumber})'),
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper model for Pass Configuration inside Add Day Form
class _FormPassItem {
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController quantityController;
  final TextEditingController maxPerCustomerController;
  final TextEditingController benefitsController;
  String type;

  _FormPassItem({
    required String name,
    required this.type,
    required double price,
    int quantity = 500,
    int maxPerCustomer = 5,
    List<String> benefits = const [],
  })  : nameController = TextEditingController(text: name),
        priceController = TextEditingController(text: price.toStringAsFixed(0)),
        quantityController = TextEditingController(text: quantity.toString()),
        maxPerCustomerController = TextEditingController(text: maxPerCustomer.toString()),
        benefitsController = TextEditingController(text: benefits.join(', '));

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    maxPerCustomerController.dispose();
    benefitsController.dispose();
  }
}

/// Helper class for Selected Artists inside Add Day Form
class _SelectedDayArtist {
  final int artistId;
  final String name;
  final String type;
  final String? photoUrl;
  bool isPrimary;

  _SelectedDayArtist({
    required this.artistId,
    required this.name,
    required this.type,
    this.photoUrl,
    this.isPrimary = false,
  });
}

/// "ADD EVENT DAY" / "EDIT EVENT DAY" SCREEN:
/// Streamlined form with:
/// 1. Auto-inherited Venue & Location (no re-typing)
/// 2. Auto-calculated Day Number & Sequential Date
/// 3. Direct Day Artist lineup multi-select with Headliner toggle
/// 4. Direct Day Pass Categories & Pricing config with 1-click presets
class AdminDayFormScreen extends ConsumerStatefulWidget {
  final int eventId;
  final int? dayId;
  final EventDayDetail? initial;

  const AdminDayFormScreen({
    super.key,
    required this.eventId,
    this.dayId,
    this.initial,
  });

  @override
  ConsumerState<AdminDayFormScreen> createState() => _AdminDayFormScreenState();
}

class _AdminDayFormScreenState extends ConsumerState<AdminDayFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _dayNumber;
  late final TextEditingController _date;
  late final TextEditingController _dayName;
  late final TextEditingController _programName;
  late final TextEditingController _startTime;
  late final TextEditingController _endTime;
  late final TextEditingController _venue;
  late final TextEditingController _address;
  late final TextEditingController _location;
  late final TextEditingController _googleMapsUrl;
  late final TextEditingController _description;

  bool _customVenueExpanded = false;
  bool _submitting = false;
  String? _error;
  bool _initializedFromEvent = false;

  // Artists assigned to this day
  final List<_SelectedDayArtist> _selectedArtists = [];
  int? _dropdownArtistId;

  // Pass categories configured for this day
  final List<_FormPassItem> _configuredPasses = [];

  static const _programSuggestions = [
    'Maha Garba Night',
    'Raas Garba Night',
    'Dandiya Dhoom',
    'Bollywood Raas',
    'Rock Garba',
    'Grand Finale Night',
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _dayNumber = TextEditingController(text: d?.dayNumber.toString() ?? '');
    _date = TextEditingController(text: d?.date ?? '');
    _dayName = TextEditingController(text: d?.dayName ?? '');
    _programName = TextEditingController(text: d?.programName ?? '');
    _startTime = TextEditingController(text: d?.startTime ?? '20:00:00');
    _endTime = TextEditingController(text: d?.endTime ?? '01:00:00');
    _venue = TextEditingController(text: d?.venue ?? '');
    _address = TextEditingController(text: d?.address ?? '');
    _location = TextEditingController(text: d?.location ?? '');
    _googleMapsUrl = TextEditingController(text: d?.googleMapsUrl ?? '');
    _description = TextEditingController(text: d?.description ?? '');

    if (d != null) {
      _customVenueExpanded = d.venue != null && d.venue!.isNotEmpty;
      for (final a in d.artists) {
        _selectedArtists.add(_SelectedDayArtist(
          artistId: a.artistId,
          name: a.name,
          type: a.type,
          photoUrl: a.photoUrl,
          isPrimary: a.isPrimary,
        ));
      }
    } else {
      // Default starter pass categories for a new day
      _configuredPasses.addAll([
        _FormPassItem(
          name: 'Regular Pass',
          type: 'REGULAR',
          price: 499,
          quantity: 500,
          maxPerCustomer: 5,
          benefits: ['General Entry', 'Dance Floor Access'],
        ),
        _FormPassItem(
          name: 'VIP Pass',
          type: 'VIP',
          price: 999,
          quantity: 100,
          maxPerCustomer: 4,
          benefits: ['VIP Arena Access', 'Complimentary Beverage', 'Priority Entry'],
        ),
      ]);
    }
  }

  void _addPassPreset(String name, String type, double price, int qty, List<String> benefits) {
    setState(() {
      _configuredPasses.add(
        _FormPassItem(
          name: name,
          type: type,
          price: price,
          quantity: qty,
          maxPerCustomer: 5,
          benefits: benefits,
        ),
      );
    });
  }

  @override
  void dispose() {
    for (final c in [
      _dayNumber, _date, _dayName, _programName, _startTime, _endTime,
      _venue, _address, _location, _googleMapsUrl, _description,
    ]) {
      c.dispose();
    }
    for (final p in _configuredPasses) {
      p.dispose();
    }
    super.dispose();
  }

  void _populateFromEventOnce(dynamic event) {
    if (_initializedFromEvent || widget.initial != null) return;
    _initializedFromEvent = true;

    // Auto-calculate next Day Number
    if (_dayNumber.text.isEmpty) {
      _dayNumber.text = (event.days.length + 1).toString();
    }

    // Auto-calculate Date
    if (_date.text.isEmpty) {
      if (event.days.isNotEmpty) {
        final lastDateStr = event.days.last.date;
        final parsed = DateTime.tryParse(lastDateStr);
        if (parsed != null) {
          final nextDate = parsed.add(const Duration(days: 1));
          _date.text = nextDate.toIso8601String().split('T').first;
        } else {
          _date.text = event.startDate;
        }
      } else {
        _date.text = event.startDate;
      }
    }

    // Auto-fill venue/address from parent event
    if (_venue.text.isEmpty) _venue.text = event.venue ?? '';
    if (_address.text.isEmpty) _address.text = event.address ?? '';
    if (_location.text.isEmpty) _location.text = event.location ?? event.city ?? '';
    if (_googleMapsUrl.text.isEmpty) _googleMapsUrl.text = event.googleMapsUrl ?? '';
    if (_programName.text.isEmpty) {
      _programName.text = 'Day ${_dayNumber.text} Garba Night';
    }
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_date.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) _date.text = picked.toIso8601String().split('T').first;
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final parts = controller.text.split(':');
    final initialHour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 20 : 20;
    final initialMin = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMin),
    );
    if (picked != null) {
      controller.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final body = {
      'dayNumber': int.parse(_dayNumber.text.trim()),
      'date': _date.text.trim(),
      if (_dayName.text.trim().isNotEmpty) 'dayName': _dayName.text.trim(),
      if (_programName.text.trim().isNotEmpty) 'programName': _programName.text.trim(),
      if (_startTime.text.trim().isNotEmpty) 'startTime': _startTime.text.trim(),
      if (_endTime.text.trim().isNotEmpty) 'endTime': _endTime.text.trim(),
      if (_venue.text.trim().isNotEmpty) 'venue': _venue.text.trim(),
      if (_address.text.trim().isNotEmpty) 'address': _address.text.trim(),
      if (_location.text.trim().isNotEmpty) 'location': _location.text.trim(),
      if (_googleMapsUrl.text.trim().isNotEmpty) 'googleMapsUrl': _googleMapsUrl.text.trim(),
      if (_description.text.trim().isNotEmpty) 'description': _description.text.trim(),
    };

    try {
      final admin = ref.read(adminServiceProvider);
      int targetDayId;

      if (widget.dayId != null) {
        await admin.updateEventDay(widget.dayId!, body);
        targetDayId = widget.dayId!;
      } else {
        final created = await admin.createEventDay(widget.eventId, body);
        targetDayId = created.id;

        // Auto-create all configured passes for this day
        if (_configuredPasses.isNotEmpty) {
          for (final passItem in _configuredPasses) {
            final priceVal = double.tryParse(passItem.priceController.text.trim()) ?? 499.0;
            final qtyVal = int.tryParse(passItem.quantityController.text.trim()) ?? 500;
            final maxPerCust = int.tryParse(passItem.maxPerCustomerController.text.trim()) ?? 5;
            final benefitsList = passItem.benefitsController.text
                .split(',')
                .map((b) => b.trim())
                .where((b) => b.isNotEmpty)
                .toList();

            await admin.createPass(targetDayId, {
              'name': passItem.nameController.text.trim().isNotEmpty ? passItem.nameController.text.trim() : 'Pass',
              'type': passItem.type,
              'price': priceVal,
              'availableQuantity': qtyVal,
              'maxPerCustomer': maxPerCust,
              'benefits': benefitsList,
            });
          }
        }
      }

      // Assign newly selected artists if creating
      if (widget.dayId == null && _selectedArtists.isNotEmpty) {
        for (int i = 0; i < _selectedArtists.length; i++) {
          final a = _selectedArtists[i];
          await admin.assignArtistToDay(targetDayId, {
            'artistId': a.artistId,
            'isPrimary': a.isPrimary,
            'performanceOrder': i + 1,
            'performanceStartTime': _startTime.text.trim(),
            'performanceEndTime': _endTime.text.trim(),
          });
        }
      }

      ref.invalidate(adminEventDetailProvider(widget.eventId));
      ref.invalidate(eventDayDetailProvider(targetDayId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.dayId != null ? 'Day details updated!' : 'Day ${_dayNumber.text} & passes created successfully! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.dayId != null;
    final eventAsync = ref.watch(adminEventDetailProvider(widget.eventId));
    final artistsAsync = ref.watch(adminArtistsProvider);
    final passTemplates = ref.watch(passTemplatesProvider);

    // Auto-populate when event loads
    eventAsync.whenData((event) => _populateFromEventOnce(event));

    return AdminShell(
      title: isEdit ? 'Edit Day' : 'Add Event Day',
      currentPath: '/admin/events',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Top Event Context Pill
                eventAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (event) => Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.neonPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event, color: AppColors.neonPink, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                '${event.venue ?? "Main Venue"}, ${event.city ?? "Ahmedabad"} · ${event.days.length} Existing Days',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // CARD 1: Day Number, Date & Program
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: AppColors.neonPurple),
                            SizedBox(width: 8),
                            Text('Day Schedule & Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _dayNumber,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Day Number *', hintText: 'e.g. 1'),
                                validator: (v) => (v == null || int.tryParse(v) == null) ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _date,
                                readOnly: true,
                                onTap: _pickDate,
                                decoration: InputDecoration(
                                  labelText: 'Date (YYYY-MM-DD) *',
                                  suffixIcon: IconButton(icon: const Icon(Icons.calendar_month), onPressed: _pickDate),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _programName,
                          decoration: const InputDecoration(
                            labelText: 'Program / Theme Title',
                            hintText: 'e.g. Maha Garba Night, Bollywood Raas',
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Quick Program Suggestions
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _programSuggestions.map((title) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ActionChip(
                                  label: Text(title, style: const TextStyle(fontSize: 11)),
                                  backgroundColor: AppColors.surfaceGlass,
                                  onPressed: () => setState(() => _programName.text = title),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _startTime,
                                readOnly: true,
                                onTap: () => _pickTime(_startTime),
                                decoration: InputDecoration(
                                  labelText: 'Start Time',
                                  suffixIcon: IconButton(icon: const Icon(Icons.access_time), onPressed: () => _pickTime(_startTime)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: _endTime,
                                readOnly: true,
                                onTap: () => _pickTime(_endTime),
                                decoration: InputDecoration(
                                  labelText: 'End Time',
                                  suffixIcon: IconButton(icon: const Icon(Icons.access_time), onPressed: () => _pickTime(_endTime)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // CARD 2: Day Lineup & Artists Selection
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.mic, size: 18, color: AppColors.neonPink),
                                SizedBox(width: 8),
                                Text('Day Performing Artists', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            Text('${_selectedArtists.length} Selected', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Assign performing artists and choose who is the HEADLINER for this specific night.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),

                        // Selected Artists List
                        if (_selectedArtists.isNotEmpty) ...[
                          Column(
                            children: _selectedArtists.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final a = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: a.isPrimary ? AppColors.neonPurple.withValues(alpha: 0.15) : AppColors.surfaceGlass,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: a.isPrimary ? AppColors.neonPurple : AppColors.divider),
                                ),
                                child: Row(
                                  children: [
                                    NetworkImageBox(
                                      url: a.photoUrl,
                                      height: 36,
                                      width: 36,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          Text(a.type, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    // Headliner Toggle
                                    FilterChip(
                                      label: Text(a.isPrimary ? '★ HEADLINER' : 'Headliner?'),
                                      selected: a.isPrimary,
                                      selectedColor: AppColors.neonPurple,
                                      onSelected: (val) {
                                        setState(() {
                                          for (var other in _selectedArtists) {
                                            other.isPrimary = false;
                                          }
                                          a.isPrimary = val;
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                                      onPressed: () => setState(() => _selectedArtists.removeAt(idx)),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Artist Dropdown & Add Button
                        artistsAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (err, _) => Text('Error: $err', style: const TextStyle(color: AppColors.error)),
                          data: (allArtists) {
                            return Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    initialValue: _dropdownArtistId,
                                    dropdownColor: AppColors.surface,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Select Artist to Add',
                                      isDense: true,
                                    ),
                                    items: allArtists.map((a) {
                                      final isAlreadySelected = _selectedArtists.any((sa) => sa.artistId == a.id);
                                      return DropdownMenuItem<int>(
                                        value: a.id,
                                        enabled: !isAlreadySelected,
                                        child: Text(
                                          '${a.name} (${a.type})${isAlreadySelected ? " ✓ Added" : ""}',
                                          style: TextStyle(
                                            color: isAlreadySelected ? AppColors.textMuted : Colors.white,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() => _dropdownArtistId = val);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _dropdownArtistId == null
                                      ? null
                                      : () {
                                          final found = allArtists.firstWhere((a) => a.id == _dropdownArtistId);
                                          setState(() {
                                            _selectedArtists.add(_SelectedDayArtist(
                                              artistId: found.id,
                                              name: found.name,
                                              type: found.type,
                                              photoUrl: found.photoUrl,
                                              isPrimary: _selectedArtists.isEmpty,
                                            ));
                                            _dropdownArtistId = null;
                                          });
                                        },
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add to Night'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.neonPurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // CARD 3: Day Pass Categories & Pricing (Create Mode)
                if (!isEdit)
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.confirmation_number, size: 18, color: AppColors.neonBlue),
                                  SizedBox(width: 8),
                                  Text('Day Pass Categories & Pricing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              Text('${_configuredPasses.length} Tiers', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Configure pass tiers and prices for this specific night. Tweak rates or add more categories with 1-click presets.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 14),

                          // Configured Passes List
                          if (_configuredPasses.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceGlass,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('No passes configured. Click a category button below to add.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            )
                          else
                            Column(
                              children: _configuredPasses.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final p = entry.value;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceGlass,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.divider),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: TextFormField(
                                              controller: p.nameController,
                                              decoration: const InputDecoration(labelText: 'Pass Name', isDense: true),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                              controller: p.priceController,
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              decoration: const InputDecoration(labelText: 'Price (₹)', prefixText: '₹ ', isDense: true),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                              controller: p.quantityController,
                                              keyboardType: TextInputType.number,
                                              decoration: const InputDecoration(labelText: 'Stock Qty', isDense: true),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                            onPressed: () => setState(() => _configuredPasses.removeAt(idx)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                          const SizedBox(height: 12),

                          // Quick Add Category Presets (from Master Catalog)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('1-Click Add Pass Tier (Catalog):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              TextButton(
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                onPressed: () => context.push('/admin/pass-templates'),
                                child: const Text('Manage Catalog ➔', style: TextStyle(fontSize: 11, color: AppColors.neonBlue)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: passTemplates.map((tpl) {
                              return ActionChip(
                                label: Text('+ ${tpl.name} (₹${tpl.price.toStringAsFixed(0)})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                backgroundColor: AppColors.surfaceGlass,
                                side: const BorderSide(color: AppColors.divider),
                                onPressed: () => _addPassPreset(tpl.name, tpl.type, tpl.price, tpl.defaultQuantity, tpl.benefits),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // CARD 4: Venue & Location (Auto-inherited default)
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_on, size: 18, color: AppColors.neonBlue),
                            SizedBox(width: 8),
                            Text('Venue & Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceGlass,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.neonBlue, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _venue.text.isNotEmpty ? _venue.text : 'Event Venue',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('Inherited from Event', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                    if (_address.text.isNotEmpty || _location.text.isNotEmpty)
                                      Text(
                                        [_address.text, _location.text].where((s) => s.isNotEmpty).join(', '),
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Different Venue for this specific night?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Enable only if this night takes place at a different venue/location.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          value: _customVenueExpanded,
                          activeThumbColor: AppColors.neonPurple,
                          onChanged: (v) => setState(() => _customVenueExpanded = v),
                        ),
                        if (_customVenueExpanded) ...[
                          const SizedBox(height: 12),
                          TextFormField(controller: _venue, decoration: const InputDecoration(labelText: 'Venue Name')),
                          const SizedBox(height: 12),
                          TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Full Address')),
                          const SizedBox(height: 12),
                          TextFormField(controller: _location, decoration: const InputDecoration(labelText: 'City / Location')),
                          const SizedBox(height: 12),
                          TextFormField(controller: _googleMapsUrl, decoration: const InputDecoration(labelText: 'Google Maps Directions URL')),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (_error != null) ...[
                  ErrorView(message: _error!),
                  const SizedBox(height: 16),
                ],

                // Submit Button
                GradientButton(
                  label: _submitting ? 'SAVING DAY & PASSES...' : (isEdit ? 'SAVE CHANGES' : 'CREATE EVENT DAY WITH PASSES'),
                  onPressed: _submitting ? null : _submit,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal Dialog for Day Artist Lineup
class _DayArtistAssignmentDialog extends ConsumerStatefulWidget {
  final int dayId;
  final int dayNumber;
  final int eventId;

  const _DayArtistAssignmentDialog({
    required this.dayId,
    required this.dayNumber,
    required this.eventId,
  });

  @override
  ConsumerState<_DayArtistAssignmentDialog> createState() => _DayArtistAssignmentDialogState();
}

class _DayArtistAssignmentDialogState extends ConsumerState<_DayArtistAssignmentDialog> {
  int? _selectedArtistId;
  bool _isPrimary = false;
  final int _order = 1;
  final _startTime = TextEditingController(text: '20:00:00');
  final _endTime = TextEditingController(text: '00:00:00');
  bool _submitting = false;

  @override
  void dispose() {
    _startTime.dispose();
    _endTime.dispose();
    super.dispose();
  }

  Future<void> _assign() async {
    if (_selectedArtistId == null) return;
    setState(() => _submitting = true);
    try {
      await ref.read(adminServiceProvider).assignArtistToDay(widget.dayId, {
        'artistId': _selectedArtistId,
        'isPrimary': _isPrimary,
        'performanceOrder': _order,
        if (_startTime.text.isNotEmpty) 'performanceStartTime': _startTime.text.trim(),
        if (_endTime.text.isNotEmpty) 'performanceEndTime': _endTime.text.trim(),
      });
      ref.invalidate(eventDayDetailProvider(widget.dayId));
      ref.invalidate(adminEventDetailProvider(widget.eventId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _removeArtist(int artistId) async {
    try {
      await ref.read(adminServiceProvider).removeArtistFromDay(widget.dayId, artistId);
      ref.invalidate(eventDayDetailProvider(widget.dayId));
      ref.invalidate(adminEventDetailProvider(widget.eventId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final artistsAsync = ref.watch(adminArtistsProvider);
    final dayAsync = ref.watch(eventDayDetailProvider(widget.dayId));

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.divider)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Lineup for Day ${widget.dayNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(color: AppColors.divider),
              Expanded(
                child: dayAsync.when(
                  loading: () => const LoadingView(),
                  error: (err, _) => ErrorView(message: err.toString()),
                  data: (day) {
                    return ListView(
                      children: [
                        if (day.artists.isNotEmpty) ...[
                          const Text('Current Lineup:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          ...day.artists.map((a) => ListTile(
                                leading: NetworkImageBox(url: a.photoUrl, height: 36, width: 36, borderRadius: BorderRadius.circular(18)),
                                title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${a.type}${a.isPrimary ? " · Headliner" : ""}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                  onPressed: () => _removeArtist(a.artistId),
                                ),
                              )),
                          const Divider(height: 24, color: AppColors.divider),
                        ],
                        const Text('Assign Another Artist:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        artistsAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (err, _) => Text('Error: $err'),
                          data: (all) {
                            return DropdownButtonFormField<int>(
                              initialValue: _selectedArtistId,
                              dropdownColor: AppColors.surface,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Select Artist'),
                              items: all.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.type})'))).toList(),
                              onChanged: (v) => setState(() => _selectedArtistId = v),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Headliner / Main Artist'),
                          value: _isPrimary,
                          activeColor: AppColors.neonPurple,
                          onChanged: (v) => setState(() => _isPrimary = v ?? false),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _startTime,
                                decoration: const InputDecoration(labelText: 'Start Time'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _endTime,
                                decoration: const InputDecoration(labelText: 'End Time'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: Text(_submitting ? 'Adding...' : 'Add to Lineup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonPurple,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          onPressed: _submitting ? null : _assign,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal Dialog for Day Facilities
class _DayFacilitiesDialog extends ConsumerStatefulWidget {
  final int dayId;
  final int dayNumber;

  const _DayFacilitiesDialog({required this.dayId, required this.dayNumber});

  @override
  ConsumerState<_DayFacilitiesDialog> createState() => _DayFacilitiesDialogState();
}

class _DayFacilitiesDialogState extends ConsumerState<_DayFacilitiesDialog> {
  final Set<int> _selected = {};
  Set<int> _initial = {};
  bool _initialized = false;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final allFacilitiesAsync = ref.watch(adminFacilitiesProvider);
    final dayDetailAsync = ref.watch(eventDayDetailProvider(widget.dayId));

    dayDetailAsync.whenData((day) {
      if (!_initialized) {
        _initial = day.facilities.map((f) => f.id).toSet();
        _selected.addAll(_initial);
        _initialized = true;
      }
    });

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.divider)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Facilities for Day ${widget.dayNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(color: AppColors.divider),
              Expanded(
                child: allFacilitiesAsync.when(
                  loading: () => const LoadingView(),
                  error: (err, _) => ErrorView(message: err.toString()),
                  data: (all) {
                    return ListView(
                      children: all.map((f) {
                        final isChecked = _selected.contains(f.id);
                        return CheckboxListTile(
                          title: Text(f.name),
                          value: isChecked,
                          activeColor: AppColors.neonPurple,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selected.add(f.id);
                              } else {
                                _selected.remove(f.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                ),
                onPressed: _submitting
                    ? null
                    : () async {
                        setState(() => _submitting = true);
                        try {
                          final admin = ref.read(adminServiceProvider);
                          for (final fId in _selected) {
                            if (!_initial.contains(fId)) {
                              await admin.addFacilityToDay(widget.dayId, fId);
                            }
                          }
                          for (final fId in _initial) {
                            if (!_selected.contains(fId)) {
                              await admin.removeFacilityFromDay(widget.dayId, fId);
                            }
                          }
                          ref.invalidate(eventDayDetailProvider(widget.dayId));
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
                          }
                        } finally {
                          if (mounted) setState(() => _submitting = false);
                        }
                      },
                child: Text(_submitting ? 'Saving...' : 'Save Day Facilities'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
