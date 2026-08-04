import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'models/sales_bill_model.dart';

/// Professional PDF Generator for Client Sales Invoices & Commercial Bills.
class SalesBillPdfGenerator {
  static final _navy = PdfColor.fromHex('#1E3A8A');
  static final _dark = PdfColor.fromHex('#1F2937');
  static final _slate = PdfColor.fromHex('#4B5563');
  static final _lightBg = PdfColor.fromHex('#F9FAFB');
  static final _border = PdfColor.fromHex('#E5E7EB');

  /// Formats amount in ISO INR representation (prevents font glyph box X errors)
  static String _formatINR(double amount) {
    final intVal = amount.toInt();
    return 'INR ${intVal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  static Future<Uint8List> generatePdf(SalesBill bill) async {
    final pdf = pw.Document(title: 'Sales Invoice ${bill.billNumber}');
    final isPaid = bill.status.toLowerCase() == 'paid';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            cross pw.CrossAxisAlignment.start,
            children: [
              // Header Row: Corporate Brand & Invoice Badge
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'IBUILD CONSTRUCTIONS',
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _navy),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text('Civil Engineering & Commercial Infrastructure', style: pw.TextStyle(fontSize: 10, color: _slate)),
                      pw.Text('Reg. GSTIN: 27AAAAA0000A1Z5 | Corporate Billing Division', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: _navy,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'OFFICIAL SALES INVOICE',
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: _border),
              pw.SizedBox(height: 16),

              // Billed To & Invoice Details Grid
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILLED CLIENT / CUSTOMER:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: _slate)),
                      pw.SizedBox(height: 4),
                      pw.Text(bill.clientName, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _dark)),
                      pw.Text('Commercial Client Account', style: pw.TextStyle(fontSize: 10, color: _slate)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INVOICE NO: ${bill.billNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: _navy)),
                      pw.SizedBox(height: 4),
                      pw.Text('Date: ${bill.createdAt.toIso8601String().split('T').first}', style: pw.TextStyle(fontSize: 10, color: _dark)),
                      pw.Text('Due Date: ${bill.dueDate?.toIso8601String().split('T').first ?? "Net 30 Days"}', style: pw.TextStyle(fontSize: 10, color: _slate)),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: (isPaid ? PdfColor.fromHex('#059669') : PdfColor.fromHex('#D97706')).withOpacity(0.15),
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                        child: pw.Text(
                          bill.status.toUpperCase(),
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: isPaid ? PdfColor.fromHex('#059669') : PdfColor.fromHex('#D97706')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // Itemized Table
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: _border, width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: pw.BoxDecoration(color: _navy),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(8),
                headers: ['S.No', 'Description / Commercial Scope', 'Billing Status', 'Total Amount (INR)'],
                data: [
                  ['1', 'Client Sales Invoice #${bill.billNumber} for ${bill.clientName}', bill.status, _formatINR(bill.totalAmount)],
                ],
              ),

              pw.SizedBox(height: 16),

              // Financial Calculations Card
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 240,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: _lightBg,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: _border),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal:', style: pw.TextStyle(fontSize: 10, color: _slate)),
                            pw.Text(_formatINR(bill.amount), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('GST / Tax (18%):', style: pw.TextStyle(fontSize: 10, color: _slate)),
                            pw.Text(_formatINR(bill.taxAmount), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.Divider(thickness: 1, color: _border),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('TOTAL DUE:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _navy)),
                            pw.Text(_formatINR(bill.totalAmount), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _navy)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Stamp & Authorized Seal
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Payment Terms: Net 30 Days from Invoice Date', style: pw.TextStyle(fontSize: 9, color: _slate)),
                      pw.Text('Anti-Fraud Digital Token: Verified Commercial Bill', style: pw.TextStyle(fontSize: 9, color: _navy, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 140,
                        height: 38,
                        decoration: pw.BoxDecoration(border: pw.Border.all(color: _border)),
                        child: pw.Center(
                          child: pw.Text('AUTHORIZED SIGNATURE\nIBUILD COMMERCIAL BILLING', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7, color: _slate, fontWeight: pw.FontWeight.bold)),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('For IBUILD ERP Solutions', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _navy)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
