import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../models/inquiry.dart';
import '../widgets/admin_shell.dart';
import '../widgets/status_badge.dart';

const _statuses = ['NEW', 'CONTACTED', 'CONFIRMED', 'CANCELLED', 'COMPLETED'];

/// Full inquiry detail with CALL CUSTOMER / OPEN WHATSAPP / status actions,
/// matching the spec's Admin Inquiry Details screen exactly.
class AdminInquiryDetailsScreen extends ConsumerStatefulWidget {
  final int inquiryId;

  const AdminInquiryDetailsScreen({super.key, required this.inquiryId});

  @override
  ConsumerState<AdminInquiryDetailsScreen> createState() => _AdminInquiryDetailsScreenState();
}

class _AdminInquiryDetailsScreenState extends ConsumerState<AdminInquiryDetailsScreen> {
  InquiryResponse? _inquiry;
  bool _loading = true;
  String? _error;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final inquiry = await ref.read(adminServiceProvider).getInquiryDetail(widget.inquiryId);
      setState(() => _inquiry = inquiry);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _setStatus(String status) async {
    setState(() => _updating = true);
    try {
      await ref.read(adminServiceProvider).updateInquiryStatus(widget.inquiryId, status);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _deleteInquiry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Inquiry?'),
        content: Text('Are you sure you want to delete inquiry ${_inquiry?.inquiryNumber ?? ''}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminServiceProvider).deleteInquiry(widget.inquiryId);
      ref.invalidate(adminInquiriesProvider(const InquiryFilterParams()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inquiry deleted')));
        context.go('/admin/inquiries');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Inquiry Details',
      currentPath: '/admin/inquiries',
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildContent(_inquiry!),
    );
  }

  Widget _buildContent(InquiryResponse inquiry) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(inquiry.inquiryNumber, style: Theme.of(context).textTheme.titleLarge),
            StatusBadge(status: inquiry.status),
          ],
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Row('Customer Name', inquiry.customerName),
              _Row('Mobile', inquiry.customerMobile),
              if (inquiry.customerEmail != null) _Row('Email', inquiry.customerEmail!),
              const Divider(color: AppColors.divider),
              _Row('Event', inquiry.eventName),
              if (inquiry.dayNumber != null) _Row('Day', 'Day ${inquiry.dayNumber}'),
              if (inquiry.date != null) _Row('Date', inquiry.date!),
              if (inquiry.programName != null) _Row('Program', inquiry.programName!),
              if (inquiry.artistName != null) _Row('Artist', inquiry.artistName!),
              if (inquiry.startTime != null && inquiry.endTime != null)
                _Row('Time', '${inquiry.startTime} - ${inquiry.endTime}'),
              if (inquiry.venue != null) _Row('Venue', inquiry.venue!),
              if (inquiry.location != null) _Row('Location', inquiry.location!),
              const Divider(color: AppColors.divider),
              _Row('Pass', inquiry.ticketCategoryName),
              _Row('Price', '₹${inquiry.price.toStringAsFixed(0)}'),
              _Row('Quantity', '${inquiry.quantity}'),
              _Row('Total', '₹${inquiry.estimatedTotal.toStringAsFixed(0)}'),
              if (inquiry.customerMessage != null && inquiry.customerMessage!.isNotEmpty)
                _Row('Message', inquiry.customerMessage!),
              if (inquiry.createdAt != null) _Row('Created At', inquiry.createdAt!),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse('tel:${inquiry.customerMobile}')),
              icon: const Icon(Icons.call_outlined),
              label: const Text('CALL CUSTOMER'),
            ),
            if (inquiry.whatsappUrl != null)
              GradientButton(
                icon: Icons.chat_bubble_outline,
                label: 'OPEN WHATSAPP',
                onPressed: () => launchUrl(Uri.parse(inquiry.whatsappUrl!), mode: LaunchMode.externalApplication),
              ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('DELETE INQUIRY'),
              onPressed: _deleteInquiry,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Update Status', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _statuses
              .map((s) => ChoiceChip(
                    label: Text(s),
                    selected: inquiry.status == s,
                    onSelected: _updating ? null : (_) => _setStatus(s),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
