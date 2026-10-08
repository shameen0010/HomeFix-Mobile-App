import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/provider_ui.dart';
import '../models/job_model.dart';

class ProviderReceipt {
  ProviderReceipt._();

  static Future<void> share(JobModel j) async {
    try {
      final doc = pw.Document();
      final closed = j.completedAt ?? j.finishedAt ?? j.scheduledAt;
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('HomeFix - Cash Receipt',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.Text('Job ${j.code}', style: const pw.TextStyle(fontSize: 11)),
          pw.Divider(),
          pw.Text('Service: ${j.title}'),
          pw.Text('Customer: ${j.customerName}'),
          pw.Text('Address: ${j.address}'),
          pw.Text('Completed: ${formatDate(closed, 'MMM d, yyyy h:mm a')}'),
          pw.SizedBox(height: 14),
          pw.Text('Cash collected: ${formatMoney(j.amount)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text('Technician confirmed receipt: ${j.receiptConfirmed ? 'Yes' : 'No'}'),
        ]),
      ));
      await Printing.sharePdf(bytes: await doc.save(), filename: 'homefix_receipt_${j.bookingNo}.pdf');
    } catch (_) {
      throw AdminException('Could not create the receipt PDF.');
    }
  }
}
