import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Smooth wave sparkline painter matching the reference dashboard
class SparklineWavePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool fill;

  SparklineWavePainter({
    required this.color,
    this.strokeWidth = 2.2,
    this.fill = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(0, h * 0.65);
    path.cubicTo(w * 0.15, h * 0.2, w * 0.25, h * 0.85, w * 0.4, h * 0.4);
    path.cubicTo(w * 0.55, h * 0.05, w * 0.65, h * 0.9, w * 0.8, h * 0.35);
    path.cubicTo(w * 0.9, h * 0.1, w * 0.95, h * 0.4, w, h * 0.25);

    if (fill) {
      final fillPath = Path.from(path);
      fillPath.lineTo(w, h);
      fillPath.lineTo(0, h);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, w, h));
      canvas.drawPath(fillPath, fillPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mini bar sparkline painter matching "Spent this month" in reference
class MiniBarSparklinePainter extends CustomPainter {
  final Color color;
  final List<double> values;

  MiniBarSparklinePainter({required this.color, required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final barCount = values.length;
    final barWidth = (size.width / (barCount * 1.8)).clamp(3.0, 7.0);
    final gap = (size.width - (barWidth * barCount)) / (barCount - 1);

    for (int i = 0; i < barCount; i++) {
      final h = size.height * values[i].clamp(0.15, 1.0);
      final x = i * (barWidth + gap);
      final y = size.height - h;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, h),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Circular arc gauge painter matching the 80% gauge in reference
class ArcGaugePainter extends CustomPainter {
  final double value; // 0.0 to 1.0
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  ArcGaugePainter({
    required this.value,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - strokeWidth / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Semicircle from PI to 2*PI
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      trackPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * value.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ArcGaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.progressColor != progressColor;
}

/// Pill Badge (e.g., "+0.814 F1", "On track", "Port 8000")
class PillBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const PillBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
