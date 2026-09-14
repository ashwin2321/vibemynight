import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../models/inquiry_admin_summary.dart';

class CsvExporter {
  static String _escapeCsv(String val) {
    if (val.contains(',') || val.contains('"') || val.contains('\n') || val.contains('\r')) {
      return '"${val.replaceAll('"', '""')}"';
    }
    return val;
  }

  /// Exports inquiry records to a downloadable CSV file.
  static Future<bool> exportInquiries(List<InquiryAdminSummary> inquiries) async {
    if (inquiries.isEmpty) return false;

    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('Inquiry ID,Customer Name,Mobile,Event,Day,Pass Category,Quantity,Price Per Ticket,Total Amount,Status,Created At');

    for (final i in inquiries) {
      final row = [
        _escapeCsv(i.inquiryNumber),
        _escapeCsv(i.customerName),
        _escapeCsv(i.customerMobile),
        _escapeCsv(i.eventName),
        _escapeCsv(i.dayNumber != null ? 'Day ${i.dayNumber}' : '-'),
        _escapeCsv(i.ticketCategoryName),
        i.quantity.toString(),
        i.price.toStringAsFixed(2),
        i.estimatedTotal.toStringAsFixed(2),
        _escapeCsv(i.status),
        _escapeCsv(i.createdAt ?? '-'),
      ];
      buffer.writeln(row.join(','));
    }

    final csvString = buffer.toString();
    final bytes = utf8.encode(csvString);
    final base64Content = base64Encode(bytes);
    final uri = Uri.parse('data:text/csv;charset=utf-8;base64,$base64Content');

    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
