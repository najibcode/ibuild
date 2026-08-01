import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../data/models/quotation_model.dart';

/// Professional Quotation / Estimate PDF Generator for IBUILD ERP.
///
/// Produces a clean, formal construction quotation with:
/// - Company header with IBUILD branding
/// - Client details section
/// - Itemized particulars table with unit, qty, rate, total
/// - Grand total with optional terms/notes
/// - Generation timestamp in professional format
class QuotationPdfGenerator {
  static const String _companyName = 'IBUILD';
  static const String _companyTagline = 'Construction & Project Management';
  static const PdfColor _primary = PdfColor.fromInt(0xFF1565C0);
  static const PdfColor _darkBlue = PdfColor.fromInt(0xFF0D47A1);
  static const PdfColor _lightBlue = PdfColor.fromInt(0xFFE3F2FD);
  static const PdfColor _accent = PdfColor.fromInt(0xFFE65100);
  static const PdfColor _grey600 = PdfColor.fromInt(0xFF757575);
  static const PdfColor _grey200 = PdfColor.fromInt(0xFFEEEEEE);
  static const PdfColor _green = PdfColor.fromInt(0xFF2E7D32);
  static const PdfColor _white = PdfColors.white;
  static const PdfColor _rowBg = PdfColor.fromInt(0xFFF5F5F5);

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

  /// Format currency with ₹ symbol and Indian number formatting.
  static String _currency(double amount) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9', decimalDigits: 2);
    return formatter.format(amount);
  }

  /// Generate a professional quotation PDF.
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

    // Parse created date for display
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
          // ── Company Header ──
          _buildCompanyHeader(headerFont, bodyFont),
          pw.SizedBox(height: 20),

          // ── QUOTATION Title Bar ──
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: pw.BoxDecoration(
              color: _darkBlue,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'QUOTATION ESTIMATE',
                  style: pw.TextStyle(font: headerFont, fontSize: 16, color: _white, letterSpacing: 1.5),
                ),
                pw.Text(
                  'Status: ${quotation.status.toUpperCase()}',
                  style: pw.TextStyle(font: headerFont, fontSize: 10, color: _white),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // ── Client & Project Details ──
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: _lightBlue,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: _primary, width: 0.5),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TO:', style: pw.TextStyle(font: headerFont, fontSize: 9, color: _grey600)),
                      pw.SizedBox(height: 4),
                      pw.Text(quotation.clientName, style: pw.TextStyle(font: headerFont, fontSize: 13, color: _darkBlue)),
                      if (quotation.clientPhone != null && quotation.clientPhone!.isNotEmpty)
                        pw.Text('Phone: ${quotation.clientPhone}', style: pw.TextStyle(font: bodyFont, fontSize: 10, color: _grey600)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _buildDetailRow('Date:', quotationDate, headerFont, bodyFont),
                      if (quotation.projectName != null)
                        _buildDetailRow('Site:', quotation.projectName!, headerFont, bodyFont),
                      _buildDetailRow('Subject:', quotation.subject, headerFont, bodyFont),
                      if (validUntilFormatted != null)
                        _buildDetailRow('Valid Until:', validUntilFormatted, headerFont, bodyFont),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── Itemized Particulars Table ──
          pw.Text(
            'ITEMIZED PARTICULARS',
            style: pw.TextStyle(font: headerFont, fontSize: 11, color: _darkBlue, letterSpacing: 1),
          ),
          pw.SizedBox(height: 8),
          _buildItemsTable(quotation.items, headerFont, bodyFont),
          pw.SizedBox(height: 12),

          // ── Grand Total ──
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: pw.BoxDecoration(
              color: _darkBlue,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'GRAND TOTAL ESTIMATE',
                  style: pw.TextStyle(font: headerFont, fontSize: 13, color: _white, letterSpacing: 1),
                ),
                pw.Text(
                  _currency(quotation.totalAmount),
                  style: pw.TextStyle(font: headerFont, fontSize: 16, color: _white),
                ),
              ],
            ),
          ),

          // ── Notes / Terms ──
          if (quotation.notes != null && quotation.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: _rowBg,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: _grey200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('TERMS & CONDITIONS', style: pw.TextStyle(font: headerFont, fontSize: 9, color: _grey600, letterSpacing: 1)),
                  pw.SizedBox(height: 6),
                  pw.Text(quotation.notes!, style: pw.TextStyle(font: bodyFont, fontSize: 10, color: PdfColors.black)),
                ],
              ),
            ),
          ],

          pw.SizedBox(height: 30),

          // ── Signature Area ──
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(width: 150, height: 0.5, color: _grey600),
                  pw.SizedBox(height: 4),
                  pw.Text('Client Signature', style: pw.TextStyle(font: italicFont, fontSize: 9, color: _grey600)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(width: 150, height: 0.5, color: _grey600),
                  pw.SizedBox(height: 4),
                  pw.Text('Authorized Signatory - $_companyName', style: pw.TextStyle(font: italicFont, fontSize: 9, color: _grey600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Company header with IBUILD branding.
  static pw.Widget _buildCompanyHeader(pw.Font headerFont, pw.Font bodyFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(_companyName, style: pw.TextStyle(font: headerFont, fontSize: 28, color: _primary, letterSpacing: 3)),
            pw.Text(_companyTagline, style: pw.TextStyle(font: bodyFont, fontSize: 10, color: _grey600)),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: _accent,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'QUOTATION',
            style: pw.TextStyle(font: headerFont, fontSize: 12, color: _white, letterSpacing: 2),
          ),
        ),
      ],
    );
  }

  /// Detail row for right column of client section.
  static pw.Widget _buildDetailRow(String label, String value, pw.Font headerFont, pw.Font bodyFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(label, style: pw.TextStyle(font: headerFont, fontSize: 9, color: _grey600)),
          pw.SizedBox(width: 6),
          pw.Text(value, style: pw.TextStyle(font: bodyFont, fontSize: 10, color: PdfColors.black)),
        ],
      ),
    );
  }

  /// Itemized table of quotation particulars.
  static pw.Widget _buildItemsTable(List<QuotationItem> items, pw.Font headerFont, pw.Font bodyFont) {
    return pw.TableHelper.fromTextArray(
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      headerStyle: pw.TextStyle(font: headerFont, fontSize: 9, color: _white),
      cellStyle: pw.TextStyle(font: bodyFont, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: _primary),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      oddRowDecoration: const pw.BoxDecoration(color: _rowBg),
      border: pw.TableBorder.all(color: _grey200, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),  // S.No
        1: const pw.FlexColumnWidth(4),     // Particular
        2: const pw.FixedColumnWidth(50),   // Unit
        3: const pw.FixedColumnWidth(50),   // Qty
        4: const pw.FixedColumnWidth(70),   // Unit Rate
        5: const pw.FixedColumnWidth(80),   // Total
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

  /// Page footer with generation timestamp.
  static pw.Widget _buildFooter(pw.Context context, pw.Font bodyFont, pw.Font italicFont, String date, String time) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _grey200, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated on $date at $time | $_companyName ERP',
            style: pw.TextStyle(font: italicFont, fontSize: 8, color: _grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(font: bodyFont, fontSize: 8, color: _grey600),
          ),
        ],
      ),
    );
  }
}
