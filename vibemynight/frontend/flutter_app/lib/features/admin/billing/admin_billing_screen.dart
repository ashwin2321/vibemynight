import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/vmn_logo.dart';
import '../../../models/inquiry_admin_summary.dart';
import '../widgets/admin_shell.dart';

/// Admin Billing & Invoice Generator Module:
/// Allows the admin to generate, calculate, and send manual or inquiry-backed invoices/bills
/// directly to customers via WhatsApp, Copy text, or PDF/Print.
class AdminBillingScreen extends ConsumerStatefulWidget {
  const AdminBillingScreen({super.key});

  @override
  ConsumerState<AdminBillingScreen> createState() => _AdminBillingScreenState();
}

class _AdminBillingScreenState extends ConsumerState<AdminBillingScreen> {
  // Mode: 0 = From Inquiry, 1 = Manual
  int _mode = 0;
  InquiryAdminSummary? _selectedInquiry;

  final _invoiceNoController = TextEditingController(
    text: 'VMN-INV-${DateTime.now().year}-${(DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}',
  );
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _eventNameController = TextEditingController();
  final _passTypeController = TextEditingController();
  final _priceController = TextEditingController(text: '999');
  final _discountController = TextEditingController(text: '0');
  final _taxPercentController = TextEditingController(text: '0');
  final _notesController = TextEditingController(
    text: 'Thank you for booking with VibeMyNight! Please present this invoice at the venue entrance.',
  );

  int _quantity = 1;
  String _paymentMethod = 'UPI';
  String _paymentStatus = 'PAID';
  DateTime _invoiceDate = DateTime.now();

  static const _paymentMethods = ['UPI', 'Cash', 'Card', 'Net Banking', 'WhatsApp Pay'];
  static const _paymentStatuses = ['PAID', 'PENDING', 'PARTIAL'];

