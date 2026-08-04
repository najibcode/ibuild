import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../data/models/bill_model.dart';

/// Professional, Formal Monochrome Building & Client Invoice PDF Generator for IBUILD ERP.
///
/// Designed strictly without colorful fonts or decorative styling for a clean, formal corporate finish.
class BuildingPdfGenerator {
  static const String _companyName = 'IBUILD';
  static const String _companyTagline = 'Building & Civil Construction ERP';

  // Professional Monochrome Palette (No colorful fonts)
  static const PdfColor _black = PdfColor.fromInt(0xFF000000);
  static const PdfColor _darkGrey = PdfColor.fromInt(0xFF333333);
  static const PdfColor _mediumGrey = PdfColor.fromInt(0xFF666666);
  static const PdfColor _lightGrey = PdfColor.fromInt(0xFFF8F9FA);
  static const PdfColor _borderGrey = PdfColor.fromInt(0xFFCCCCCC);
  static const PdfColor _white = PdfColors.white;

  static Future<Map<String, pw.Font>> _loadFonts() async {
    final regularData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final italicData = await rootBundle.load('assets/fonts/Roboto-Italic.ttf');
    return {
      'regular': pw.Font.ttf(regularData),
      'bold': pw.Font.ttf(boldData),
      'italic': pw.Font.ttf(italicData),
    };
  }

