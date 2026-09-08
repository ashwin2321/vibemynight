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
import '../../../models/ticket_category.dart';
import '../widgets/admin_shell.dart';

/// "MANAGE PASSES" for a single day - list + add/edit/delete, matching the
/// spec's Admin Pass Management screen. Prices/availability are per-day and
/// independent of every other day, as required.
class AdminManagePassesScreen extends ConsumerWidget {
  final int eventDayId;

  const AdminManagePassesScreen({super.key, required this.eventDayId});

  Future<void> _delete(BuildContext context, WidgetRef ref, int passId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete pass?'),
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
      ref.invalidate(eventDayDetailProvider(eventDayId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayAsync = ref.watch(eventDayDetailProvider(eventDayId));

    return AdminShell(
      title: 'Manage Passes',
      currentPath: '/admin/events',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Pass'),
            onPressed: () => context.push('/admin/event-days/$eventDayId/passes/new'),
          ),
        ),
      ],
      body: dayAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) =>
            ErrorView(message: err.toString(), onRetry: () => ref.invalidate(eventDayDetailProvider(eventDayId))),
        data: (day) {
          if (day.passes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.confirmation_number_outlined, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  const Text('No passes added for this day yet.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Pass'),
                    onPressed: () => context.push('/admin/event-days/$eventDayId/passes/new'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: day.passes.length,
            itemBuilder: (context, index) {
              final pass = day.passes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(pass.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.neonPurple.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(pass.type, style: const TextStyle(color: AppColors.neonPink, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${pass.price.toStringAsFixed(0)} · Available: ${pass.availableQuantity} · Max/customer: ${pass.maxPerCustomer}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            if (pass.benefits.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  pass.benefits.join(' · '),
                                  style: const TextStyle(color: AppColors.neonBlue, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => context.push('/admin/event-days/$eventDayId/passes/${pass.id}/edit'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () => _delete(context, ref, pass.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminCreatePassScreen extends StatelessWidget {
  final int eventDayId;

  const AdminCreatePassScreen({super.key, required this.eventDayId});

  @override
  Widget build(BuildContext context) => _AdminPassForm(eventDayId: eventDayId);
}

class AdminEditPassScreen extends ConsumerWidget {
  final int eventDayId;
  final int passId;

  const AdminEditPassScreen({super.key, required this.eventDayId, required this.passId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayAsync = ref.watch(eventDayDetailProvider(eventDayId));
    return dayAsync.when(
      loading: () => const AdminShell(title: 'Edit Pass', currentPath: '/admin/events', body: LoadingView()),
      error: (err, _) => AdminShell(
        title: 'Edit Pass',
        currentPath: '/admin/events',
        body: ErrorView(message: err.toString(), onRetry: () => ref.invalidate(eventDayDetailProvider(eventDayId))),
      ),
      data: (day) {
        TicketCategory? pass;
        for (final p in day.passes) {
          if (p.id == passId) {
            pass = p;
            break;
          }
        }
        if (pass == null) {
          return const AdminShell(
            title: 'Edit Pass',
            currentPath: '/admin/events',
            body: Center(child: Text('Pass not found.')),
          );
        }
        return _AdminPassForm(eventDayId: eventDayId, passId: passId, initial: pass);
      },
    );
  }
}

class _AdminPassForm extends ConsumerStatefulWidget {
  final int eventDayId;
  final int? passId;
  final TicketCategory? initial;

  const _AdminPassForm({required this.eventDayId, this.passId, this.initial});

  @override
  ConsumerState<_AdminPassForm> createState() => _AdminPassFormState();
}

class _AdminPassFormState extends ConsumerState<_AdminPassForm> {
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

  static const _types = ['REGULAR', 'VIP', 'COUPLE', 'GROUP', 'EARLY_BIRD', 'PREMIUM', 'CUSTOM'];

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: p?.price.toString() ?? '');
    _availableQuantity = TextEditingController(text: p?.availableQuantity.toString() ?? '');
    _maxPerCustomer = TextEditingController(text: p?.maxPerCustomer.toString() ?? '10');
    _description = TextEditingController(text: p?.description ?? '');
    _benefits = TextEditingController(text: p?.benefits.join(', ') ?? '');
    _type = p?.type ?? 'REGULAR';
  }

  @override
  void dispose() {
    for (final c in [_name, _price, _availableQuantity, _maxPerCustomer, _description, _benefits]) {
      c.dispose();
    }
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
      if (widget.passId != null) {
        await admin.updatePass(widget.passId!, body);
      } else {
        await admin.createPass(widget.eventDayId, body);
      }
      ref.invalidate(eventDayDetailProvider(widget.eventDayId));
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.passId != null;
    return AdminShell(
      title: isEdit ? 'Edit Pass' : 'Create Pass',
      currentPath: '/admin/events',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Pass Name *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Pass Type *'),
              items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price (₹) *'),
              validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter a valid price' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _availableQuantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Available Quantity *'),
              validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter a valid number' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _maxPerCustomer,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Max Per Customer *'),
              validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter a valid number' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _benefits,
              decoration: const InputDecoration(labelText: 'Benefits (comma-separated)'),
            ),
            const SizedBox(height: 20),
            if (_error != null) ErrorView(message: _error!),
            GradientButton(
              label: _submitting ? 'SAVING...' : (isEdit ? 'SAVE CHANGES' : 'CREATE PASS'),
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
