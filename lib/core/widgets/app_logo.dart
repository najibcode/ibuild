import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Ultra-modern, Godly.design inspired Logo & App Icon for IBUILD ERP.
///
/// Features a futuristic 3D isometric interlocking "iB" architectural prism
/// with glowing emerald crystal columns and frosted titanium bevels, paired
/// with high-contrast luxury enterprise typography.
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
    final primaryCol = color ?? AppColors.primaryColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark || inverted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Godly 3D App Icon Tile ──
        _GodlyAppIconMark(
          size: size,
          primaryColor: primaryCol,
          inverted: inverted,
        ),

        if (showText) ...[
          SizedBox(width: size * 0.32),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wordmark (IBU + ILD with Cobalt-Emerald Brand Styling)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'IBU',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: size * 0.54,
                        fontWeight: FontWeight.w900,
                        color: inverted
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        letterSpacing: -0.5,
                        height: 1.0,
                      ),
                    ),
                    TextSpan(
                      text: 'ILD',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: size * 0.54,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF3B82F6),
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
                  fontSize: (size * 0.20).clamp(8.0, 14.0),
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  letterSpacing: 2.2,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Standalone Godly.design 3D Squircle App Icon Tile.
class _GodlyAppIconMark extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final bool inverted;

  const _GodlyAppIconMark({
    required this.size,
    required this.primaryColor,
    this.inverted = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size * 0.23);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF070B18),
        borderRadius: borderRadius,
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.45),
          width: size > 48 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E40AF).withValues(alpha: 0.35),
            blurRadius: size * 0.35,
            spreadRadius: -2,
            offset: Offset(0, size * 0.12),
          ),
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.2),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Image.asset(
          'assets/logo/ibuild_godly_app_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // High fidelity vector fallback
            return CustomPaint(
              size: Size(size, size),
              painter: _GodlyIsometricPainter(),
            );
          },
        ),
      ),
    );
  }
}

/// Vector-precise fallback painter for the 3D isometric interlocking "iB" mark.
class _GodlyIsometricPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ambient radial glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF3B82F6).withValues(alpha: 0.35),
          const Color(0xFF10B981).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.45, h * 0.45), radius: w * 0.5));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glowPaint);

    final cobaltTop = Paint()..color = const Color(0xFF93C5FD);
    final cobaltSide = Paint()..color = const Color(0xFF3B82F6);
    final cobaltDark = Paint()..color = const Color(0xFF1E40AF);

    final titaniumTop = Paint()..color = const Color(0xFFE2E8F0);
    final titaniumSide = Paint()..color = const Color(0xFF64748B);
    final titaniumDark = Paint()..color = const Color(0xFF334155);
    final emeraldAccent = Paint()..color = const Color(0xFF10B981);

    // 1. Floating 'i' Dot Cube
    _drawIsoCube(canvas, Offset(w * 0.34, h * 0.28), w * 0.12, cobaltTop, cobaltSide, cobaltDark);

    // 2. 'i' Lower Column
    _drawIsoPillar(canvas, Offset(w * 0.34, h * 0.46), w * 0.12, h * 0.26, cobaltTop, cobaltSide, cobaltDark);

    // 3. Central Spire
    _drawIsoPillar(canvas, Offset(w * 0.50, h * 0.18), w * 0.14, h * 0.56, cobaltTop, cobaltSide, cobaltDark);

    // 4. Titanium 'B' Loops
    final pathTop = Path()
      ..moveTo(w * 0.42, h * 0.34)
      ..lineTo(w * 0.55, h * 0.27)
      ..lineTo(w * 0.74, h * 0.39)
      ..lineTo(w * 0.62, h * 0.46)
      ..close();
    canvas.drawPath(pathTop, titaniumTop);

    final pathSide = Path()
      ..moveTo(w * 0.42, h * 0.34)
      ..lineTo(w * 0.62, h * 0.46)
      ..lineTo(w * 0.62, h * 0.56)
      ..lineTo(w * 0.42, h * 0.44)
      ..close();
    canvas.drawPath(pathSide, titaniumSide);

    // Emerald accent loop
    final pathEmerald = Path()
      ..moveTo(w * 0.63, h * 0.47)
      ..lineTo(w * 0.73, h * 0.41)
      ..lineTo(w * 0.73, h * 0.47)
      ..lineTo(w * 0.63, h * 0.53)
      ..close();
    canvas.drawPath(pathEmerald, emeraldAccent);

    final pathLoop2 = Path()
      ..moveTo(w * 0.58, h * 0.50)
      ..lineTo(w * 0.76, h * 0.39)
      ..lineTo(w * 0.76, h * 0.64)
      ..lineTo(w * 0.67, h * 0.70)
      ..lineTo(w * 0.67, h * 0.56)
      ..lineTo(w * 0.58, h * 0.62)
      ..close();
    canvas.drawPath(pathLoop2, titaniumDark);
  }

  void _drawIsoCube(Canvas canvas, Offset top, double s, Paint pTop, Paint pLeft, Paint pRight) {
    final half = s / 2;
    final quarter = s / 4;

    // Top face
    final pathTop = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(top.dx + half, top.dy - quarter)
      ..lineTo(top.dx + s, top.dy)
      ..lineTo(top.dx + half, top.dy + quarter)
      ..close();
    canvas.drawPath(pathTop, pTop);

    // Left face
    final pathLeft = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(top.dx + half, top.dy + quarter)
      ..lineTo(top.dx + half, top.dy + s)
      ..lineTo(top.dx, top.dy + s - quarter)
      ..close();
    canvas.drawPath(pathLeft, pLeft);

    // Right face
    final pathRight = Path()
      ..moveTo(top.dx + half, top.dy + quarter)
      ..lineTo(top.dx + s, top.dy)
      ..lineTo(top.dx + s, top.dy + s - quarter)
      ..lineTo(top.dx + half, top.dy + s)
      ..close();
    canvas.drawPath(pathRight, pRight);
  }

  void _drawIsoPillar(Canvas canvas, Offset top, double s, double height, Paint pTop, Paint pLeft, Paint pRight) {
    final half = s / 2;
    final quarter = s / 4;

    // Top face
    final pathTop = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(top.dx + half, top.dy - quarter)
      ..lineTo(top.dx + s, top.dy)
      ..lineTo(top.dx + half, top.dy + quarter)
      ..close();
    canvas.drawPath(pathTop, pTop);

    // Left face
    final pathLeft = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(top.dx + half, top.dy + quarter)
      ..lineTo(top.dx + half, top.dy + height)
      ..lineTo(top.dx, top.dy + height - quarter)
      ..close();
    canvas.drawPath(pathLeft, pLeft);

    // Right face
    final pathRight = Path()
      ..moveTo(top.dx + half, top.dy + quarter)
      ..lineTo(top.dx + s, top.dy)
      ..lineTo(top.dx + s, top.dy + height - quarter)
      ..lineTo(top.dx + half, top.dy + height)
      ..close();
    canvas.drawPath(pathRight, pRight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
