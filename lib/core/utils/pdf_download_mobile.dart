import 'dart:io';
import 'dart:typed_data';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> saveAndOpenPdf({
  required Uint8List bytes,
  required String filename,
  bool openAfterDownload = true,
}) async {
  Directory? targetDir;

  try {
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (downloadDir.existsSync()) {
        targetDir = downloadDir;
      }
    }
  } catch (_) {}

  try {
    targetDir ??= await getDownloadsDirectory();
  } catch (_) {}

  try {
    targetDir ??= await getExternalStorageDirectory();
  } catch (_) {}

  try {
    targetDir ??= await getApplicationDocumentsDirectory();
  } catch (_) {}

  targetDir ??= await getTemporaryDirectory();

  final filePath = '${targetDir.path}/$filename';
  final file = File(filePath);
  await file.writeAsBytes(bytes, flush: true);

  if (openAfterDownload) {
    try {
      await OpenFilex.open(filePath);
    } catch (_) {}
  }

  return filePath;
}
