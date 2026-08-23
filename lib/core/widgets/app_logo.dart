import 'package:flutter/material.dart';

/// Clean, minimalistic & professional Logo for IBUILD Construction ERP.
///
/// Features a Swiss-style geometric construction monogram:
/// - Left: Royal Cobalt structural column & Emerald safety beacon forming the "i".
/// - Right: Clean architectural cantilever beam & rising building foundation forming the "B".
/// - Wordmark: Prominently highlights **"IBU"** in bold Cobalt Blue, followed by
///   high-contrast **"ILD"** and tracked **"CONSTRUCTION ERP"** subtitle.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final String? subtitle;
  final Color? color;

  /// When true the mark and wordmark render with light/white tones for dark backgrounds.
  final bool inverted;

  const AppLogo({
    super.key,
    this.size = 36,
    this.showText = true,
    this.subtitle,
    this.color,
    this.inverted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || inverted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Minimalist Construction App Icon Mark ──
        _MinimalConstructionMark(
          size: size,
          inverted: inverted,
        ),

        if (showText) ...[
          SizedBox(width: size * 0.25),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wordmark (Prominently Highlighting "IBU")
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'IBU',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: size * 0.52,
                          fontWeight: FontWeight.w900,
                          color: inverted
                              ? const Color(0xFF60A5FA)
                              : (isDark
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF1D4ED8)),
                          letterSpacing: -0.5,
                          height: 1.0,
                        ),
                      ),
                      TextSpan(
                        text: 'ILD',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: size * 0.52,
                          fontWeight: FontWeight.w900,
                          color: inverted
                              ? Colors.white
                              : (isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A)),
                          letterSpacing: -0.5,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (subtitle != null && subtitle!.isNotEmpty)
                      ? subtitle!.toUpperCase()
                      : 'CONSTRUCTION ERP',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: (size * 0.16).clamp(7.0, 11.0),
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    letterSpacing: 1.5,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Standalone Squircle App Icon Tile.
class _MinimalConstructionMark extends StatelessWidget {
  final double size;
  final bool inverted;

  const _MinimalConstructionMark({
    required this.size,
    this.inverted = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size * 0.24);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF070B18),
        borderRadius: borderRadius,
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
          width: size > 48 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E40AF).withValues(alpha: 0.22),
            blurRadius: size * 0.25,
            spreadRadius: -1,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: CustomPaint(
          size: Size(size, size),
          painter: const _MinimalConstructionPainter(),
        ),
      ),
    );
  }
}

/// Clean & Minimalist vector CustomPainter for the Construction Monogram.
class _MinimalConstructionPainter extends CustomPainter {
  const _MinimalConstructionPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Emerald Gradient for safety beacon and foundation base
    final emeraldPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF34D399),
          Color(0xFF10B981),
          Color(0xFF059669),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Royal Cobalt Gradient for structural columns and steel beams
    final cobaltPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF60A5FA),
          Color(0xFF3B82F6),
          Color(0xFF1D4ED8),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // 1. Left 'i' Top Emerald Beacon / Apex
    final beaconRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.18, w * 0.15, h * 0.15),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(beaconRect, emeraldPaint);

    // 2. Left 'i' Vertical Structural Column
    final columnRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.38, w * 0.15, h * 0.44),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(columnRect, cobaltPaint);

    // 3. Right 'B' Upper Cantilever Beam / Crane Jib
    final upperBeamRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.39, h * 0.18, w * 0.43, h * 0.28),
      topLeft: Radius.circular(w * 0.04),
      bottomLeft: Radius.circular(w * 0.04),
      topRight: Radius.circular(w * 0.14),
      bottomRight: Radius.circular(w * 0.14),
    );
    canvas.drawRRect(upperBeamRect, cobaltPaint);

    // Clean structural window cutout
    final upperCutout = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.49, h * 0.25, w * 0.20, h * 0.14),
      topLeft: Radius.circular(w * 0.02),
      bottomLeft: Radius.circular(w * 0.02),
      topRight: Radius.circular(w * 0.07),
      bottomRight: Radius.circular(w * 0.07),
    );
    canvas.drawRRect(upperCutout, Paint()..color = const Color(0xFF070B18));

    // 4. Right 'B' Lower Foundation / Rising Structure
    final lowerBuildingRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.39, h * 0.52, w * 0.43, h * 0.30),
      topLeft: Radius.circular(w * 0.04),
      bottomLeft: Radius.circular(w * 0.04),
      topRight: Radius.circular(w * 0.15),
      bottomRight: Radius.circular(w * 0.15),
    );
    canvas.drawRRect(lowerBuildingRect, emeraldPaint);

    // Clean structural foundation cutout
    final lowerCutout = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.49, h * 0.59, w * 0.20, h * 0.16),
      topLeft: Radius.circular(w * 0.02),
      bottomLeft: Radius.circular(w * 0.02),
      topRight: Radius.circular(w * 0.08),
      bottomRight: Radius.circular(w * 0.08),
    );
    canvas.drawRRect(lowerCutout, Paint()..color = const Color(0xFF070B18));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
