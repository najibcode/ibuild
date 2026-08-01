import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../data/models/bill_model.dart';

/// Professional Building / Client Invoice PDF Generator for IBUILD ERP.
///
/// Produces a clean, architectural-style building invoice with:
/// - Company header & logo banner
/// - Invoice / Bill number, date, status
/// - Project site details
/// - Amount breakdown & payment terms
/// - Timestamped generation footer
class BuildingPdfGenerator {
  static const String _companyName = 'IBUILD';
  static const String _companyTagline = 'Building & Civil Construction ERP';
  static const PdfColor _primary = PdfColor.fromInt(0xFF1E88E5);
  static const PdfColor _darkBlue = PdfColor.fromInt(0xFF0D47A1);
  static const PdfColor _lightBg = PdfColor.fromInt(0xFFF4F6F9);
  static const PdfColor _grey600 = PdfColor.fromInt(0xFF757575);
  static const PdfColor _grey200 = PdfColor.fromInt(0xFFE0E0E0);
  static const PdfColor _green = PdfColor.fromInt(0xFF2E7D32);
  static const PdfColor _amber = PdfColor.fromInt(0xFFF57F17);
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
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9', decimalDigits: 2);
    return formatter.format(amount);
  }

  /// Generate single bill building PDF
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

    final isPaid = bill.status.toLowerCase() == 'paid';
    final statusColor = isPaid ? _green : _amber;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: (context) => _buildFooter(context, bodyFont, italicFont, dateFormatted, timeFormatted),
        build: (context) => [
          // Header
          _buildHeader(headerFont, bodyFont),
          pw.SizedBox(height: 20),

          // Title Banner
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const pw.BoxDecoration(
              color: _darkBlue,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'BUILDING CLIENT INVOICE',
                  style: pw.TextStyle(font: headerFont, fontSize: 14, color: _white, letterSpacing: 1.5),
                ),
                pw.Text(
                  'BILL #${bill.billNumber}',
                  style: pw.TextStyle(font: headerFont, fontSize: 12, color: _white),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Invoice Summary Card
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _lightBg,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: _grey200),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PROJECT / SITE LOCATION:', style: pw.TextStyle(font: headerFont, fontSize: 9, color: _grey600)),
                      pw.SizedBox(height: 4),
                      pw.Text(bill.projectName ?? 'General Construction Site', style: pw.TextStyle(font: headerFont, fontSize: 13, color: _darkBlue)),
                      pw.SizedBox(height: 8),
                      pw.Text('Bill Date: $billDateFormatted', style: pw.TextStyle(font: bodyFont, fontSize: 10, color: PdfColors.black)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: statusColor,
                          borderRadius: pw.BorderRadius.circular(12),
                        ),
                        child: pw.Text(
                          bill.status.toUpperCase(),
                          style: pw.TextStyle(font: headerFont, fontSize: 10, color: _white),
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text('TOTAL INVOICE AMOUNT', style: pw.TextStyle(font: headerFont, fontSize: 9, color: _grey600)),
                      pw.Text(_currency(bill.amount), style: pw.TextStyle(font: headerFont, fontSize: 18, color: _darkBlue)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Invoice Particulars Table
          pw.Text('BILLING DETAILS', style: pw.TextStyle(font: headerFont, fontSize: 11, color: _darkBlue, letterSpacing: 1)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(font: headerFont, fontSize: 10, color: _white),
            cellStyle: pw.TextStyle(font: bodyFont, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: _primary),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: pw.TableBorder.all(color: _grey200, width: 0.5),
            headers: ['#', 'Description / Particular', 'Category', 'Amount (\u20B9)'],
            data: [
              ['1', 'Civil Construction & Building Work - ${bill.projectName ?? 'Site'}', 'Building Billing', _currency(bill.amount)],
            ],
          ),
          pw.SizedBox(height: 12),

          // Total Bar
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const pw.BoxDecoration(color: _darkBlue, borderRadius: pw.BorderRadius.all(pw.Radius.circular(4))),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL PAYABLE AMOUNT', style: pw.TextStyle(font: headerFont, fontSize: 12, color: _white)),
                pw.Text(_currency(bill.amount), style: pw.TextStyle(font: headerFont, fontSize: 16, color: _white)),
              ],
            ),
          ),

          if (bill.notes != null && bill.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: _lightBg, borderRadius: pw.BorderRadius.circular(4), border: pw.Border.all(color: _grey200)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('REMARKS & NOTES', style: pw.TextStyle(font: headerFont, fontSize: 9, color: _grey600)),
                  pw.SizedBox(height: 4),
                  pw.Text(bill.notes!, style: pw.TextStyle(font: bodyFont, fontSize: 10)),
                ],
              ),
            ),
          ],

          pw.SizedBox(height: 40),

          // Signatures
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(width: 140, height: 0.5, color: _grey600),
                  pw.SizedBox(height: 4),
                  pw.Text('Client Approval', style: pw.TextStyle(font: italicFont, fontSize: 9, color: _grey600)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(width: 140, height: 0.5, color: _grey600),
                  pw.SizedBox(height: 4),
                  pw.Text('Authorized Manager - $_companyName', style: pw.TextStyle(font: italicFont, fontSize: 9, color: _grey600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Generate full building summary report (all bills)
  static Future<Uint8List> generateBuildingReport(List<Bill> bills) async {
    final fonts = await _loadFonts();
    final headerFont = fonts['bold']!;
    final bodyFont = fonts['regular']!;
    final italicFont = fonts['italic']!;

    final pdf = pw.Document(
      title: 'IBUILD Building Billing Summary Report',
      author: _companyName,
      creator: 'IBUILD ERP Report Engine',
    );

    final now = DateTime.now();
    final dateFormatted = DateFormat('dd MMMM yyyy').format(now);
    final timeFormatted = DateFormat('hh:mm a').format(now);

    final double totalAmount = bills.fold(0.0, (sum, b) => sum + b.amount);
    final double paidAmount = bills.where((b) => b.status.toLowerCase() == 'paid').fold(0.0, (sum, b) => sum + b.amount);
    final double pendingAmount = totalAmount - paidAmount;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: (context) => _buildFooter(context, bodyFont, italicFont, dateFormatted, timeFormatted),
        build: (context) => [
          _buildHeader(headerFont, bodyFont),
          pw.SizedBox(height: 20),

          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const pw.BoxDecoration(color: _darkBlue, borderRadius: pw.BorderRadius.all(pw.Radius.circular(4))),
            child: pw.Text('BUILDING BILLING & REVENUE REPORT', style: pw.TextStyle(font: headerFont, fontSize: 14, color: _white, letterSpacing: 1.5)),
          ),
          pw.SizedBox(height: 16),

          // Metrics
          pw.Row(
            children: [
              _buildMetricBox('TOTAL INVOICED', _currency(totalAmount), _darkBlue, headerFont, bodyFont),
              pw.SizedBox(width: 10),
              _buildMetricBox('COLLECTED (PAID)', _currency(paidAmount), _green, headerFont, bodyFont),
              pw.SizedBox(width: 10),
              _buildMetricBox('PENDING BALANCE', _currency(pendingAmount), _amber, headerFont, bodyFont),
            ],
          ),
          pw.SizedBox(height: 20),

          pw.Text('ALL BUILDING BILLS LOG', style: pw.TextStyle(font: headerFont, fontSize: 11, color: _darkBlue, letterSpacing: 1)),
          pw.SizedBox(height: 8),

          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(font: headerFont, fontSize: 9, color: _white),
            cellStyle: pw.TextStyle(font: bodyFont, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: _primary),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            border: pw.TableBorder.all(color: _grey200, width: 0.5),
            headers: ['Bill #', 'Project / Site', 'Date', 'Status', 'Amount (\u20B9)'],
            data: bills.map((b) => [
              '#${b.billNumber}',
              b.projectName ?? 'General Site',
              b.billDate,
              b.status.toUpperCase(),
              _currency(b.amount),
            ]).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(pw.Font headerFont, pw.Font bodyFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(_companyName, style: pw.TextStyle(font: headerFont, fontSize: 26, color: _primary, letterSpacing: 3)),
            pw.Text(_companyTagline, style: pw.TextStyle(font: bodyFont, fontSize: 10, color: _grey600)),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(color: _darkBlue, borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Text('BUILDING BILLING', style: pw.TextStyle(font: headerFont, fontSize: 11, color: _white, letterSpacing: 1)),
        ),
      ],
    );
  }

  static pw.Widget _buildMetricBox(String label, String val, PdfColor col, pw.Font headerFont, pw.Font bodyFont) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(color: _lightBg, borderRadius: pw.BorderRadius.circular(4), border: pw.Border.all(color: _grey200)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(font: headerFont, fontSize: 8, color: _grey600)),
            pw.SizedBox(height: 4),
            pw.Text(val, style: pw.TextStyle(font: headerFont, fontSize: 12, color: col)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, pw.Font bodyFont, pw.Font italicFont, String date, String time) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _grey200, width: 0.5))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generated on $date at $time | $_companyName ERP Building Division', style: pw.TextStyle(font: italicFont, fontSize: 8, color: _grey600)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(font: bodyFont, fontSize: 8, color: _grey600)),
        ],
      ),
    );
  }
}
