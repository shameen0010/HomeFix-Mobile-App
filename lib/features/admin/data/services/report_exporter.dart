import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/admin_exception.dart';
import '../../core/admin_format.dart';
import '../models/report_data.dart';

class ReportExporter {
  ReportExporter._();

  static String _stamp(ReportData r) => formatDate(r.generatedAt, 'yyyyMMdd_HHmm');

  static Future<void> exportPdf(ReportData r) async {
    try {
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (_) => [
            pw.Text('HomeFix - ${r.title}',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(
                '${r.rangeLabel}  |  Generated ${formatDate(r.generatedAt, 'MMM d, yyyy HH:mm')}',
                style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 14),
            pw.Text(
                'Bookings: ${r.bookings.length}   Completed: ${r.completed}   Cancelled: ${r.cancelled}   Emergency: ${r.emergency}',
                style: const pw.TextStyle(fontSize: 11)),
            pw.Text(
                'Providers involved: ${r.providersInvolved}   Financial volume: ${formatMoney(r.financialVolume)}   Satisfaction: ${r.satisfactionPct.toStringAsFixed(0)}%',
                style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 6),
            pw.Text(r.summary, style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Booking', 'Service', 'Category', 'Customer', 'Provider', 'Status', 'Amount'
              ],
              data: r.bookings
                  .map((b) => [
                        b.code,
                        b.title,
                        b.category,
                        b.customerName,
                        b.providerName ?? '-',
                        b.status,
                        formatMoney(b.amount),
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
        ),
      );
      final Uint8List bytes = await doc.save();
      await Printing.sharePdf(bytes: bytes, filename: 'homefix_report_${_stamp(r)}.pdf');
    } on AdminException {
      rethrow;
    } catch (_) {
      throw AdminException('Could not create the PDF report.');
    }
  }

  static Future<void> exportExcel(ReportData r) async {
    try {
      final excel = xl.Excel.createExcel();
      final sheet = excel['Bookings'];
      excel.delete('Sheet1');
      sheet.appendRow([
        xl.TextCellValue('Booking'),
        xl.TextCellValue('Service'),
        xl.TextCellValue('Category'),
        xl.TextCellValue('Customer'),
        xl.TextCellValue('Provider'),
        xl.TextCellValue('Status'),
        xl.TextCellValue('Emergency'),
        xl.TextCellValue('Date'),
        xl.TextCellValue('Amount'),
      ]);
      for (final b in r.bookings) {
        sheet.appendRow([
          xl.TextCellValue(b.code),
          xl.TextCellValue(b.title),
          xl.TextCellValue(b.category),
          xl.TextCellValue(b.customerName),
          xl.TextCellValue(b.providerName ?? '-'),
          xl.TextCellValue(b.status),
          xl.TextCellValue(b.isEmergency ? 'Yes' : 'No'),
          xl.TextCellValue(formatDate(b.date, 'yyyy-MM-dd HH:mm')),
          xl.DoubleCellValue(b.amount),
        ]);
      }
      final summary = excel['Summary'];
      summary.appendRow([xl.TextCellValue('Report'), xl.TextCellValue(r.title)]);
      summary.appendRow([xl.TextCellValue('Range'), xl.TextCellValue(r.rangeLabel)]);
      summary.appendRow([xl.TextCellValue('Bookings'), xl.IntCellValue(r.bookings.length)]);
      summary.appendRow([xl.TextCellValue('Completed'), xl.IntCellValue(r.completed)]);
      summary.appendRow([xl.TextCellValue('Cancelled'), xl.IntCellValue(r.cancelled)]);
      summary.appendRow([xl.TextCellValue('Emergency'), xl.IntCellValue(r.emergency)]);
      summary.appendRow([xl.TextCellValue('Financial volume'), xl.DoubleCellValue(r.financialVolume)]);

      final data = excel.encode();
      if (data == null) throw AdminException('Could not build the Excel file.');
      final name = 'homefix_report_${_stamp(r)}.xlsx';
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(data),
              name: name,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            )
          ],
          subject: 'HomeFix Report',
          fileNameOverrides: [name],
        ),
      );
    } on AdminException {
      rethrow;
    } catch (_) {
      throw AdminException('Could not create the Excel report.');
    }
  }
}
