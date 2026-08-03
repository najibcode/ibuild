import 'dart:math';

/// Standardized Document Number Generator & Verification Engine for IBUILD ERP.
///
/// Supports automatic, anti-fraud document numbering across:
/// - Bills (Vendor/Operational Expenses): BILL-YYYYMMDD-XXXX
/// - Sales Bills (Client Invoices): INV-YYYYMMDD-XXXX
/// - Quotations & Estimates: EST-YYYYMMDD-XXXX
class DocumentNumberGenerator {
  static final _random = Random();

  /// Standard Prefixes
  static const String prefixBill = 'BILL';
  static const String prefixSalesBill = 'INV';
  static const String prefixQuotation = 'EST';

  /// Generate a standardized Bill Number (e.g. BILL-20260803-7A3B)
  static String generateBillNumber({DateTime? date}) {
    return generateDocumentNumber(prefixBill, date: date);
  }

  /// Generate a standardized Sales Bill / Invoice Number (e.g. INV-20260803-5E1F)
  static String generateSalesBillNumber({DateTime? date}) {
    return generateDocumentNumber(prefixSalesBill, date: date);
  }

  /// Generate a standardized Quotation / Estimate Number (e.g. EST-20260803-9C2D)
  static String generateQuotationNumber({DateTime? date}) {
    return generateDocumentNumber(prefixQuotation, date: date);
  }

  /// Generate a standardized document number with anti-tamper checksum token.
  /// Format: PREFIX-YYYYMMDD-XXXX
  static String generateDocumentNumber(String prefix, {DateTime? date}) {
    final effectiveDate = date ?? DateTime.now();
    final dateStr = _formatDate(effectiveDate);
    
    // Generate 3 pseudo-random hex chars based on microsecond timestamp + random seed
    final seed = (effectiveDate.microsecondsSinceEpoch ^ _random.nextInt(0xFFFFFF)) & 0xFFF;
    final hexPrefix = seed.toRadixString(16).padLeft(3, '0').toUpperCase();

    // Calculate 1-char anti-tamper checksum over (prefix + dateStr + hexPrefix)
    final checksum = _calculateChecksum('$prefix$dateStr$hexPrefix');

    return '$prefix-$dateStr-$hexPrefix$checksum';
  }

  /// Verifies format structural integrity and anti-tamper checksum of a document number.
  static bool verifyAuthenticity(String documentNumber) {
    if (documentNumber.trim().isEmpty) return false;

    final parts = documentNumber.trim().split('-');
    if (parts.length != 3) return false;

    final prefix = parts[0];
    final dateStr = parts[1];
    final token = parts[2];

    if (prefix.isEmpty || dateStr.length != 8 || token.length != 4) {
      return false;
    }

    // Verify date is valid YYYYMMDD digits
    if (int.tryParse(dateStr) == null) return false;

    final hexPrefix = token.substring(0, 3);
    final providedChecksum = token.substring(3);

    final expectedChecksum = _calculateChecksum('$prefix$dateStr$hexPrefix');

    return providedChecksum.toUpperCase() == expectedChecksum.toUpperCase();
  }

  /// Format DateTime as YYYYMMDD
  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  /// Compute deterministic 1-character hex checksum (0-F)
  static String _calculateChecksum(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = (hash * 31 + input.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    final nibble = (hash ^ (hash >> 16)) & 0xF;
    return nibble.toRadixString(16).toUpperCase();
  }
}
