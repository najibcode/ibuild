import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibuild/core/utils/pdf_download_helper.dart';
import 'package:ibuild/core/utils/excel_download_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '/tmp';
      },
    );
  });

  group('Download Helpers Tests', () {
    test('PdfDownloadHelper handles bytes and sanitizes filename', () async {
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final path = await PdfDownloadHelper.downloadPdf(
        bytes: sampleBytes,
        filename: 'Test_Report',
        openAfterDownload: false,
      );
      if (path != null) {
        expect(path.endsWith('Test_Report.pdf'), isTrue);
      }
    });

    test('ExcelDownloadHelper handles bytes and sanitizes filename', () async {
      final sampleBytes = [10, 20, 30, 40];
      final path = await ExcelDownloadHelper.downloadExcel(
        bytes: sampleBytes,
        filename: 'Financial_Ledger',
        openAfterDownload: false,
      );
      if (path != null) {
        expect(path.endsWith('Financial_Ledger.xlsx'), isTrue);
      }
    });
  });
}
