import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/providers/data_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/network_image_box.dart';
import '../../../models/event_day_detail.dart';
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

/// Rich Day Card containing day details, embedded pass price list with + Add Pass,
/// performing artists line-up, and facilities.
class _DayDetailCard extends ConsumerWidget {
  final int eventId;
  final int dayId;
  final int dayNumber;
  final String dateString;
  final String? programName;
  final VoidCallback onEditDay;
  final VoidCallback onDeleteDay;
  final VoidCallback onAddPass;
  final void Function(TicketCategory pass) onEditPass;
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
        title: Text('Delete $passName?'),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayDetailAsync = ref.watch(eventDayDetailProvider(dayId));

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Day Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonPurple.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    'DAY $dayNumber',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateString,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      if (programName != null && programName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            programName!,
                            style: const TextStyle(color: AppColors.neonPink, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit Day Info',
                  onPressed: onEditDay,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                  tooltip: 'Delete Day',
                  onPressed: onDeleteDay,
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 10),

            // Passes / Pricing Section
            dayDetailAsync.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (err, _) => Text('Error loading day details: $err', style: const TextStyle(color: AppColors.error, fontSize: 12)),
              data: (day) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Passes Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.confirmation_number_outlined, size: 16, color: AppColors.neonPurple),
                            const SizedBox(width: 6),
                            Text(
                              'Passes & Pricing (${day.passes.length})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.neonPink),
                          label: const Text('+ Add Pass / Price', style: TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: onAddPass,
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    if (day.passes.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceGlass,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'No passes added yet for this day. Add General, VIP, or Couple passes.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.neonPurple,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              onPressed: onAddPass,
                              child: const Text('+ Add Pass'),
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

                    const SizedBox(height: 14),

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
                              label: Text('${a.name}${a.isPrimary ? " (Primary)" : ""}'),
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

/// Quick Modal Dialog to Add or Edit Pass for a specific Day directly in 1 click!
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
  String? _error;

  static const _types = ['REGULAR', 'VIP', 'VVIP', 'COUPLE', 'GROUP', 'EARLY_BIRD', 'FANPIT', 'CUSTOM'];

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

    final body = {
      'name': _name.text.trim(),
      'type': _type,
      'price': double.parse(_price.text.trim()),
      'availableQuantity': int.parse(_availableQuantity.text.trim()),
      'maxPerCustomer': int.parse(_maxPerCustomer.text.trim()),
      if (_description.text.trim().isNotEmpty) 'description': _description.text.trim(),
      'benefits': _benefits.text
          .split(',')
          .map((b) => b.trim())
          .where((b) => b.isNotEmpty)
          .toList(),
    };

    try {
      final admin = ref.read(adminServiceProvider);
      if (widget.initial != null) {
        await admin.updatePass(widget.initial!.id, body);
      } else {
        await admin.createPass(widget.dayId, body);
      }
      ref.invalidate(eventDayDetailProvider(widget.dayId));
      ref.invalidate(adminEventDetailProvider(widget.eventId));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.initial != null ? 'Pass updated' : 'Pass added to Day ${widget.dayNumber}')),
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

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
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
                const SizedBox(height: 16),
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
                        decoration: const InputDecoration(labelText: 'Pass Type *'),
                        items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setState(() => _type = v ?? _type),
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
                  controller: _benefits,
                  decoration: const InputDecoration(
                    labelText: 'Benefits (comma-separated)',
                    hintText: 'e.g. General entry, Dance floor access, Free parking',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Description (Optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: _submitting ? 'SAVING...' : (isEdit ? 'UPDATE PASS' : 'ADD PASS TO DAY'),
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

/// Dialog for assigning and removing artists from an event day.
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
  bool _isPrimary = true;
  final _orderController = TextEditingController(text: '1');
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _orderController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      controller.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
    }
  }

  Future<void> _assignArtist() async {
    if (_selectedArtistId == null) {
      setState(() => _error = 'Please select an artist');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final body = {
        'artistId': _selectedArtistId,
        'isPrimary': _isPrimary,
        'performanceOrder': int.tryParse(_orderController.text.trim()) ?? 1,
        if (_startTimeController.text.trim().isNotEmpty) 'performanceStartTime': _startTimeController.text.trim(),
        if (_endTimeController.text.trim().isNotEmpty) 'performanceEndTime': _endTimeController.text.trim(),
      };
      await ref.read(adminServiceProvider).assignArtistToDay(widget.dayId, body);
      ref.invalidate(eventDayDetailProvider(widget.dayId));
      ref.invalidate(adminEventDetailProvider(widget.eventId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Artist assigned to day')));
        setState(() {
          _selectedArtistId = null;
          _startTimeController.clear();
          _endTimeController.clear();
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _removeArtist(int artistId) async {
    try {
      await ref.read(adminServiceProvider).removeArtistFromDay(widget.dayId, artistId);
      ref.invalidate(eventDayDetailProvider(widget.dayId));
      ref.invalidate(adminEventDetailProvider(widget.eventId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Artist removed from day')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayAsync = ref.watch(eventDayDetailProvider(widget.dayId));
    final artistsAsync = ref.watch(adminArtistsProvider);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.divider)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Artists for Day ${widget.dayNumber}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 12),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                const SizedBox(height: 8),
              ],
              // Assigned artists list
              Expanded(
                child: dayAsync.when(
                  loading: () => const LoadingView(),
                  error: (err, _) => ErrorView(message: err.toString()),
                  data: (day) {
                    final assigned = day.artists;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Assigned Artists (${assigned.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        if (assigned.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('No artists assigned to this day yet.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: assigned.length,
                              itemBuilder: (context, index) {
                                final a = assigned[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: NetworkImageBox(url: a.photoUrl, height: 40, width: 40, borderRadius: BorderRadius.circular(20)),
                                  title: Row(
                                    children: [
                                      Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      if (a.isPrimary) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: AppColors.neonPurple, borderRadius: BorderRadius.circular(6)),
                                          child: const Text('PRIMARY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Text('Order: ${a.performanceOrder} · ${a.performanceStartTime ?? ""} - ${a.performanceEndTime ?? ""}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                    onPressed: () => _removeArtist(a.artistId),
                                  ),
                                );
                              },
                            ),
                          ),

                        const Divider(color: AppColors.divider),
                        const SizedBox(height: 8),
                        const Text('Assign New Artist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),

                        artistsAsync.when(
                          loading: () => const LoadingView(),
                          error: (err, _) => Text('Error loading artists: $err'),
                          data: (allArtists) {
                            return Column(
                              children: [
                                DropdownButtonFormField<int>(
                                  initialValue: _selectedArtistId,
                                  decoration: const InputDecoration(labelText: 'Select Artist *', isDense: true),
                                  items: allArtists
                                      .map((a) => DropdownMenuItem(value: a.id, child: Text('${a.name} (${a.type})')))
                                      .toList(),
                                  onChanged: (v) => setState(() => _selectedArtistId = v),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _orderController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'Performance Order', isDense: true),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SwitchListTile(
                                        title: const Text('Primary', style: TextStyle(fontSize: 12)),
                                        contentPadding: EdgeInsets.zero,
                                        value: _isPrimary,
                                        onChanged: (v) => setState(() => _isPrimary = v),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _startTimeController,
                                        readOnly: true,
                                        onTap: () => _pickTime(_startTimeController),
                                        decoration: const InputDecoration(labelText: 'Start Time', isDense: true),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _endTimeController,
                                        readOnly: true,
                                        onTap: () => _pickTime(_endTimeController),
                                        decoration: const InputDecoration(labelText: 'End Time', isDense: true),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.person_add),
                                    label: Text(_submitting ? 'Assigning...' : 'Assign Artist to Day'),
                                    onPressed: _submitting ? null : _assignArtist,
                                  ),
                                ),
                              ],
                            );
                          },
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

/// Dialog for attaching/detaching facilities to a single event day.
class _DayFacilitiesDialog extends ConsumerWidget {
  final int dayId;
  final int dayNumber;

  const _DayFacilitiesDialog({required this.dayId, required this.dayNumber});

  Future<void> _toggleFacility(WidgetRef ref, int facilityId, bool isAttached) async {
    if (isAttached) {
      await ref.read(adminServiceProvider).removeFacilityFromDay(dayId, facilityId);
    } else {
      await ref.read(adminServiceProvider).addFacilityToDay(dayId, facilityId);
    }
    ref.invalidate(eventDayDetailProvider(dayId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayAsync = ref.watch(eventDayDetailProvider(dayId));
    final facilitiesAsync = ref.watch(adminFacilitiesProvider);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.divider)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 550),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Facilities for Day $dayNumber', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: dayAsync.when(
                  loading: () => const LoadingView(),
                  error: (err, _) => ErrorView(message: err.toString()),
                  data: (day) {
                    final attachedIds = day.facilities.map((f) => f.id).toSet();
                    return facilitiesAsync.when(
                      loading: () => const LoadingView(),
                      error: (err, _) => ErrorView(message: err.toString()),
                      data: (allFacilities) {
                        if (allFacilities.isEmpty) {
                          return const Center(child: Text('No facilities created yet in Admin > Facilities.'));
                        }
                        return ListView.builder(
                          itemCount: allFacilities.length,
                          itemBuilder: (context, index) {
                            final f = allFacilities[index];
                            final isAttached = attachedIds.contains(f.id);
                            return CheckboxListTile(
                              value: isAttached,
                              title: Text(f.name),
                              subtitle: f.description != null ? Text(f.description!, style: const TextStyle(fontSize: 12)) : null,
                              activeColor: AppColors.neonPurple,
                              onChanged: (v) => _toggleFacility(ref, f.id, isAttached),
                            );
                          },
                        );
                      },
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

/// Shared form for Create Day / Edit Day.
class AdminCreateDayScreen extends StatelessWidget {
  final int eventId;

  const AdminCreateDayScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) => _AdminDayForm(eventId: eventId);
}

class AdminEditDayScreen extends ConsumerWidget {
  final int dayId;

  const AdminEditDayScreen({super.key, required this.dayId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayAsync = ref.watch(eventDayDetailProvider(dayId));
    return dayAsync.when(
      loading: () => const AdminShell(title: 'Edit Day', currentPath: '/admin/events', body: LoadingView()),
      error: (err, _) => AdminShell(
        title: 'Edit Day',
        currentPath: '/admin/events',
        body: ErrorView(message: err.toString(), onRetry: () => ref.invalidate(eventDayDetailProvider(dayId))),
      ),
      data: (day) => _AdminDayForm(eventId: day.eventId, dayId: dayId, initial: day),
    );
  }
}

class _AdminDayForm extends ConsumerStatefulWidget {
  final int eventId;
  final int? dayId;
  final EventDayDetail? initial;

  const _AdminDayForm({required this.eventId, this.dayId, this.initial});

  @override
  ConsumerState<_AdminDayForm> createState() => _AdminDayFormState();
}

class _AdminDayFormState extends ConsumerState<_AdminDayForm> {
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
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _dayNumber = TextEditingController(text: d?.dayNumber.toString() ?? '');
    _date = TextEditingController(text: d?.date ?? '');
    _dayName = TextEditingController(text: d?.dayName ?? '');
    _programName = TextEditingController(text: d?.programName ?? '');
    _startTime = TextEditingController(text: d?.startTime ?? '');
    _endTime = TextEditingController(text: d?.endTime ?? '');
    _venue = TextEditingController(text: d?.venue ?? '');
    _address = TextEditingController(text: d?.address ?? '');
    _location = TextEditingController(text: d?.location ?? '');
    _googleMapsUrl = TextEditingController(text: d?.googleMapsUrl ?? '');
    _description = TextEditingController(text: d?.description ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _dayNumber, _date, _dayName, _programName, _startTime, _endTime,
      _venue, _address, _location, _googleMapsUrl, _description,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_date.text) ?? DateTime.now();
    final picked = await showDatePicker(
        context: context, initialDate: initial, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) _date.text = picked.toIso8601String().split('T').first;
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
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
      if (widget.dayId != null) {
        await admin.updateEventDay(widget.dayId!, body);
      } else {
        await admin.createEventDay(widget.eventId, body);
      }
      ref.invalidate(adminEventDetailProvider(widget.eventId));
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.dayId != null;
    return AdminShell(
      title: isEdit ? 'Edit Day' : 'Add Day',
      currentPath: '/admin/events',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _dayNumber,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Day Number *'),
              validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter a valid number' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _date,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(labelText: 'Date *'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _dayName, decoration: const InputDecoration(labelText: 'Day Name')),
            const SizedBox(height: 12),
            TextFormField(
                controller: _programName, decoration: const InputDecoration(labelText: 'Program Name')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startTime,
                    readOnly: true,
                    onTap: () => _pickTime(_startTime),
                    decoration: const InputDecoration(labelText: 'Start Time'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _endTime,
                    readOnly: true,
                    onTap: () => _pickTime(_endTime),
                    decoration: const InputDecoration(labelText: 'End Time'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _venue, decoration: const InputDecoration(labelText: 'Venue')),
            const SizedBox(height: 12),
            TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 12),
            TextFormField(controller: _location, decoration: const InputDecoration(labelText: 'Location')),
            const SizedBox(height: 12),
            TextFormField(
                controller: _googleMapsUrl, decoration: const InputDecoration(labelText: 'Google Maps URL')),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            if (_error != null) ErrorView(message: _error!),
            GradientButton(
              label: _submitting ? 'SAVING...' : (isEdit ? 'SAVE CHANGES' : 'ADD DAY'),
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