  @override
  void dispose() {
    _invoiceNoController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _eventNameController.dispose();
    _passTypeController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _taxPercentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateFromInquiry(InquiryAdminSummary inq) {
    setState(() {
      _selectedInquiry = inq;
      _customerNameController.text = inq.customerName;
      _customerPhoneController.text = inq.customerMobile;
      _customerEmailController.text = '';
      _eventNameController.text = inq.eventName;
      _passTypeController.text = inq.ticketCategoryName;
      _priceController.text = inq.price.toStringAsFixed(0);
      _quantity = inq.quantity;
      _paymentStatus = inq.status == 'CONFIRMED' ? 'PAID' : 'PENDING';
    });
  }

  double get _unitPrice => double.tryParse(_priceController.text) ?? 0.0;
  double get _discount => double.tryParse(_discountController.text) ?? 0.0;
  double get _taxPercent => double.tryParse(_taxPercentController.text) ?? 0.0;

  double get _subtotal => _unitPrice * _quantity;
  double get _taxAmount => (_subtotal - _discount) * (_taxPercent / 100);
  double get _grandTotal {
    final net = _subtotal - _discount + _taxAmount;
    return net > 0 ? net : 0.0;
  }

  String _generateInvoiceText() {
    final buffer = StringBuffer();
    buffer.writeln('🧾 *VIBEMYNIGHT — OFFICIAL BOOKING INVOICE*');
    buffer.writeln('════════════════════════════════════');
    buffer.writeln('📋 *Invoice No:* ${_invoiceNoController.text.trim()}');
    buffer.writeln('📅 *Date:* ${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}');
    buffer.writeln('👤 *Billed To:* ${_customerNameController.text.trim()}');
    buffer.writeln('📱 *Phone:* ${_customerPhoneController.text.trim()}');
    if (_customerEmailController.text.trim().isNotEmpty) {
      buffer.writeln('✉️ *Email:* ${_customerEmailController.text.trim()}');
    }
    buffer.writeln('────────────────────────────────────');
    buffer.writeln('🎟️ *Event:* ${_eventNameController.text.trim()}');
    buffer.writeln('🎫 *Pass Tier:* ${_passTypeController.text.trim()}');
    buffer.writeln('🔢 *Quantity:* $_quantity');
    buffer.writeln('💵 *Rate per pass:* ₹${_unitPrice.toStringAsFixed(0)}');
    buffer.writeln('📊 *Subtotal:* ₹${_subtotal.toStringAsFixed(0)}');
    if (_discount > 0) {
      buffer.writeln('🏷️ *Discount:* -₹${_discount.toStringAsFixed(0)}');
    }
    if (_taxAmount > 0) {
      buffer.writeln('🏛️ *GST/Tax (${_taxPercent.toStringAsFixed(0)}%):* +₹${_taxAmount.toStringAsFixed(0)}');
    }
    buffer.writeln('────────────────────────────────────');
    buffer.writeln('💰 *GRAND TOTAL:* ₹${_grandTotal.toStringAsFixed(0)}');
    buffer.writeln('💳 *Payment Mode:* $_paymentMethod');
    buffer.writeln('📌 *Payment Status:* $_paymentStatus');
    buffer.writeln('════════════════════════════════════');
    if (_notesController.text.trim().isNotEmpty) {
      buffer.writeln('📝 *Note:* ${_notesController.text.trim()}');
    }
    buffer.writeln('✨ _Verified by VibeMyNight Pass Management_');
    return buffer.toString();
  }

  Future<void> _shareOnWhatsApp() async {
    final phone = _customerPhoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final text = Uri.encodeComponent(_generateInvoiceText());
    final url = phone.isNotEmpty ? 'https://wa.me/$phone?text=$text' : 'https://wa.me/?text=$text';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyInvoiceText() {
    Clipboard.setData(ClipboardData(text: _generateInvoiceText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invoice details copied to clipboard!')),
    );
  }

  void _resetInvoice() {
    setState(() {
      _invoiceNoController.text =
          'VMN-INV-${DateTime.now().year}-${(DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';
      _customerNameController.clear();
      _customerPhoneController.clear();
      _customerEmailController.clear();
      _eventNameController.clear();
      _passTypeController.clear();
      _priceController.text = '999';
      _discountController.text = '0';
      _taxPercentController.text = '0';
      _quantity = 1;
      _selectedInquiry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final inquiriesAsync = ref.watch(adminInquiriesProvider(const InquiryFilterParams()));
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    return AdminShell(
      title: 'Billing & Invoices',
      currentPath: '/admin/billing',
      actions: [
        IconButton(
          tooltip: 'New / Reset Invoice',
          icon: const Icon(Icons.refresh),
          onPressed: _resetInvoice,
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INVOICE & BILL GENERATOR',
                      style: TextStyle(
                        color: AppColors.neonPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Create & Send Customer Bills',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('Send on WhatsApp'),
                      onPressed: _shareOnWhatsApp,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy Bill'),
                      onPressed: _copyInvoiceText,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Two-column responsive layout
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildFormCard(inquiriesAsync)),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildReceiptPreview()),
                ],
              )
            else
              Column(
                children: [
                  _buildFormCard(inquiriesAsync),
                  const SizedBox(height: 24),
                  _buildReceiptPreview(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(AsyncValue<List<InquiryAdminSummary>> inquiriesAsync) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode Toggle: From Backend Inquiry vs Pure Manual
          Row(
            children: [
              ChoiceChip(
                label: const Text('From Existing Inquiry'),
                selected: _mode == 0,
                selectedColor: AppColors.neonPurple,
                backgroundColor: AppColors.surfaceGlass,
                labelStyle: TextStyle(
                  color: _mode == 0 ? Colors.white : AppColors.textSecondary,
                  fontWeight: _mode == 0 ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (v) => setState(() => _mode = 0),
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('Manual Entry'),
                selected: _mode == 1,
                selectedColor: AppColors.neonPink,
                backgroundColor: AppColors.surfaceGlass,
                labelStyle: TextStyle(
                  color: _mode == 1 ? Colors.white : AppColors.textSecondary,
                  fontWeight: _mode == 1 ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (v) => setState(() => _mode = 1),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Inquiry Dropdown when in mode 0
          if (_mode == 0) ...[
            inquiriesAsync.maybeWhen(
              data: (inquiries) {
                if (inquiries.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGlass,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'No inquiries in backend yet. You can switch to "Manual Entry" to create a bill.',
                      style: TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  );
                }
                return DropdownButtonFormField<InquiryAdminSummary>(
                  initialValue: _selectedInquiry,
                  hint: const Text('Select an Inquiry to Auto-Populate'),
                  dropdownColor: AppColors.surface,
                  items: inquiries.map((inq) {
                    return DropdownMenuItem(
                      value: inq,
                      child: Text(
                        '#${inq.inquiryNumber} · ${inq.customerName} (${inq.eventName})',
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) _populateFromInquiry(val);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Select Customer Inquiry',
                    prefixIcon: Icon(Icons.receipt_outlined),
                  ),
                );
              },
              orElse: () => const LinearProgressIndicator(),
            ),
            const SizedBox(height: 20),
          ],

          // Invoice Number & Date
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _invoiceNoController,
                  decoration: const InputDecoration(labelText: 'Invoice Number', isDense: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _invoiceDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _invoiceDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Invoice Date', isDense: true),
                    child: Text('${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Customer Info
          const Text('Customer Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customerNameController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Customer Name', isDense: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _customerPhoneController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Customer Phone (WhatsApp)', isDense: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customerEmailController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Customer Email (Optional)', isDense: true),
          ),
          const SizedBox(height: 20),

          // Booking Details
          const Text('Pass / Item Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _eventNameController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Event Name / Title', isDense: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _passTypeController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Pass Tier (e.g. VIP, Couple)', isDense: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pricing, Quantity, Discount & Tax
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Price per Pass (₹)', isDense: true),
                ),
              ),
              const SizedBox(width: 12),
              // Quantity stepper
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Quantity', isDense: true),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      ),
                      Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Discount (₹)', isDense: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _taxPercentController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Tax / GST %', isDense: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Payment Status & Method
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(labelText: 'Payment Method', isDense: true),
                  dropdownColor: AppColors.surface,
                  items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setState(() => _paymentMethod = v ?? 'UPI'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _paymentStatus,
                  decoration: const InputDecoration(labelText: 'Payment Status', isDense: true),
                  dropdownColor: AppColors.surface,
                  items: _paymentStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _paymentStatus = v ?? 'PAID'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Note
          TextField(
            controller: _notesController,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Customer Note / Instructions', isDense: true),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPreview() {
    final customerName = _customerNameController.text.trim().isNotEmpty ? _customerNameController.text.trim() : 'Customer Name';
    final customerPhone = _customerPhoneController.text.trim().isNotEmpty ? _customerPhoneController.text.trim() : '+91 XXXXX XXXXX';
    final eventName = _eventNameController.text.trim().isNotEmpty ? _eventNameController.text.trim() : 'Navratri Nights 2026';
    final passType = _passTypeController.text.trim().isNotEmpty ? _passTypeController.text.trim() : 'VIP Pass';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Logo & Invoice badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const VmnLogo(size: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _paymentStatus == 'PAID' ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _paymentStatus == 'PAID' ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                ),
                child: Text(
                  _paymentStatus,
                  style: TextStyle(
                    color: _paymentStatus == 'PAID' ? Colors.greenAccent : Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),

          // Invoice # & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('INVOICE NO', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 1)),
                  Text(_invoiceNoController.text.trim(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('DATE', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 1)),
                  Text('${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Billed To
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BILLED TO', style: TextStyle(fontSize: 10, color: AppColors.neonPurple, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                Text(customerPhone, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Items breakdown
          const Text('BOOKING DETAILS', style: TextStyle(fontSize: 10, color: AppColors.neonPink, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(eventName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                          Text('$passType (x$_quantity)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text('₹${_subtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Totals summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text('₹${_subtotal.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
          if (_discount > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Discount', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                Text('-₹${_discount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
              ],
            ),
          ],
          if (_taxAmount > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tax (${_taxPercent.toStringAsFixed(0)}%)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Text('+₹${_taxAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
              Text(
                '₹${_grandTotal.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFFA855F7)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Payment Mode', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              Text('$_paymentMethod ($_paymentStatus)', style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 20),

          // Action Buttons
          GradientButton(
            label: 'Send Invoice on WhatsApp',
            height: 44,
            onPressed: _shareOnWhatsApp,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Formatted Bill'),
            onPressed: _copyInvoiceText,
          ),
        ],
      ),
    );
  }
}
