import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../models/facility.dart';
import '../widgets/admin_shell.dart';
import '../widgets/status_badge.dart';

/// Facilities are simple enough (name, icon, description, status) to manage
/// with an inline add/edit dialog rather than a separate route/screen.
class AdminFacilitiesScreen extends ConsumerWidget {
  const AdminFacilitiesScreen({super.key});

  Future<void> _openForm(BuildContext context, WidgetRef ref, {Facility? facility}) async {
    await showDialog(
      context: context,
      builder: (context) => _FacilityFormDialog(facility: facility),
    );
  }

  Future<void> _toggleStatus(WidgetRef ref, Facility facility) async {
    final newStatus = facility.status == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    await ref.read(adminServiceProvider).changeFacilityStatus(facility.id, newStatus);
    ref.invalidate(adminFacilitiesProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Facility facility) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${facility.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminServiceProvider).deleteFacility(facility.id);
      ref.invalidate(adminFacilitiesProvider);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilitiesAsync = ref.watch(adminFacilitiesProvider);

    return AdminShell(
      title: 'Facilities',
      currentPath: '/admin/facilities',
      actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => _openForm(context, ref)),
      ],
      body: facilitiesAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) =>
            ErrorView(message: err.toString(), onRetry: () => ref.invalidate(adminFacilitiesProvider)),
        data: (facilities) {
          if (facilities.isEmpty) {
            return const Center(child: Text('No facilities yet. Tap + to add one.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: facilities.length,
            itemBuilder: (context, index) {
              final facility = facilities[index];
              return ListTile(
                title: Text(facility.name),
                subtitle: facility.description != null ? Text(facility.description!) : null,
                leading: StatusBadge(status: facility.status),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _openForm(context, ref, facility: facility),
                    ),
                    IconButton(
                      icon: Icon(facility.status == 'ACTIVE' ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => _toggleStatus(ref, facility),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(context, ref, facility),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FacilityFormDialog extends ConsumerStatefulWidget {
  final Facility? facility;

  const _FacilityFormDialog({this.facility});

  @override
  ConsumerState<_FacilityFormDialog> createState() => _FacilityFormDialogState();
}

class _FacilityFormDialogState extends ConsumerState<_FacilityFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _icon;
  late final TextEditingController _description;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.facility?.name ?? '');
    _icon = TextEditingController(text: widget.facility?.icon ?? '');
    _description = TextEditingController(text: widget.facility?.description ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _icon.dispose();
    _description.dispose();
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
      if (_icon.text.trim().isNotEmpty) 'icon': _icon.text.trim(),
      if (_description.text.trim().isNotEmpty) 'description': _description.text.trim(),
    };
    try {
      final admin = ref.read(adminServiceProvider);
      if (widget.facility != null) {
        await admin.updateFacility(widget.facility!.id, body);
      } else {
        await admin.createFacility(body);
      }
      ref.invalidate(adminFacilitiesProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.facility != null ? 'Edit Facility' : 'Add Facility'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _icon, decoration: const InputDecoration(labelText: 'Icon (optional)')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        GradientButton(label: _submitting ? 'SAVING...' : 'SAVE', onPressed: _submitting ? null : _submit),
      ],
    );
  }
}
