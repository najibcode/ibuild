import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Generic PDF Report & Table Generator for all modules in IBUILD ERP.
class GenericPdfTableGenerator {
  static final _navy = PdfColor.fromHex('#1E3A8A');
  static final _dark = PdfColor.fromHex('#1F2937');
  static final _slate = PdfColor.fromHex('#4B5563');
  static final _lightBg = PdfColor.fromHex('#F9FAFB');
  static final _border = PdfColor.fromHex('#E5E7EB');

  /// Generates a styled A4 PDF document for any list or tabular dataset.
  static Future<Uint8List> generatePdf({
    required String title,
    required String subtitle,
    required List<String> headers,
    required List<List<String>> data,
    String? scopeName,
    Map<String, String>? summaryMetrics,
  }) async {
    final pdf = pw.Document(title: title);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'IBUILD CONSTRUCTIONS',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: _navy,
                        ),
                      ),
                      pw.Text(
                        'Civil Engineering & Enterprise Resource Planning',
                        style: pw.TextStyle(fontSize: 9, color: _slate),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _navy,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      title.toUpperCase(),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, color: _border),
              pw.SizedBox(height: 8),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: _border),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'IBUILD ERP - Official Enterprise Audit Record',
                    style: pw.TextStyle(fontSize: 8, color: _slate),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(fontSize: 8, color: _slate),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Report Scope Metadata
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Report Scope: ${scopeName ?? 'Full Enterprise Summary'}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: _dark,
                      ),
                    ),
                    pw.Text(
                      subtitle,
                      style: pw.TextStyle(fontSize: 9, color: _slate),
                    ),
                  ],
                ),
                pw.Text(
                  'Generated: ${DateTime.now().toString().split('.').first}',
                  style: pw.TextStyle(fontSize: 9, color: _slate),
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // Optional Executive Summary Metrics Card
            if (summaryMetrics != null && summaryMetrics.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: _lightBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: _border),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: summaryMetrics.entries.map((entry) {
                    return pw.Column(
                      children: [
                        pw.Text(
                          entry.key.toUpperCase(),
                          style: pw.TextStyle(fontSize: 8, color: _slate),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          entry.value,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: _navy,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              pw.SizedBox(height: 14),
            ],

            // Data Table
            pw.TableHelper.fromTextArray(
              context: context,
              border: pw.TableBorder.all(color: _border, width: 0.5),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration: pw.BoxDecoration(color: _navy),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(6),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headers: headers,
              data: data,
            ),

            pw.SizedBox(height: 20),

            // Signature & Seal Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Anti-Fraud Verified ERP Document',
                  style: pw.TextStyle(fontSize: 8, color: _slate),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 120,
                      height: 30,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _border),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'AUTHORIZED STAMP',
                          style: pw.TextStyle(
                            fontSize: 7,
                            color: _slate,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'For IBUILD ERP Solutions',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: _navy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
