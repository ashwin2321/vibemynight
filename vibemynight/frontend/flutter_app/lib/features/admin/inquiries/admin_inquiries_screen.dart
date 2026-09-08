import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../models/inquiry_admin_summary.dart';
import '../widgets/admin_shell.dart';
import '../widgets/status_badge.dart';

const _statuses = ['All', 'NEW', 'CONTACTED', 'CONFIRMED', 'CANCELLED', 'COMPLETED'];

/// Admin inquiries table with search, status tabs, split details panel on wide screens,
/// quick status update, and WhatsApp launcher - matching Figma Admin Inquiries.
class AdminInquiriesScreen extends ConsumerStatefulWidget {
  const AdminInquiriesScreen({super.key});

  @override
  ConsumerState<AdminInquiriesScreen> createState() => _AdminInquiriesScreenState();
}

class _AdminInquiriesScreenState extends ConsumerState<AdminInquiriesScreen> {
  String _search = '';
  String _selectedStatus = 'All';
  InquiryAdminSummary? _selectedInquiry;
  bool _statusUpdating = false;

  Future<void> _updateStatus(int inquiryId, String newStatus) async {
    setState(() => _statusUpdating = true);
    try {
      await ref.read(adminServiceProvider).updateInquiryStatus(inquiryId, newStatus);
      ref.invalidate(adminInquiriesProvider(const InquiryFilterParams()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Inquiry status updated to $newStatus')));
        if (_selectedInquiry != null && _selectedInquiry!.id == inquiryId) {
          setState(() {
            _selectedInquiry = InquiryAdminSummary(
              id: _selectedInquiry!.id,
              inquiryNumber: _selectedInquiry!.inquiryNumber,
              customerName: _selectedInquiry!.customerName,
              customerMobile: _selectedInquiry!.customerMobile,
              eventName: _selectedInquiry!.eventName,
              dayNumber: _selectedInquiry!.dayNumber,
              date: _selectedInquiry!.date,
              artistName: _selectedInquiry!.artistName,
              ticketCategoryName: _selectedInquiry!.ticketCategoryName,
              price: _selectedInquiry!.price,
              quantity: _selectedInquiry!.quantity,
              estimatedTotal: _selectedInquiry!.estimatedTotal,
              status: newStatus,
              createdAt: _selectedInquiry!.createdAt,
            );
          });
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _statusUpdating = false);
    }
  }

  Future<void> _deleteInquiry(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Inquiry?'),
        content: const Text('This will permanently delete this customer inquiry.'),
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
      await ref.read(adminServiceProvider).deleteInquiry(id);
      setState(() => _selectedInquiry = null);
      ref.invalidate(adminInquiriesProvider(const InquiryFilterParams()));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inquiry deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _openWhatsApp(InquiryAdminSummary inquiry) {
    final phone = inquiry.customerMobile.replaceAll(RegExp(r'\D'), '');
    final cleanPhone = phone.startsWith('91') ? phone : '91$phone';
    final msg = Uri.encodeComponent(
      'Hi ${inquiry.customerName}, regarding your inquiry ${inquiry.inquiryNumber} for ${inquiry.eventName} (${inquiry.ticketCategoryName} pass)...',
    );
    final url = 'https://wa.me/$cleanPhone?text=$msg';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final params = InquiryFilterParams(
      search: _search.isEmpty ? null : _search,
      status: _selectedStatus == 'All' ? null : _selectedStatus,
    );
    final inquiriesAsync = ref.watch(adminInquiriesProvider(params));
    final isWide = MediaQuery.of(context).size.width >= 1100;

    return AdminShell(
      title: 'Inquiries',
      currentPath: '/admin/inquiries',
      body: Column(
        children: [
          // Filter / Search Toolbar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search by inquiry number, customer, mobile or event…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      fillColor: AppColors.surfaceGlass,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statuses.map((s) {
                        final selected = _selectedStatus == s;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(s),
                            selected: selected,
                            selectedColor: AppColors.neonPurple,
                            backgroundColor: AppColors.surfaceGlass,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              color: selected ? Colors.white : AppColors.textSecondary,
                            ),
                            onSelected: (_) => setState(() => _selectedStatus = s),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Table + Optional Side Details Panel
          Expanded(
            child: inquiriesAsync.when(
              loading: () => const LoadingView(),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(adminInquiriesProvider(params)),
              ),
              data: (inquiries) {
                if (inquiries.isEmpty) {
                  return const Center(
                    child: Text('No inquiries match your filter.', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table Area
                    Expanded(
                      flex: _selectedInquiry != null && isWide ? 3 : 5,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              showCheckboxColumn: false,
                              headingRowColor: WidgetStateProperty.all(AppColors.surfaceGlass),
                              horizontalMargin: 16,
                              columnSpacing: 20,
                              columns: const [
                                DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Event', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Pass', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: inquiries.map((i) {
                                final isSelected = _selectedInquiry?.id == i.id;
                                return DataRow(
                                  selected: isSelected,
                                  onSelectChanged: (_) {
                                    if (isWide) {
                                      setState(() => _selectedInquiry = i);
                                    } else {
                                      context.push('/admin/inquiries/${i.id}');
                                    }
                                  },
                                  cells: [
                                    DataCell(Text(i.inquiryNumber, style: const TextStyle(color: AppColors.neonPurple, fontWeight: FontWeight.bold))),
                                    DataCell(Text(i.customerName, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    DataCell(Text(i.customerMobile, style: const TextStyle(fontSize: 12))),
                                    DataCell(Text('${i.eventName} (D${i.dayNumber ?? "-"})', style: const TextStyle(fontSize: 12))),
                                    DataCell(Text('${i.ticketCategoryName} × ${i.quantity}', style: const TextStyle(fontSize: 12))),
                                    DataCell(Text('₹${i.estimatedTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.neonPink))),
                                    DataCell(StatusBadge(status: i.status)),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Side details panel on wide displays
                    if (_selectedInquiry != null && isWide) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: ListView(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedInquiry!.inquiryNumber,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.neonPurple),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () => setState(() => _selectedInquiry = null),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedInquiry!.customerName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                Text(
                                  _selectedInquiry!.customerMobile,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                                const SizedBox(height: 12),
                                const Divider(color: AppColors.divider),
                                const SizedBox(height: 8),
                                _DetailRow('Event', _selectedInquiry!.eventName),
                                _DetailRow('Day', 'Day ${_selectedInquiry!.dayNumber ?? "-"}'),
                                _DetailRow('Pass', _selectedInquiry!.ticketCategoryName),
                                _DetailRow('Quantity', '${_selectedInquiry!.quantity}'),
                                _DetailRow('Total', '₹${_selectedInquiry!.estimatedTotal.toStringAsFixed(0)}'),
                                _DetailRow('Created', _selectedInquiry!.createdAt?.split('T').first ?? '-'),
                                const SizedBox(height: 12),
                                const Divider(color: AppColors.divider),
                                const SizedBox(height: 8),
                                const Text('Update Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedInquiry!.status,
                                  decoration: const InputDecoration(isDense: true),
                                  items: ['NEW', 'CONTACTED', 'CONFIRMED', 'CANCELLED', 'COMPLETED']
                                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                      .toList(),
                                  onChanged: _statusUpdating
                                      ? null
                                      : (v) {
                                          if (v != null) _updateStatus(_selectedInquiry!.id, v);
                                        },
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  label: const Text('Open WhatsApp'),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                                  onPressed: () => _openWhatsApp(_selectedInquiry!),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.open_in_new),
                                  label: const Text('View Full Details'),
                                  onPressed: () => context.push('/admin/inquiries/${_selectedInquiry!.id}'),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                  label: const Text('Delete Inquiry', style: TextStyle(color: AppColors.error)),
                                  onPressed: () => _deleteInquiry(_selectedInquiry!.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
