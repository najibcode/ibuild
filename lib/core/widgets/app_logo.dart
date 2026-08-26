import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Clean, neat, and minimalistic logo for IBUILD Construction ERP.
///
/// Features classic architectural construction skyline columns with an emerald apex
/// and solid foundation base beam, unmistakably representing a construction company.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final String? subtitle;
  final Color? color;

  /// When true, renders with light/white tones for dark backgrounds.
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
    final primaryCol = color ?? AppColors.primaryColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark || inverted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Clean Construction Icon Tile ──
        _ConstructionLogoMark(
          size: size,
          primaryColor: primaryCol,
          accentColor: const Color(0xFF10B981), // Emerald Safety Accent
          inverted: inverted,
        ),

        if (showText) ...[
          SizedBox(width: size * 0.28),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wordmark: Highlighting IBU
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
                          letterSpacing: 0.2,
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
                          letterSpacing: 0.2,
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

/// Standalone construction company logo mark tile.
class _ConstructionLogoMark extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color accentColor;
  final bool inverted;

  const _ConstructionLogoMark({
    required this.size,
    required this.primaryColor,
    required this.accentColor,
    this.inverted = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size * 0.22);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            Color.lerp(primaryColor, const Color(0xFF0D2563), 0.35)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.30),
            blurRadius: size * 0.28,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: CustomPaint(
          size: Size(size, size),
          painter: _SkylineConstructionPainter(
            markColor: Colors.white,
            accentColor: accentColor,
          ),
        ),
      ),
    );
  }
}

/// Clean, neat vector CustomPainter for 3 ascending architectural construction columns
/// with solid foundation base beam and emerald apex roof crown.
class _SkylineConstructionPainter extends CustomPainter {
  final Color markColor;
  final Color accentColor;

  const _SkylineConstructionPainter({
    required this.markColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Paints
    final mainPaint = Paint()
      ..color = markColor
      ..style = PaintingStyle.fill;

    final sidePaint = Paint()
      ..color = markColor.withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    // Column metrics
    const double gap = 0.04;
    const double colW = 0.18;

    // 1. Left Column (Foundation tower 1)
    final double lx = w * 0.20;
    final double lTop = h * 0.46;
    final double lBot = h * 0.80;
    final leftCol = RRect.fromRectAndRadius(
      Rect.fromLTRB(lx, lTop, lx + w * colW, lBot),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(leftCol, sidePaint);

    // 2. Center Column (Tallest main structure)
    final double cx = lx + w * colW + w * gap;
    final double cTop = h * 0.24;
    final double cBot = h * 0.80;
    final centerCol = RRect.fromRectAndRadius(
      Rect.fromLTRB(cx, cTop, cx + w * colW, cBot),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(centerCol, mainPaint);

    // 3. Right Column (Tower 2)
    final double rx = cx + w * colW + w * gap;
    final double rTop = h * 0.36;
    final double rBot = h * 0.80;
    final rightCol = RRect.fromRectAndRadius(
      Rect.fromLTRB(rx, rTop, rx + w * colW, rBot),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(rightCol, sidePaint);

    // 4. Emerald Safety Apex / Chevron Crown atop center tower
    final double chevCenterX = cx + (w * colW) / 2;
    final double chevTop = cTop - h * 0.07;
    final double chevBase = cTop + h * 0.01;
    final double chevHalfW = w * colW * 0.65;

    final chevron = Path()
      ..moveTo(chevCenterX, chevTop)
      ..lineTo(chevCenterX + chevHalfW, chevBase)
      ..lineTo(chevCenterX - chevHalfW, chevBase)
      ..close();
    canvas.drawPath(chevron, accentPaint);

    // 5. Clean Architectural Window Accents
    final windowPaint = Paint()
      ..color = markColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    final double winW = w * 0.08;
    final double winH = h * 0.035;
    final double winR = w * 0.01;

    // Center column windows (3 levels)
    final double winXc = cx + (w * colW - winW) / 2;
    for (double wy in [cTop + h * 0.10, cTop + h * 0.20, cTop + h * 0.30, cTop + h * 0.40]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(winXc, wy, winW, winH),
          Radius.circular(winR),
        ),
        windowPaint,
      );
    }

    // Left column windows (2 levels)
    final double winXl = lx + (w * colW - winW) / 2;
    for (double wy in [lTop + h * 0.08, lTop + h * 0.18]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(winXl, wy, winW, winH),
          Radius.circular(winR),
        ),
        windowPaint,
      );
    }

    // Right column windows (2 levels)
    final double winXr = rx + (w * colW - winW) / 2;
    for (double wy in [rTop + h * 0.08, rTop + h * 0.18]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(winXr, wy, winW, winH),
          Radius.circular(winR),
        ),
        windowPaint,
      );
    }

    // 6. Solid Foundation Ground Beam Line
    final basePaint = Paint()
      ..color = markColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.15, h * 0.85),
      Offset(w * 0.85, h * 0.85),
      basePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SkylineConstructionPainter oldDelegate) {
    return oldDelegate.markColor != markColor || oldDelegate.accentColor != accentColor;
  }
}
