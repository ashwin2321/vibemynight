import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/pass_template_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../models/pass_template.dart';
import '../widgets/admin_shell.dart';

/// "MASTER PASS CATALOG & PRICING" SCREEN:
/// Dedicated admin module where organizers can configure global pass types,
/// standard rates (e.g. ₹200 Early Bird, ₹499 Regular, ₹1499 Couple),
/// default benefits, and availability presets for reuse across all events & days.
class AdminPassCatalogScreen extends ConsumerStatefulWidget {
  const AdminPassCatalogScreen({super.key});

  @override
  ConsumerState<AdminPassCatalogScreen> createState() => _AdminPassCatalogScreenState();
}

class _AdminPassCatalogScreenState extends ConsumerState<AdminPassCatalogScreen> {
  String _selectedCategory = 'ALL';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _promptNewCategory() async {
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
            Text('Add New Pass Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter new category code / title (e.g. DIAMOND, GOLDEN_CIRCLE, VIP_LOUNGE, FEMALE, STUDENT)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
      setState(() => _selectedCategory = newCat);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added category "$newCat" to catalog! 🎉'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  void _openTemplateDialog([PassTemplate? existing]) {
    showDialog(
      context: context,
      builder: (context) => _PassTemplateDialog(existing: existing),
    );
  }

  void _duplicateTemplate(PassTemplate template) {
    final copy = template.copyWith(
      id: 'tpl_${DateTime.now().millisecondsSinceEpoch}',
      name: '${template.name} (Copy)',
    );
    ref.read(passTemplatesProvider.notifier).addTemplate(copy);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Duplicated "${template.name}" as template! 📋'),
        backgroundColor: AppColors.neonPurple,
      ),
    );
  }

  Future<void> _deleteTemplate(PassTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete "${template.name}"?'),
        content: const Text('This will remove this template from your master catalog. Existing events will keep their current passes.'),
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
    if (confirmed == true) {
      ref.read(passTemplatesProvider.notifier).deleteTemplate(template.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Template "${template.name}" deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTemplates = ref.watch(passTemplatesProvider);
    final dynamicCategories = ref.watch(passCategoriesProvider);
    final search = _searchController.text.trim().toLowerCase();

    final filtered = allTemplates.where((t) {
      final matchesSearch = search.isEmpty ||
          t.name.toLowerCase().contains(search) ||
          t.type.toLowerCase().contains(search) ||
          t.price.toString().contains(search);
      final matchesCat = _selectedCategory == 'ALL' || t.type == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    return AdminShell(
      title: 'Pass Catalog & Pricing Master',
      currentPath: '/admin/pass-templates',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Pass Template'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _openTemplateDialog(),
          ),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner explanation
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.neonPurple.withValues(alpha: 0.15),
                  const Color(0xFF16102E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.neonPurple.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.confirmation_number_rounded, color: AppColors.neonPink, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Master Pass & Price Catalog',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Define standard pass tiers (e.g. ₹200 Early Entry, ₹499 Regular, ₹1499 Couple) with benefits. All templates automatically sync into your Event & Day forms for 1-click pricing!',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick Filter Row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: 'Search pass templates or prices (e.g. 200, VIP, Couple)...',
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _searchController.clear()))
                        : null,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.restore, size: 16),
                label: const Text('Reset Defaults', style: TextStyle(fontSize: 12)),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await ref.read(passTemplatesProvider.notifier).resetToDefaults();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Reset to standard pass templates!')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Category Chips + Add Category Action Chip
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'ALL',
                ...dynamicCategories,
              ].map((type) {
                final isSelected = _selectedCategory == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    selectedColor: AppColors.neonPurple,
                    onSelected: (_) => setState(() => _selectedCategory = type),
                  ),
                );
              }).toList()
                ..add(
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: ActionChip(
                      avatar: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.neonPink),
                      label: const Text('+ Add Category', style: TextStyle(fontSize: 11, color: AppColors.neonPink, fontWeight: FontWeight.bold)),
                      backgroundColor: AppColors.neonPink.withValues(alpha: 0.1),
                      side: const BorderSide(color: AppColors.neonPink),
                      onPressed: _promptNewCategory,
                    ),
                  ),
                ),
            ),
          ),

          const SizedBox(height: 20),

          // Templates Grid / List
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(Icons.search_off, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    const Text('No pass templates found matching your query.', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Template'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonPurple),
                      onPressed: () => _openTemplateDialog(),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 768;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: filtered.map((tpl) {
                    final itemWidth = isDesktop ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

                    return SizedBox(
                      width: itemWidth,
                      child: GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              tpl.name,
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.neonPurple.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                tpl.type,
                                                style: const TextStyle(color: AppColors.neonPink, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        if (tpl.description != null && tpl.description!.isNotEmpty)
                                          Text(
                                            tpl.description!,
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${tpl.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: AppColors.neonPink,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              const Divider(height: 1, color: AppColors.divider),
                              const SizedBox(height: 12),

                              // Default Stock & Limits
                              Row(
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text('Default Stock: ${tpl.defaultQuantity}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text('Max/Person: ${tpl.maxPerCustomer}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),

                              if (tpl.benefits.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: tpl.benefits.map((b) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceGlass,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.divider),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('✓ ', style: TextStyle(color: AppColors.neonBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                                          Text(b, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],

                              const SizedBox(height: 14),

                              // Card Actions
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.copy, size: 14),
                                    label: const Text('Duplicate', style: TextStyle(fontSize: 12)),
                                    onPressed: () => _duplicateTemplate(tpl),
                                  ),
                                  const SizedBox(width: 6),
                                  TextButton.icon(
                                    icon: const Icon(Icons.edit_outlined, size: 14),
                                    label: const Text('Edit', style: TextStyle(fontSize: 12)),
                                    onPressed: () => _openTemplateDialog(tpl),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                    tooltip: 'Delete',
                                    onPressed: () => _deleteTemplate(tpl),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Dialog to Add or Edit a Pass Template in the Master Catalog
class _PassTemplateDialog extends ConsumerStatefulWidget {
  final PassTemplate? existing;

  const _PassTemplateDialog({this.existing});

  @override
  ConsumerState<_PassTemplateDialog> createState() => _PassTemplateDialogState();
}

class _PassTemplateDialogState extends ConsumerState<_PassTemplateDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _quantity;
  late final TextEditingController _maxPerCustomer;
  late final TextEditingController _description;
  late final TextEditingController _benefits;
  String _type = 'REGULAR';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _price = TextEditingController(text: e != null ? e.price.toStringAsFixed(0) : '200');
    _quantity = TextEditingController(text: e != null ? e.defaultQuantity.toString() : '500');
    _maxPerCustomer = TextEditingController(text: e != null ? e.maxPerCustomer.toString() : '5');
    _description = TextEditingController(text: e?.description ?? '');
    _benefits = TextEditingController(text: e != null ? e.benefits.join(', ') : 'General entry, Dance floor access');
    _type = e?.type ?? 'REGULAR';
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
            Text('Add Custom Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _quantity.dispose();
    _maxPerCustomer.dispose();
    _description.dispose();
    _benefits.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final priceVal = double.tryParse(_price.text.trim()) ?? 200.0;
    final qtyVal = int.tryParse(_quantity.text.trim()) ?? 500;
    final maxPerCust = int.tryParse(_maxPerCustomer.text.trim()) ?? 5;
    final benefitsList = _benefits.text
        .split(',')
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty)
        .toList();

    final item = PassTemplate(
      id: widget.existing?.id ?? 'tpl_${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      type: _type,
      price: priceVal,
      defaultQuantity: qtyVal,
      maxPerCustomer: maxPerCust,
      benefits: benefitsList,
      description: _description.text.trim().isNotEmpty ? _description.text.trim() : null,
    );

    final notifier = ref.read(passTemplatesProvider.notifier);
    if (widget.existing != null) {
      notifier.updateTemplate(item);
    } else {
      notifier.addTemplate(item);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.existing != null ? 'Pass template updated!' : 'New pass template "${item.name}" created! 🎉'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final categories = ref.watch(passCategoriesProvider);
    final allCategoryOptions = categories.contains(_type) ? categories : [_type, ...categories];

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.divider)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
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
                      isEdit ? 'Edit Pass Template' : 'New Pass Template',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Pass Name *',
                    hintText: 'e.g. Early Entry ₹200, VIP Dome, Couple Pass',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _type,
                        dropdownColor: AppColors.surface,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Category Type *',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppColors.neonPink, size: 20),
                            tooltip: 'Add Custom Category',
                            onPressed: _promptAddCategory,
                          ),
                        ),
                        items: [
                          ...allCategoryOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))),
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
                        decoration: const InputDecoration(
                          labelText: 'Standard Price (₹) *',
                          prefixText: '₹ ',
                        ),
                        validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter valid price' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantity,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Default Stock *'),
                        validator: (v) => (v == null || int.tryParse(v) == null) ? 'Enter valid number' : null,
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
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Description (Optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _benefits,
                  decoration: const InputDecoration(
                    labelText: 'Default Inclusions / Benefits (comma-separated)',
                    hintText: 'e.g. AC Dome Entry, Free Parking, Food Coupon',
                  ),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  label: isEdit ? 'SAVE TEMPLATE' : 'CREATE PASS TEMPLATE',
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
