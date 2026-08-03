import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'models/sales_bill_model.dart';

/// Professional PDF Generator for Client Sales Invoices & Bills.
class SalesBillPdfGenerator {
  static Future<List<int>> generatePdf(SalesBill bill) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#1E3A8A'); // Deep Navy Blue
    final darkColor = PdfColor.fromHex('#1F2937');
    final lightColor = PdfColor.fromHex('#F3F4F6');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Row: Brand Logo & Document Title
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'IBUILD ERP',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.Text(
                        'Construction & Engineering Solutions',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'OFFICIAL SALES INVOICE',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 16),

              // Invoice Details & Client Information
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILLED TO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
                      pw.SizedBox(height: 4),
                      pw.Text(bill.clientName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkColor)),
                      if (bill.clientAddress != null && bill.clientAddress!.isNotEmpty)
                        pw.Text(bill.clientAddress!, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                      if (bill.clientGstin != null && bill.clientGstin!.isNotEmpty)
                        pw.Text('GSTIN: ${bill.clientGstin}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INVOICE NO: ${bill.billNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: primaryColor)),
                      pw.SizedBox(height: 4),
                      pw.Text('Invoice Date: ${bill.invoiceDate.toIso8601String().split('T').first}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Due Date: ${bill.dueDate.toIso8601String().split('T').first}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Status: ${bill.status.toUpperCase()}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: bill.status == 'Paid' ? PdfColors.green700 : PdfColors.orange800)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // Items Table
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: pw.BoxDecoration(color: primaryColor),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(8),
                headers: ['S.No', 'Item Description / Scope of Work', 'Qty', 'Unit Rate (₹)', 'Total (₹)'],
                data: List.generate(bill.items.length, (index) {
                  final item = bill.items[index];
                  return [
                    '${index + 1}',
                    item.description,
                    '${item.quantity}',
                    '₹${item.unitPrice.toStringAsFixed(2)}',
                    '₹${item.total.toStringAsFixed(2)}',
                  ];
                }),
              ),

              pw.SizedBox(height: 16),

              // Summary Calculations
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 240,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: lightColor,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text('₹${bill.subtotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('GST / Tax Amount:', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text('₹${bill.taxAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.Divider(thickness: 1, color: PdfColors.grey400),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('TOTAL DUE:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                            pw.Text('₹${bill.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer & Authorization Stamp
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Payment Terms: Net 30 Days', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('Anti-Fraud Verified Document Token', style: pw.TextStyle(fontSize: 9, color: primaryColor, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 120,
                        height: 36,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                        ),
                        child: pw.Center(
                          child: pw.Text('AUTHORIZED STAMP', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('For IBUILD ERP Solutions', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
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
