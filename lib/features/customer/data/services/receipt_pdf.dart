import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/customer_ui.dart';
import '../models/booking_info.dart';

class ReceiptPdf {
  ReceiptPdf._();

  static Future<void> share(BookingInfo b, {required String customerName}) async {
    try {
      final doc = pw.Document();
      final closed = b.completedAt ?? b.finishedAt;
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('HomeFix - Cash Receipt',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Job ${b.code}', style: const pw.TextStyle(fontSize: 11)),
          pw.Divider(),
          pw.Text('Service: ${b.title}'),
          pw.Text('Customer: $customerName'),
          pw.Text('Technician: ${b.providerName}'),
          pw.Text('Address: ${b.address}'),
          pw.Text('Completed: ${formatDate(closed, 'MMM d, yyyy h:mm a')}'),
          pw.SizedBox(height: 14),
          pw.Text('Amount paid in cash: ${formatMoney(b.amount)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 14),
          pw.Text('Customer confirmed handover: ${b.customerAttested ? 'Yes' : 'No'}'),
          pw.Text('Technician confirmed receipt: ${b.providerConfirmed ? 'Yes' : 'No'}'),
          pw.SizedBox(height: 14),
          pw.Text(
              'HomeFix 30-Day Guarantee: workmanship is protected until ${formatDate((closed ?? DateTime.now()).add(const Duration(days: 30)))}.',
              style: const pw.TextStyle(fontSize: 10)),
        ]),
      ));
      await Printing.sharePdf(bytes: await doc.save(), filename: 'homefix_receipt_${b.bookingNo}.pdf');
    } catch (_) {
      throw AdminException('Could not create the receipt PDF.');
    }
  }
}
