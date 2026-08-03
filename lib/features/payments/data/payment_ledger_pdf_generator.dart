import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../data/models/payment_ledger_model.dart';
import '../data/models/payment_model.dart';

/// Professional PDF Generator for Payment Ledger Reports & Transaction Receipts.
class PaymentLedgerPdfGenerator {
  /// Generates a complete Payment Ledger Cash Flow Report
  static Future<List<int>> generateLedgerReport(List<PaymentLedgerEntry> entries) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#1E3A8A'); // Deep Navy Blue
    final darkColor = PdfColor.fromHex('#1F2937');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Row
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
                        'Financial Payment Ledger & Cash Flow Summary',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Generated: ${DateTime.now().toIso8601String().split('T').first}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 16),

              // Ledger Table
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                headerDecoration: pw.BoxDecoration(color: primaryColor),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(6),
                headers: ['Date', 'Counterparty Name', 'Type', 'Method', 'Amount (₹)', 'Running Balance (₹)'],
                data: List.generate(entries.length, (index) {
                  final e = entries[index];
                  final isPaid = e.paymentType == 'Paid';
                  return [
                    e.paymentDate.toIso8601String().split('T').first,
                    e.counterpartyName,
                    e.paymentType,
                    e.paymentMethod,
                    '${isPaid ? '-' : '+'}₹${e.amount.toInt()}',
                    '₹${e.runningBalance.toInt()}',
                  ];
                }),
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('IBUILD ERP Financial Audit System', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('Page 1 of 1', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generates a single Site Payment Receipt PDF
  static Future<List<int>> generatePaymentReceipt(ProjectPayment payment) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#1E3A8A');
    final isReceived = payment.paymentType == 'Received';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('IBUILD ERP', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: isReceived ? PdfColor.fromHex('#059669') : PdfColor.fromHex('#DC2626'),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'OFFICIAL PAYMENT RECEIPT',
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 20),

              // Transaction Box
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F9FAFB'),
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Payment Description: ${payment.title}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Payment Type: ${payment.paymentType}', style: const pw.TextStyle(fontSize: 12)),
                        pw.Text('Payment Method: ${payment.paymentMethod}', style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Transaction Ref: ${payment.referenceNo ?? "N/A"}', style: const pw.TextStyle(fontSize: 12)),
                        pw.Text('Date: ${payment.paymentDate.toIso8601String().split('T').first}', style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                    pw.Divider(height: 20, color: PdfColors.grey300),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('TOTAL AMOUNT:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                          '${isReceived ? '+' : '-'}₹${payment.amount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: isReceived ? PdfColor.fromHex('#059669') : PdfColor.fromHex('#DC2626'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Stamp
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Anti-Fraud Verification Seal', style: pw.TextStyle(fontSize: 9, color: primaryColor, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Authorized Signature: _______________', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
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
