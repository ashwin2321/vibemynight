import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/csv_exporter.dart';
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
  bool _isKanbanView = true;

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
      'Hi ${inquiry.customerName}! Regarding your VibeMyNight inquiry #${inquiry.inquiryNumber} for ${inquiry.eventName} (${inquiry.ticketCategoryName} pass - ${inquiry.quantity} qty). Please find your pass booking details and let us know if you need assistance!',
    );
    final url = 'https://api.whatsapp.com/send?phone=$cleanPhone&text=$msg';
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
      title: 'Inquiries CRM Pipeline',
      currentPath: '/admin/inquiries',
      actions: [
        // View Switcher (Table vs Kanban)
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: true,
              icon: Icon(Icons.view_kanban_outlined, size: 16),
              label: Text('Kanban Board', style: TextStyle(fontSize: 12)),
            ),
            ButtonSegment(
              value: false,
              icon: Icon(Icons.table_rows_outlined, size: 16),
              label: Text('Table View', style: TextStyle(fontSize: 12)),
            ),
          ],
          selected: {_isKanbanView},
          onSelectionChanged: (set) => setState(() => _isKanbanView = set.first),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.neonPurple.withValues(alpha: 0.3);
              return AppColors.surfaceGlass;
            }),
          ),
        ),
      ],
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
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
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
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Export CSV', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.neonBlue,
                          side: const BorderSide(color: AppColors.neonBlue),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () async {
                          final currentList = inquiriesAsync.valueOrNull ?? [];
                          if (currentList.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No inquiries available to export.')),
                            );
                            return;
                          }
                          await CsvExporter.exportInquiries(currentList);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Main Content: Kanban CRM Board OR Data Table
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

                if (_isKanbanView) {
                  return _buildKanbanPipelineView(inquiries);
                }

                return _buildTableView(inquiries, isWide);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanPipelineView(List<InquiryAdminSummary> inquiries) {
    final stages = [
      {'key': 'NEW', 'title': 'New Leads', 'color': AppColors.neonPurple, 'icon': Icons.fiber_new_rounded},
      {'key': 'CONTACTED', 'title': 'Contacted / Sent', 'color': AppColors.neonBlue, 'icon': Icons.mark_chat_read_rounded},
      {'key': 'CONFIRMED', 'title': 'Confirmed / Booked', 'color': AppColors.success, 'icon': Icons.check_circle_outline_rounded},
      {'key': 'CANCELLED', 'title': 'Closed / Cancelled', 'color': AppColors.error, 'icon': Icons.cancel_outlined},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: stages.map((stage) {
          final key = stage['key'] as String;
          final title = stage['title'] as String;
          final color = stage['color'] as Color;
          final icon = stage['icon'] as IconData;

          final stageInquiries = inquiries.where((i) {
            if (key == 'NEW') return i.status == 'NEW' || i.status == 'PENDING';
            if (key == 'CONFIRMED') return i.status == 'CONFIRMED' || i.status == 'COMPLETED';
            return i.status == key;
          }).toList();

          return Container(
            width: 310,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Column Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.3))),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${stageInquiries.length}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                        ),
                      ),
                    ],
                  ),
                ),

                // Cards List
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 650),
                  child: stageInquiries.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No inquiries in this stage',
                              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 12),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(10),
                          itemCount: stageInquiries.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final inq = stageInquiries[idx];
                            return _buildKanbanCard(inq);
                          },
                        ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKanbanCard(InquiryAdminSummary inq) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inquiry ID & Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                inq.inquiryNumber,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neonPurple),
              ),
              Text(
                '₹${inq.estimatedTotal.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.neonPink),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Customer Name & Mobile
          Text(
            inq.customerName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            inq.customerMobile,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          // Event & Pass
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inq.eventName,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${inq.ticketCategoryName} × ${inq.quantity} ${inq.dayNumber != null ? "(Day ${inq.dayNumber})" : ""}',
                  style: const TextStyle(fontSize: 11, color: AppColors.neonBlue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Actions: WhatsApp & Stage Transition Dropdown
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline, size: 14),
                  label: const Text('WhatsApp', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    minimumSize: const Size(0, 32),
                  ),
                  onPressed: () => _openWhatsApp(inq),
                ),
              ),
              const SizedBox(width: 6),
              // Stage Advance Popup Menu
              PopupMenuButton<String>(
                tooltip: 'Change Stage',
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(maxWidth: 180),
                onSelected: (newStatus) => _updateStatus(inq.id, newStatus),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'NEW', child: Text('🟡 Mark as New')),
                  const PopupMenuItem(value: 'CONTACTED', child: Text('🔵 Mark Contacted')),
                  const PopupMenuItem(value: 'CONFIRMED', child: Text('🟢 Mark Confirmed')),
                  const PopupMenuItem(value: 'CANCELLED', child: Text('🔴 Mark Cancelled')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableView(List<InquiryAdminSummary> inquiries, bool isWide) {
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
                      isExpanded: true,
                      dropdownColor: AppColors.surface,
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
