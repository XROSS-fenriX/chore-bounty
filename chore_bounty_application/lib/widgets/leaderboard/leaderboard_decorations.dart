import 'package:flutter/material.dart';

enum CrownColor { gold, silver, bronze }

/// Crown Widget matching the leaderboard podium design
class CrownWidget extends StatelessWidget {
  const CrownWidget({
    super.key,
    required this.type,
    this.size = 32.0,
  });

  final CrownColor type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.25,
      height: size,
      child: CustomPaint(
        painter: _CrownPainter(type),
      ),
    );
  }
}

class _CrownPainter extends CustomPainter {
  _CrownPainter(this.type);
  final CrownColor type;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    Color primaryColor;
    Color secondaryColor;
    Color strokeColor;

    switch (type) {
      case CrownColor.silver:
        primaryColor = const Color(0xFFCBD5E1);
        secondaryColor = const Color(0xFF94A3B8);
        strokeColor = const Color(0xFF475569);
        break;
      case CrownColor.bronze:
        primaryColor = const Color(0xFFFDBA74);
        secondaryColor = const Color(0xFFC2410C);
        strokeColor = const Color(0xFF7C2D12);
        break;
      case CrownColor.gold:
        primaryColor = const Color(0xFFFBBF24);
        secondaryColor = const Color(0xFFD97706);
        strokeColor = const Color(0xFF92400E);
        break;
    }

    // Crown Path (3 spikes with arched base)
    final crownPath = Path()
      ..moveTo(w * 0.15, h * 0.82)
      ..lineTo(w * 0.10, h * 0.28)
      ..lineTo(w * 0.35, h * 0.52)
      ..lineTo(w * 0.50, h * 0.12)
      ..lineTo(w * 0.65, h * 0.52)
      ..lineTo(w * 0.90, h * 0.28)
      ..lineTo(w * 0.85, h * 0.82)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor, secondaryColor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(crownPath, fillPaint);
    canvas.drawPath(crownPath, strokePaint);

    // Jewel in Center Spike
    final jewelPaint = Paint()..color = const Color(0xFFEF4444);
    final jewelBorder = Paint()
      ..color = const Color(0xFF7F1D1D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset(w * 0.50, h * 0.54), w * 0.065, jewelPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.54), w * 0.065, jewelBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
