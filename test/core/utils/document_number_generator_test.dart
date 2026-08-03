import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/core/utils/document_number_generator.dart';

void main() {
  group('DocumentNumberGenerator Tests', () {
    test('generateBillNumber creates valid BILL-YYYYMMDD-XXXX format', () {
      final now = DateTime(2026, 8, 3);
      final billNo = DocumentNumberGenerator.generateBillNumber(date: now);

      expect(billNo.startsWith('BILL-20260803-'), isTrue);
      expect(billNo.length, equals(19)); // BILL-20260803-XXXX
      expect(DocumentNumberGenerator.verifyAuthenticity(billNo), isTrue);
    });

    test('generateSalesBillNumber creates valid INV-YYYYMMDD-XXXX format', () {
      final now = DateTime(2026, 8, 3);
      final invNo = DocumentNumberGenerator.generateSalesBillNumber(date: now);

      expect(invNo.startsWith('INV-20260803-'), isTrue);
      expect(invNo.length, equals(18)); // INV-20260803-XXXX
      expect(DocumentNumberGenerator.verifyAuthenticity(invNo), isTrue);
    });

    test('generateQuotationNumber creates valid EST-YYYYMMDD-XXXX format', () {
      final now = DateTime(2026, 8, 3);
      final estNo = DocumentNumberGenerator.generateQuotationNumber(date: now);

      expect(estNo.startsWith('EST-20260803-'), isTrue);
      expect(estNo.length, equals(18)); // EST-20260803-XXXX
      expect(DocumentNumberGenerator.verifyAuthenticity(estNo), isTrue);
    });

    test('verifyAuthenticity detects tampered checksums and invalid formats', () {
      final validNo = DocumentNumberGenerator.generateBillNumber();
      expect(DocumentNumberGenerator.verifyAuthenticity(validNo), isTrue);

      // Tamper with checksum character
      final tamperedChar = validNo.substring(0, validNo.length - 1) + 
          (validNo.endsWith('0') ? '1' : '0');
      expect(DocumentNumberGenerator.verifyAuthenticity(tamperedChar), isFalse);

      // Invalid formats
      expect(DocumentNumberGenerator.verifyAuthenticity('INVALID-STRING'), isFalse);
      expect(DocumentNumberGenerator.verifyAuthenticity('BILL-20260803'), isFalse);
      expect(DocumentNumberGenerator.verifyAuthenticity(''), isFalse);
    });
  });
}
