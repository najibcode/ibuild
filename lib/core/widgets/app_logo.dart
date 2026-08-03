import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Professional, modern logo for IBUILD ERP.
/// Renders crisp geometric architecture emblem with core brand styling.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final String? subtitle;
  final Color? color;

  const AppLogo({
    super.key,
    this.size = 36,
    this.showText = true,
    this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final primaryCol = color ?? AppColors.primaryColor(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Custom Architectural Building Logo Icon
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryCol,
                primaryCol.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.22),
            boxShadow: [
              BoxShadow(
                color: primaryCol.withValues(alpha: 0.28),
                blurRadius: size * 0.3,
                offset: Offset(0, size * 0.12),
              ),
            ],
          ),
          child: CustomPaint(
            size: Size(size, size),
            painter: _ArchitecturalLogoPainter(accentColor: Colors.white),
          ),
        ),

        if (showText) ...[
          SizedBox(width: size * 0.32),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IBUILD',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: size * 0.55,
                  fontWeight: FontWeight.w900,
                  color: primaryCol,
                  letterSpacing: 0.8,
                  height: 1.0,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: size * 0.28,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedText(context),
                    letterSpacing: 0.3,
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

/// CustomPainter for crisp, standing architectural skyscraper emblem
class _ArchitecturalLogoPainter extends CustomPainter {
  final Color accentColor;

  _ArchitecturalLogoPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paintMain = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final paintMid = Paint()
      ..color = accentColor.withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;

    final paintSide = Paint()
      ..color = accentColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    // Standing Skyscraper Tower 1 (Left Wing)
    final towerLeft = Path()
      ..moveTo(w * 0.18, h * 0.82)
      ..lineTo(w * 0.18, h * 0.42)
      ..lineTo(w * 0.38, h * 0.28)
      ..lineTo(w * 0.38, h * 0.82)
      ..close();
    canvas.drawPath(towerLeft, paintSide);

    // Standing Center Tower (Main High-rise Skyscraper)
    final towerCenter = Path()
      ..moveTo(w * 0.40, h * 0.82)
      ..lineTo(w * 0.40, h * 0.16)
      ..lineTo(w * 0.62, h * 0.16)
      ..lineTo(w * 0.62, h * 0.82)
      ..close();
    canvas.drawPath(towerCenter, paintMain);

    // Standing Skyscraper Tower 3 (Right Wing)
    final towerRight = Path()
      ..moveTo(w * 0.64, h * 0.82)
      ..lineTo(w * 0.64, h * 0.34)
      ..lineTo(w * 0.82, h * 0.44)
      ..lineTo(w * 0.82, h * 0.82)
      ..close();
    canvas.drawPath(towerRight, paintMid);

    // Architectural Window Accents on Center Tower
    final windowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.46, h * 0.24, w * 0.10, h * 0.08), Radius.circular(w * 0.02)), windowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.46, h * 0.38, w * 0.10, h * 0.08), Radius.circular(w * 0.02)), windowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.46, h * 0.52, w * 0.10, h * 0.08), Radius.circular(w * 0.02)), windowPaint);

    // Heavy Structural Base Foundation Line
    final baseLine = Path()
      ..moveTo(w * 0.12, h * 0.86)
      ..lineTo(w * 0.88, h * 0.86);
    canvas.drawPath(
      baseLine,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.08
        ..strokeCap = StrokeCap.round,
    );

    // Crown Spire Accent on Center Tower Top
    final spire = Path()
      ..moveTo(w * 0.51, h * 0.16)
      ..lineTo(w * 0.51, h * 0.08);
    canvas.drawPath(
      spire,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ArchitecturalLogoPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}