  static String _currency(double amount) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: 'INR ', decimalDigits: 2);
    return formatter.format(amount);
  }

  /// Generate single bill building PDF (Monochrome)
  static Future<Uint8List> generateBill(Bill bill) async {
    final fonts = await _loadFonts();
    final headerFont = fonts['bold']!;
    final bodyFont = fonts['regular']!;
    final italicFont = fonts['italic']!;

    final pdf = pw.Document(
      title: 'Building Invoice #${bill.billNumber} - ${bill.projectName ?? 'Site'}',
      author: _companyName,
      creator: 'IBUILD ERP Building Billing Engine',
      subject: 'Construction Client Invoice',
    );

    final now = DateTime.now();
    final dateFormatted = DateFormat('dd MMMM yyyy').format(now);
    final timeFormatted = DateFormat('hh:mm a').format(now);

    String billDateFormatted = bill.billDate;
    try {
      final parsed = DateTime.parse(bill.billDate);
      billDateFormatted = DateFormat('dd MMMM yyyy').format(parsed);
    } catch (_) {}

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: (context) => _buildFooter(context, bodyFont, italicFont, dateFormatted, timeFormatted),
        build: (context) => [
          // Header
          _buildHeader(headerFont, bodyFont),
          pw.SizedBox(height: 16),
          pw.Divider(color: _borderGrey, thickness: 1),
          pw.SizedBox(height: 12),

          // Title Row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'BUILDING CLIENT INVOICE',
                style: pw.TextStyle(font: headerFont, fontSize: 16, color: _black, letterSpacing: 1),
              ),
              pw.Text(
                'BILL #${bill.billNumber}',
                style: pw.TextStyle(font: headerFont, fontSize: 12, color: _mediumGrey),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // Details Card
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _lightGrey,
              border: pw.Border.all(color: _borderGrey, width: 0.5),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PROJECT / SITE:', style: pw.TextStyle(font: headerFont, fontSize: 8, color: _mediumGrey, letterSpacing: 0.5)),
                      pw.SizedBox(height: 4),
                      pw.Text(bill.projectName ?? 'General Construction Site', style: pw.TextStyle(font: headerFont, fontSize: 12, color: _black)),
                      pw.SizedBox(height: 4),
                      pw.Text('Invoice Date: $billDateFormatted', style: pw.TextStyle(font: bodyFont, fontSize: 9, color: _darkGrey)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _buildDetailRow('Bill Number:', '#${bill.billNumber}', headerFont, bodyFont),
                      _buildDetailRow('Status:', bill.status.toUpperCase(), headerFont, bodyFont),
                      _buildDetailRow('Total Invoiced:', _currency(bill.amount), headerFont, bodyFont),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Breakdown Section
          pw.Text('FINANCIAL BREAKDOWN', style: pw.TextStyle(font: headerFont, fontSize: 10, color: _black, letterSpacing: 0.5)),
          pw.SizedBox(height: 6),

          pw.Table(
            border: pw.TableBorder.all(color: _borderGrey, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _darkGrey),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Description / Particulars', style: pw.TextStyle(font: headerFont, fontSize: 8, color: _white)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Amount (\u20B9)', style: pw.TextStyle(font: headerFont, fontSize: 8, color: _white), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _white),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Construction Work / Milestone Billing', style: pw.TextStyle(font: headerFont, fontSize: 9, color: _black)),
                        if (bill.notes != null && bill.notes!.isNotEmpty)
                          pw.Text(bill.notes!, style: pw.TextStyle(font: bodyFont, fontSize: 8, color: _mediumGrey)),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(_currency(bill.amount), style: pw.TextStyle(font: headerFont, fontSize: 10, color: _black), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          // Grand Total Box
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const pw.BoxDecoration(
              color: _darkGrey,
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL BILL AMOUNT', style: pw.TextStyle(font: headerFont, fontSize: 12, color: _white, letterSpacing: 0.5)),
                pw.Text(_currency(bill.amount), style: pw.TextStyle(font: headerFont, fontSize: 15, color: _white)),
              ],
            ),
          ),

          pw.SizedBox(height: 35),

          // Signatures
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(width: 140, height: 0.5, color: _black),
                  pw.SizedBox(height: 4),
                  pw.Text('Client Representative', style: pw.TextStyle(font: italicFont, fontSize: 8, color: _mediumGrey)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(width: 140, height: 0.5, color: _black),
                  pw.SizedBox(height: 4),
                  pw.Text('Authorized Signatory - $_companyName', style: pw.TextStyle(font: italicFont, fontSize: 8, color: _mediumGrey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate summary report for building billing (Monochrome)
  static Future<Uint8List> generateReport({
    required List<Bill> bills,
    required double totalAmount,
    required double totalPaid,
    required double totalPending,
  }) async {
    final fonts = await _loadFonts();
    final headerFont = fonts['bold']!;
    final bodyFont = fonts['regular']!;
    final italicFont = fonts['italic']!;

    final pdf = pw.Document(
      title: 'Building Billing Summary Report',
      author: _companyName,
      creator: 'IBUILD ERP Building Billing Engine',
    );

    final now = DateTime.now();
    final dateFormatted = DateFormat('dd MMMM yyyy').format(now);
    final timeFormatted = DateFormat('hh:mm a').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: (context) => _buildFooter(context, bodyFont, italicFont, dateFormatted, timeFormatted),
        build: (context) => [
          _buildHeader(headerFont, bodyFont),
          pw.SizedBox(height: 16),
          pw.Divider(color: _borderGrey, thickness: 1),
          pw.SizedBox(height: 12),

          pw.Text('BUILDING BILLING SUMMARY REPORT', style: pw.TextStyle(font: headerFont, fontSize: 14, color: _black, letterSpacing: 1)),
          pw.SizedBox(height: 12),

          // Summary Stats Cards
          pw.Row(
            children: [
              _buildStatBox('TOTAL INVOICED', _currency(totalAmount), headerFont, bodyFont),
              pw.SizedBox(width: 8),
              _buildStatBox('PAID AMOUNT', _currency(totalPaid), headerFont, bodyFont),
              pw.SizedBox(width: 8),
              _buildStatBox('PENDING AMOUNT', _currency(totalPending), headerFont, bodyFont),
            ],
          ),
          pw.SizedBox(height: 20),

          // Bills List Table
          pw.Text('ALL BUILDING INVOICES (${bills.length})', style: pw.TextStyle(font: headerFont, fontSize: 10, color: _black, letterSpacing: 0.5)),
          pw.SizedBox(height: 6),

          pw.TableHelper.fromTextArray(
            headerAlignment: pw.Alignment.centerLeft,
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(font: headerFont, fontSize: 8, color: _white),
            cellStyle: pw.TextStyle(font: bodyFont, fontSize: 8, color: _black),
            headerDecoration: const pw.BoxDecoration(color: _darkGrey),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            oddRowDecoration: const pw.BoxDecoration(color: _lightGrey),
            border: pw.TableBorder.all(color: _borderGrey, width: 0.5),
            headers: ['Bill #', 'Project / Site', 'Date', 'Status', 'Amount (\u20B9)'],
            data: bills.map((b) {
              return [
                '#${b.billNumber}',
                b.projectName ?? 'General Site',
                b.billDate,
                b.status.toUpperCase(),
                _currency(b.amount),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildStatBox(String label, String value, pw.Font headerFont, pw.Font bodyFont) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _lightGrey,
          border: pw.Border.all(color: _borderGrey, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(font: headerFont, fontSize: 7, color: _mediumGrey, letterSpacing: 0.5)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(font: headerFont, fontSize: 11, color: _black)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildHeader(pw.Font headerFont, pw.Font bodyFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(_companyName, style: pw.TextStyle(font: headerFont, fontSize: 24, color: _black, letterSpacing: 2)),
            pw.Text(_companyTagline, style: pw.TextStyle(font: bodyFont, fontSize: 9, color: _mediumGrey)),
          ],
        ),
        pw.Text(
          'BUILDING INVOICE',
          style: pw.TextStyle(font: headerFont, fontSize: 11, color: _darkGrey, letterSpacing: 1),
        ),
      ],
    );
  }

  static pw.Widget _buildDetailRow(String label, String value, pw.Font headerFont, pw.Font bodyFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(label, style: pw.TextStyle(font: headerFont, fontSize: 8, color: _mediumGrey)),
          pw.SizedBox(width: 5),
          pw.Text(value, style: pw.TextStyle(font: bodyFont, fontSize: 9, color: _black)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, pw.Font bodyFont, pw.Font italicFont, String date, String time) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _borderGrey, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated on $date at $time | $_companyName ERP',
            style: pw.TextStyle(font: italicFont, fontSize: 8, color: _mediumGrey),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(font: bodyFont, fontSize: 8, color: _mediumGrey),
          ),
        ],
      ),
    );
  }
}
