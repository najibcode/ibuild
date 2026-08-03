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

/// CustomPainter for crisp, modern architectural building structure emblem
class _ArchitecturalLogoPainter extends CustomPainter {
  final Color accentColor;

  _ArchitecturalLogoPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Building Pillar 1 (Left tower)
    final path1 = Path()
      ..moveTo(w * 0.25, h * 0.80)
      ..lineTo(w * 0.25, h * 0.40)
      ..lineTo(w * 0.44, h * 0.26)
      ..lineTo(w * 0.44, h * 0.80)
      ..close();
    canvas.drawPath(path1, paint);

    // Building Pillar 2 (Right tower - taller)
    final path2 = Path()
      ..moveTo(w * 0.50, h * 0.80)
      ..lineTo(w * 0.50, h * 0.20)
      ..lineTo(w * 0.75, h * 0.34)
      ..lineTo(w * 0.75, h * 0.80)
      ..close();

    // Slightly dim right pillar for depth
    final dimPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.82)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path2, dimPaint);

    // Foundation Base line
    final baseLine = Path()
      ..moveTo(w * 0.18, h * 0.84)
      ..lineTo(w * 0.82, h * 0.84);
    canvas.drawPath(
      baseLine,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.08
        ..strokeCap = StrokeCap.round,
    );

    // Modern Roof Angle Badge Accent
    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round;

    final roofLine = Path()
      ..moveTo(w * 0.22, h * 0.38)
      ..lineTo(w * 0.48, h * 0.18)
      ..lineTo(w * 0.78, h * 0.32);
    canvas.drawPath(roofLine, accentPaint);
  }

  @override
  bool shouldRepaint(covariant _ArchitecturalLogoPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}
