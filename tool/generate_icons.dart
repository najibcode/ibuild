import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

bool _isInsideRoundedRect(int px, int py, int width, int height, int radius) {
  if (px < 0 || px >= width || py < 0 || py >= height) return false;
  
  // Left-top corner
  if (px < radius && py < radius) {
    return (px - radius) * (px - radius) + (py - radius) * (py - radius) <= radius * radius;
  }
  // Right-top corner
  if (px >= width - radius && py < radius) {
    final cx = width - radius - 1;
    return (px - cx) * (px - cx) + (py - radius) * (py - radius) <= radius * radius;
  }
  // Left-bottom corner
  if (px < radius && py >= height - radius) {
    final cy = height - radius - 1;
    return (px - radius) * (px - radius) + (py - cy) * (py - cy) <= radius * radius;
  }
  // Right-bottom corner
  if (px >= width - radius && py >= height - radius) {
    final cx = width - radius - 1;
    final cy = height - radius - 1;
    return (px - cx) * (px - cx) + (py - cy) * (py - cy) <= radius * radius;
  }
  return true;
}

void _fillRect(img.Image image, int x, int y, int w, int h, img.Color color, {int radius = 0}) {
  for (int py = y; py < y + h; py++) {
    for (int px = x; px < x + w; px++) {
      if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
        if (radius <= 0 || _isInsideRoundedRect(px - x, py - y, w, h, radius)) {
          image.setPixel(px, py, color);
        }
      }
    }
  }
}

void _fillPolygon(img.Image image, List<Point<int>> points, img.Color color) {
  int minY = points.map((p) => p.y).reduce(min);
  int maxY = points.map((p) => p.y).reduce(max);

  for (int y = minY; y <= maxY; y++) {
    List<int> intersections = [];
    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];

      if ((p1.y <= y && p2.y > y) || (p2.y <= y && p1.y > y)) {
        final x = p1.x + ((y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y)).round();
        intersections.add(x);
      }
    }
    intersections.sort();
    for (int i = 0; i < intersections.length - 1; i += 2) {
      for (int x = intersections[i]; x <= intersections[i + 1]; x++) {
        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          image.setPixel(x, y, color);
        }
      }
    }
  }
}

img.Image generateConstructionIcon(int size) {
  final image = img.Image(width: size, height: size);

  final bgStartR = 0x1E, bgStartG = 0x40, bgStartB = 0xAF;
  final bgEndR = 0x0D, bgEndG = 0x25, bgEndB = 0x63;
  final cornerRadius = (size * 0.22).round();

  // 1. Draw Background Squircle
  for (int y = 0; y < size; y++) {
    final t = y / size;
    final r = (bgStartR * (1 - t) + bgEndR * t).round();
    final g = (bgStartG * (1 - t) + bgEndG * t).round();
    final b = (bgStartB * (1 - t) + bgEndB * t).round();
    final col = img.ColorRgba8(r, g, b, 0xFF);

    for (int x = 0; x < size; x++) {
      if (_isInsideRoundedRect(x, y, size, size, cornerRadius)) {
        image.setPixel(x, y, col);
      }
    }
  }

  // Column Dimensions (Normalized)
  final colW = (size * 0.18).round();
  final gap = (size * 0.04).round();
  final colRadius = max(1, (size * 0.03).round());

  final lx = (size * 0.20).round();
  final lTop = (size * 0.46).round();
  final botY = (size * 0.80).round();

  final cx = lx + colW + gap;
  final cTop = (size * 0.24).round();

  final rx = cx + colW + gap;
  final rTop = (size * 0.36).round();

  final sideWhite = img.ColorRgba8(0xFF, 0xFF, 0xFF, 0xEF);
  final pureWhite = img.ColorRgba8(0xFF, 0xFF, 0xFF, 0xFF);
  final windowCol = img.ColorRgba8(0x1E, 0x40, 0xAF, 0x66);
  final emeraldCol = img.ColorRgba8(0x10, 0xB9, 0x81, 0xFF);

  // 2. Left Column
  _fillRect(image, lx, lTop, colW, botY - lTop, sideWhite, radius: colRadius);

  // 3. Center Column (Tallest)
  _fillRect(image, cx, cTop, colW, botY - cTop, pureWhite, radius: colRadius);

  // 4. Right Column
  _fillRect(image, rx, rTop, colW, botY - rTop, sideWhite, radius: colRadius);

  // 5. Emerald Apex Crown atop Center Tower
  final apexTop = (cTop - size * 0.07).round();
  final apexBase = (cTop + size * 0.01).round();
  final apexHalfW = (colW * 0.65).round();
  final apexCenterX = cx + (colW / 2).round();

  _fillPolygon(image, [
    Point(apexCenterX, apexTop),
    Point(apexCenterX + apexHalfW, apexBase),
    Point(apexCenterX - apexHalfW, apexBase),
  ], emeraldCol);

  // 6. Windows
  final winW = (size * 0.08).round();
  final winH = max(1, (size * 0.035).round());
  final winR = max(1, (size * 0.01).round());

  // Center windows
  final winXc = cx + ((colW - winW) / 2).round();
  for (final wyFrac in [0.10, 0.20, 0.30, 0.40]) {
    final wy = (cTop + size * wyFrac).round();
    if (wy + winH < botY) {
      _fillRect(image, winXc, wy, winW, winH, windowCol, radius: winR);
    }
  }

  // Left windows
  final winXl = lx + ((colW - winW) / 2).round();
  for (final wyFrac in [0.08, 0.18]) {
    final wy = (lTop + size * wyFrac).round();
    if (wy + winH < botY) {
      _fillRect(image, winXl, wy, winW, winH, windowCol, radius: winR);
    }
  }

  // Right windows
  final winXr = rx + ((colW - winW) / 2).round();
  for (final wyFrac in [0.08, 0.18]) {
    final wy = (rTop + size * wyFrac).round();
    if (wy + winH < botY) {
      _fillRect(image, winXr, wy, winW, winH, windowCol, radius: winR);
    }
  }

  // 7. Solid Foundation Ground Beam
  final beamH = max(2, (size * 0.05).round());
  final beamY = (size * 0.85).round();
  final beamX = (size * 0.15).round();
  final beamW = (size * 0.70).round();
  _fillRect(image, beamX, beamY, beamW, beamH, pureWhite, radius: (beamH / 2).round());

  return image;
}

void main() {
  final Map<String, int> targets = {
    'web/favicon.png': 32,
    'web/favicon-16x16.png': 16,
    'web/favicon-32x32.png': 32,
    'web/favicon.ico': 32,
    'web/icons/Icon-192.png': 192,
    'web/icons/Icon-512.png': 512,
    'web/icons/Icon-maskable-192.png': 192,
    'web/icons/Icon-maskable-512.png': 512,
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
    'assets/logo/ibuild_godly_app_icon_256.png': 256,
    'assets/logo/ibuild_godly_app_icon.png': 512,
    'assets/logo/ibuild_godly_app_icon_1024.png': 1024,
  };

  print('Generating unified construction logo icons across all targets...');

  for (final entry in targets.entries) {
    final file = File(entry.key);
    final size = entry.value;
    final imgData = generateConstructionIcon(size);
    final pngBytes = img.encodePng(imgData);

    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(pngBytes);
    print('  ✓ Generated ${entry.key} (${size}x${size}, ${pngBytes.length} bytes)');
  }

  print('\nAll app icons, favicons, and web launcher icons unified successfully!');
}
