import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants.dart';

/// Reusable app logo widget.
/// [size] controls the bounding box (width = height).
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: LogoPainter()),
    );
  }
}

class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Background ──────────────────────────────────────────────────────────
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1A1230), Color(0xFF241C3E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final bgRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.22),
    );
    canvas.drawRRect(bgRRect, bgPaint);

    // Radial inner glow (top-center)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.5),
        radius: 0.75,
        colors: [
          AppColors.accent.withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(bgRRect, glowPaint);

    final cx = w / 2;

    // ── Open book (bottom 55% of icon) ──────────────────────────────────────
    final bookTop    = h * 0.48;
    final bookBottom = h * 0.85;
    final bookLeft   = w * 0.10;
    final bookRight  = w * 0.90;
    final spineW     = w * 0.04;

    // Left page – trapezoid that curves inward at top
    final leftPage = Path();
    leftPage.moveTo(bookLeft, bookBottom);
    leftPage.lineTo(bookLeft, bookTop + h * 0.06);
    leftPage.quadraticBezierTo(
      bookLeft + (cx - spineW - bookLeft) * 0.5, bookTop - h * 0.03,
      cx - spineW, bookTop,
    );
    leftPage.lineTo(cx - spineW, bookBottom);
    leftPage.close();

    // Right page – mirror
    final rightPage = Path();
    rightPage.moveTo(bookRight, bookBottom);
    rightPage.lineTo(bookRight, bookTop + h * 0.06);
    rightPage.quadraticBezierTo(
      bookRight - (bookRight - cx - spineW) * 0.5, bookTop - h * 0.03,
      cx + spineW, bookTop,
    );
    rightPage.lineTo(cx + spineW, bookBottom);
    rightPage.close();

    // Page fills
    final pageGradL = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF2E2450), const Color(0xFF241C3E)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(bookLeft, bookTop, cx - bookLeft, bookBottom - bookTop));
    final pageGradR = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF241C3E), const Color(0xFF2E2450)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(cx, bookTop, bookRight - cx, bookBottom - bookTop));

    canvas.drawPath(leftPage,  pageGradL);
    canvas.drawPath(rightPage, pageGradR);

    // Page outlines
    final outlinePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(leftPage,  outlinePaint);
    canvas.drawPath(rightPage, outlinePaint);

    // Spine line
    canvas.drawLine(
      Offset(cx, bookTop),
      Offset(cx, bookBottom),
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = w * 0.032
        ..strokeCap = StrokeCap.round,
    );

    // Bottom page-edge shadow line
    canvas.drawLine(
      Offset(bookLeft + w * 0.03, bookBottom),
      Offset(bookRight - w * 0.03, bookBottom),
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.35)
        ..strokeWidth = w * 0.022
        ..strokeCap = StrokeCap.round,
    );

    // ── Wifi arcs above spine (3 arcs = "smart") ────────────────────────────
    final arcCX  = cx;
    final arcCY  = bookTop - h * 0.01; // arc origin = top of spine
    final arcColors = [
      AppColors.accent.withValues(alpha: 0.45),
      AppColors.accent.withValues(alpha: 0.72),
      AppColors.accent,
    ];
    final arcRadii = [w * 0.13, w * 0.21, w * 0.30];
    final arcStroke = w * 0.032;

    for (int i = 0; i < 3; i++) {
      final r  = arcRadii[i];
      final rect = Rect.fromCircle(center: Offset(arcCX, arcCY), radius: r);
      canvas.drawArc(
        rect,
        -math.pi * 1.05,   // start: slightly past 9 o'clock going upward
        math.pi * 1.10,    // sweep: just over 180° (top half)
        false,
        Paint()
          ..color = arcColors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = arcStroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Center dot (wifi dot)
    canvas.drawCircle(
      Offset(arcCX, arcCY),
      w * 0.038,
      Paint()..color = AppColors.accent,
    );
  }

  @override
  bool shouldRepaint(LogoPainter old) => false;
}
