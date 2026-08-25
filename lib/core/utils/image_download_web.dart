// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

/// Triggers a browser file download for an image on web.
void triggerImageDownload(Uint8List bytes, String filename) {
  final mimeType = filename.endsWith('.png')
      ? 'image/png'
      : filename.endsWith('.webp')
          ? 'image/webp'
          : 'image/jpeg';
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
