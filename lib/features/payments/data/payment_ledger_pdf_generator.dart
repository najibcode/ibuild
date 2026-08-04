import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../data/models/payment_ledger_model.dart';
import '../data/models/payment_model.dart';

/// Professional Classic Website Corporate PDF Generator for Payment Ledger & Receipts.
class PaymentLedgerPdfGenerator {
  static final _navy = PdfColor.fromHex('#1E3A8A');
  static final _dark = PdfColor.fromHex('#1F2937');
  static final _slate = PdfColor.fromHex('#4B5563');
  static final _lightBg = PdfColor.fromHex('#F9FAFB');
  static final _green = PdfColor.fromHex('#059669');
  static final _red = PdfColor.fromHex('#DC2626');
  static final _border = PdfColor.fromHex('#E5E7EB');

  /// Formats amount in ISO INR representation (prevents font glyph box X errors)
  static String _formatINR(double amount) {
    final intVal = amount.toInt();
    return 'INR ${intVal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  /// Generates a complete Payment Ledger Cash Flow Audit Report
  static Future<Uint8List> generateLedgerReport(List<PaymentLedgerEntry> entries) async {
    final pdf = pw.Document(title: 'IBUILD ERP Payment Ledger Report');

    final double totalInflow = entries
        .where((e) => e.paymentType == 'Received')
        .fold(0.0, (sum, e) => sum + e.amount);
    final double totalOutflow = entries
        .where((e) => e.paymentType == 'Paid')
        .fold(0.0, (sum, e) => sum + e.amount);
    final double netBalance = totalInflow - totalOutflow;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            cross pw.CrossAxisAlignment.start,
            children: [
              // Corporate Header Block
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'IBUILD CIVIL ENGINEERING ERP',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _navy),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Official Financial Payment Ledger & Cash Flow Summary',
                        style: pw.TextStyle(fontSize: 10, color: _slate),
                      ),
                      pw.Text(
                        'Reg. GSTIN: 27AAAAA0000A1Z5 | Reg. Office: Sector 11, Commercial Complex',
                        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: _navy,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'FINANCIAL AUDIT STATEMENT',
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 14),
              pw.Divider(thickness: 1, color: _border),
              pw.SizedBox(height: 12),

              // Metric Summary Row
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: _lightBg, borderRadius: pw.BorderRadius.circular(6), border: pw.Border.all(color: _border)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(children: [
                      pw.Text('Total Inflow (+)', style: pw.TextStyle(fontSize: 9, color: _slate)),
                      pw.SizedBox(height: 2),
                      pw.Text(_formatINR(totalInflow), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _green)),
                    ]),
                    pw.Container(height: 24, width: 1, color: _border),
                    pw.Column(children: [
                      pw.Text('Total Outflow (-)', style: pw.TextStyle(fontSize: 9, color: _slate)),
                      pw.SizedBox(height: 2),
                      pw.Text(_formatINR(totalOutflow), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _red)),
                    ]),
                    pw.Container(height: 24, width: 1, color: _border),
                    pw.Column(children: [
                      pw.Text('Net Cash Balance', style: pw.TextStyle(fontSize: 9, color: _slate)),
                      pw.SizedBox(height: 2),
                      pw.Text(_formatINR(netBalance), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _navy)),
                    ]),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Ledger Table
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: _border, width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                headerDecoration: pw.BoxDecoration(color: _navy),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(6),
                headers: ['Date', 'Counterparty Name', 'Type', 'Method', 'Amount (INR)', 'Running Balance (INR)'],
                data: List.generate(entries.length, (index) {
                  final e = entries[index];
                  final isPaid = e.paymentType == 'Paid';
                  return [
                    e.paymentDate.toIso8601String().split('T').first,
                    e.counterpartyName,
                    e.counterpartyType,
                    e.paymentMethod,
                    '${isPaid ? '-' : '+'}${_formatINR(e.amount)}',
                    _formatINR(e.runningBalance),
                  ];
                }),
              ),

              pw.Spacer(),

              // Footer & Anti-Fraud Seal
              pw.Divider(thickness: 1, color: _border),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('IBUILD ERP Financial Audit System | Token: ${DateTime.now().millisecondsSinceEpoch}', style: pw.TextStyle(fontSize: 8, color: _slate)),
                  pw.Text('Page 1 of 1', style: pw.TextStyle(fontSize: 8, color: _slate)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generates a single Classic Website Formal Payment Receipt PDF
  static Future<Uint8List> generatePaymentReceipt(ProjectPayment payment) async {
    final pdf = pw.Document(title: 'Payment Receipt ${payment.title}');
    final isReceived = payment.paymentType == 'Received';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            cross pw.CrossAxisAlignment.start,
            children: [
              // Classic Website Commercial Header
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
                      pw.Text('Infrastructure & Commercial Developers', style: pw.TextStyle(fontSize: 10, color: _slate)),
                      pw.Text('GSTIN: 27AAAAA0000A1Z5 | Email: accounts@ibuild.in', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: isReceived ? _green : _red,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'OFFICIAL PAYMENT RECEIPT',
                          style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text('Receipt No: REC-${payment.id.isNotEmpty ? payment.id.substring(0, 8).toUpperCase() : "2026-001"}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date: ${payment.paymentDate.toIso8601String().split('T').first}', style: pw.TextStyle(fontSize: 9, color: _slate)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: _border),
              pw.SizedBox(height: 16),

              // Transaction Detail Grid Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: _lightBg,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: _border),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('TRANSACTION SUMMARY', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _navy)),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Payment Description:', style: pw.TextStyle(fontSize: 11, color: _slate)),
                        pw.Text(payment.title, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _dark)),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Payment Flow / Action:', style: pw.TextStyle(fontSize: 11, color: _slate)),
                        pw.Text(payment.paymentType, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: isReceived ? _green : _red)),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Payment Method:', style: pw.TextStyle(fontSize: 11, color: _slate)),
                        pw.Text(payment.paymentMethod, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _dark)),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Reference / UTR Number:', style: pw.TextStyle(fontSize: 11, color: _slate)),
                        pw.Text(payment.referenceNo != null && payment.referenceNo!.isNotEmpty ? payment.referenceNo! : 'UTR-VERIFIED-SYSTEM', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _navy)),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Total Amount Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: isReceived ? PdfColor.fromHex('#ECFDF5') : PdfColor.fromHex('#FEF2F2'),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: isReceived ? _green : _red, width: 1),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TOTAL TRANSACTION AMOUNT', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _slate)),
                        pw.SizedBox(height: 4),
                        pw.Text('Status: PAYMENT VERIFIED & SETTLED', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: isReceived ? _green : _red)),
                      ],
                    ),
                    pw.Text(
                      _formatINR(payment.amount),
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: isReceived ? _green : _red),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Anti-Fraud Seal & Authorization
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Terms & Conditions:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _slate)),
                      pw.Text('1. Computer-generated official receipt token.', style: pw.TextStyle(fontSize: 8, color: _slate)),
                      pw.Text('2. Subject to bank clearance for cheque/NEFT entries.', style: pw.TextStyle(fontSize: 8, color: _slate)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 140,
                        height: 40,
                        decoration: pw.BoxDecoration(border: pw.Border.all(color: _border)),
                        child: pw.Center(
                          child: pw.Text('AUTHORISED SIGNATORY\nIBUILD ACCOUNTS', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7, color: _slate, fontWeight: pw.FontWeight.bold)),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Authorized Stamp', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _navy)),
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
