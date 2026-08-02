import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../data/models/quotation_model.dart';

/// Professional, Formal Monochrome Quotation / Estimate PDF Generator for IBUILD ERP.
///
/// Designed strictly without colorful fonts or decorative styling for a clean, formal corporate finish.
class QuotationPdfGenerator {
  static const String _companyName = 'IBUILD';
  static const String _companyTagline = 'Construction & Project Management ERP';

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

  /// Format currency with ₹ symbol and standard Indian number formatting.
  static String _currency(double amount) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9', decimalDigits: 2);
    return formatter.format(amount);
  }

  /// Generate a formal monochrome quotation PDF.
  static Future<Uint8List> generate(Quotation quotation) async {
    final fonts = await _loadFonts();
    final headerFont = fonts['bold']!;
    final bodyFont = fonts['regular']!;
    final italicFont = fonts['italic']!;

    final pdf = pw.Document(
      title: 'Quotation - ${quotation.clientName} - ${quotation.subject}',
      author: _companyName,
      creator: 'IBUILD ERP Quotation Engine',
      subject: 'Construction Quotation Estimate',
    );

    final now = DateTime.now();
    final dateFormatted = DateFormat('dd MMMM yyyy').format(now);
    final timeFormatted = DateFormat('hh:mm a').format(now);

    String quotationDate = dateFormatted;
    if (quotation.createdAt != null && quotation.createdAt!.isNotEmpty) {
      try {
        final parsed = DateTime.parse(quotation.createdAt!);
        quotationDate = DateFormat('dd MMMM yyyy').format(parsed);
      } catch (_) {}
    }

    String? validUntilFormatted;
    if (quotation.validUntil != null && quotation.validUntil!.isNotEmpty) {
      try {
        final parsed = DateTime.parse(quotation.validUntil!);
        validUntilFormatted = DateFormat('dd MMMM yyyy').format(parsed);
      } catch (_) {
        validUntilFormatted = quotation.validUntil;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: (context) => _buildFooter(context, bodyFont, italicFont, dateFormatted, timeFormatted),
        build: (context) => [
          // ── Header ──
          _buildCompanyHeader(headerFont, bodyFont),
          pw.SizedBox(height: 16),
          pw.Divider(color: _borderGrey, thickness: 1),
          pw.SizedBox(height: 12),

          // ── Title Bar ──
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'QUOTATION ESTIMATE',
                style: pw.TextStyle(font: headerFont, fontSize: 16, color: _black, letterSpacing: 1),
              ),
              pw.Text(
                'STATUS: ${quotation.status.toUpperCase()}',
                style: pw.TextStyle(font: headerFont, fontSize: 10, color: _mediumGrey),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // ── Client & Details Section ──
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
                      pw.Text('CLIENT DETAILS:', style: pw.TextStyle(font: headerFont, fontSize: 8, color: _mediumGrey, letterSpacing: 0.5)),
                      pw.SizedBox(height: 4),
                      pw.Text(quotation.clientName, style: pw.TextStyle(font: headerFont, fontSize: 12, color: _black)),
                      if (quotation.clientPhone != null && quotation.clientPhone!.isNotEmpty)
                        pw.Text('Phone: ${quotation.clientPhone}', style: pw.TextStyle(font: bodyFont, fontSize: 9, color: _darkGrey)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _buildDetailRow('Date:', quotationDate, headerFont, bodyFont),
                      if (quotation.projectName != null)
                        _buildDetailRow('Project / Site:', quotation.projectName!, headerFont, bodyFont),
                      _buildDetailRow('Subject:', quotation.subject, headerFont, bodyFont),
                      if (validUntilFormatted != null)
                        _buildDetailRow('Valid Until:', validUntilFormatted, headerFont, bodyFont),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          // ── Itemized Particulars Table ──
          pw.Text(
            'ITEMIZED PARTICULARS',
            style: pw.TextStyle(font: headerFont, fontSize: 10, color: _black, letterSpacing: 0.5),
          ),
          pw.SizedBox(height: 6),
          _buildItemsTable(quotation.items, headerFont, bodyFont),
          pw.SizedBox(height: 10),

          // ── Grand Total Box ──
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: pw.BoxDecoration(
              color: _darkGrey,
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'GRAND TOTAL ESTIMATE',
                  style: pw.TextStyle(font: headerFont, fontSize: 12, color: _white, letterSpacing: 0.5),
                ),
                pw.Text(
                  _currency(quotation.totalAmount),
                  style: pw.TextStyle(font: headerFont, fontSize: 15, color: _white),
                ),
              ],
            ),
          ),

          // ── Terms & Notes ──
          if (quotation.notes != null && quotation.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _borderGrey, width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('TERMS & CONDITIONS', style: pw.TextStyle(font: headerFont, fontSize: 8, color: _mediumGrey, letterSpacing: 0.5)),
                  pw.SizedBox(height: 4),
                  pw.Text(quotation.notes!, style: pw.TextStyle(font: bodyFont, fontSize: 9, color: _black)),
                ],
              ),
            ),
          ],

          pw.SizedBox(height: 35),

          // ── Signatures ──
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(width: 140, height: 0.5, color: _black),
                  pw.SizedBox(height: 4),
                  pw.Text('Client Signature', style: pw.TextStyle(font: italicFont, fontSize: 8, color: _mediumGrey)),
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

  /// Company header
  static pw.Widget _buildCompanyHeader(pw.Font headerFont, pw.Font bodyFont) {
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
          'OFFICIAL QUOTATION',
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

  static pw.Widget _buildItemsTable(List<QuotationItem> items, pw.Font headerFont, pw.Font bodyFont) {
    return pw.TableHelper.fromTextArray(
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 8, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 8, color: _black),
      headerDecoration: const pw.BoxDecoration(color: _darkGrey),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      oddRowDecoration: const pw.BoxDecoration(color: _lightGrey),
      border: pw.TableBorder.all(color: _borderGrey, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(25),
        1: const pw.FlexColumnWidth(4),
        2: const pw.FixedColumnWidth(45),
        3: const pw.FixedColumnWidth(45),
        4: const pw.FixedColumnWidth(65),
        5: const pw.FixedColumnWidth(75),
      },
      headers: ['#', 'Particular', 'Unit', 'Qty', 'Rate (\u20B9)', 'Total (\u20B9)'],
      data: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return [
          '${i + 1}',
          item.particular,
          item.unit,
          item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2),
          _currency(item.unitRate),
          _currency(item.totalCost),
        ];
      }).toList(),
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
