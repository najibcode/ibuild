import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Professional, modern logo for IBUILD ERP.
///
/// Renders a vector-crisp geometric skyline mark with three ascending
/// building columns and an emerald chevron crown, paired with the IBUILD
/// wordmark. Works at any scale from 16px favicon to 512px app icon.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final String? subtitle;
  final Color? color;

  /// When true the mark renders white-on-transparent (for dark/coloured bg).
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Logo Mark ──
        _LogoMark(
          size: size,
          primaryColor: primaryCol,
          accentColor: AppColors.secondary,
          inverted: inverted,
        ),

        if (showText) ...[
          SizedBox(width: size * 0.35),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wordmark (IBU uppercase + ild lowercase)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'IBU',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: size * 0.52,
                        fontWeight: FontWeight.w900,
                        color: inverted ? Colors.white : primaryCol,
                        letterSpacing: 0.5,
                        height: 1.0,
                      ),
                    ),
                    TextSpan(
                      text: 'ild',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: size * 0.52,
                        fontWeight: FontWeight.w700,
                        color: inverted
                            ? Colors.white.withValues(alpha: 0.92)
                            : (isDark
                                ? AppColors.darkTextMain
                                : AppColors.textMain),
                        letterSpacing: 0.5,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.w600,
                    color: inverted
                        ? Colors.white.withValues(alpha: 0.6)
                        : AppColors.mutedText(context),
                    letterSpacing: 2.5,
                    height: 1.0,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// The standalone icon mark — three ascending building columns with
/// an emerald chevron crown. Can be used independently for app icons.
class _LogoMark extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color accentColor;
  final bool inverted;

  const _LogoMark({
    required this.size,
    required this.primaryColor,
    required this.accentColor,
    this.inverted = false,
  });

  @override
  Widget build(BuildContext context) {
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
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.30),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.10),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _SkylineLogoPainter(
          markColor: Colors.white,
          accentColor: accentColor,
        ),
      ),
    );
  }
}

/// Paints the three-column rising skyline with chevron crown.
///
/// Geometry is normalised to a 0–1 coordinate system so
/// the mark scales uniformly to any canvas size.
class _SkylineLogoPainter extends CustomPainter {
  final Color markColor;
  final Color accentColor;

  _SkylineLogoPainter({
    required this.markColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Paints ──
    final mainPaint = Paint()
      ..color = markColor
      ..style = PaintingStyle.fill;

    final midPaint = Paint()
      ..color = markColor.withValues(alpha: 0.82)
      ..style = PaintingStyle.fill;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    // Column metrics (x-positions, heights)
    const double gap = 0.04; // gap between columns
    const double colW = 0.18; // column width

    // ── Left Column (shortest) ──
    final double lx = w * 0.20;
    final double lTop = h * 0.48;
    final double lBot = h * 0.82;
    final leftCol = RRect.fromRectAndRadius(
      Rect.fromLTRB(lx, lTop, lx + w * colW, lBot),
      Radius.circular(w * 0.025),
    );
    canvas.drawRRect(leftCol, midPaint);

    // ── Center Column (tallest) ──
    final double cx = lx + w * colW + w * gap;
    final double cTop = h * 0.22;
    final double cBot = h * 0.82;
    final centerCol = RRect.fromRectAndRadius(
      Rect.fromLTRB(cx, cTop, cx + w * colW, cBot),
      Radius.circular(w * 0.025),
    );
    canvas.drawRRect(centerCol, mainPaint);

    // ── Right Column (medium) ──
    final double rx = cx + w * colW + w * gap;
    final double rTop = h * 0.36;
    final double rBot = h * 0.82;
    final rightCol = RRect.fromRectAndRadius(
      Rect.fromLTRB(rx, rTop, rx + w * colW, rBot),
      Radius.circular(w * 0.025),
    );
    canvas.drawRRect(rightCol, midPaint);

    // ── Emerald Chevron Crown (on center column) ──
    final double chevCenterX = cx + w * colW / 2;
    final double chevTop = cTop - h * 0.06;
    final double chevBase = cTop + h * 0.02;
    final double chevHalfW = w * colW * 0.65;

    final chevron = Path()
      ..moveTo(chevCenterX, chevTop)
      ..lineTo(chevCenterX + chevHalfW, chevBase)
      ..lineTo(chevCenterX - chevHalfW, chevBase)
      ..close();
    canvas.drawPath(chevron, accentPaint);

    // ── Window Accents (subtle) ──
    final windowPaint = Paint()
      ..color = markColor.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;

    // Center column windows
    final double winW = w * 0.08;
    final double winH = h * 0.04;
    final double winR = w * 0.01;
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

    // Left column windows (2)
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

    // Right column windows (2)
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

    // ── Foundation Base Line ──
    final basePaint = Paint()
      ..color = markColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.16, h * 0.86),
      Offset(w * 0.84, h * 0.86),
      basePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SkylineLogoPainter oldDelegate) {
    return oldDelegate.markColor != markColor ||
        oldDelegate.accentColor != accentColor;
  }
}
