import 'package:flutter/material.dart';

/// Renders the potted plant and nightstand illustration for the dashboard summary banner.
class SummaryCardIllustration extends StatelessWidget {
  const SummaryCardIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 90,
      child: CustomPaint(
        painter: _SummaryPlantPainter(),
      ),
    );
  }
}

class _SummaryPlantPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background shrub foliage
    final shrubPaint = Paint()..color = const Color(0xFF6EAA7F).withAlpha(160);
    canvas.drawCircle(Offset(w * 0.38, h * 0.72), 16, shrubPaint);
    canvas.drawCircle(Offset(w * 0.52, h * 0.70), 20, shrubPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.40), 28, shrubPaint);
    canvas.drawCircle(Offset(w * 0.88, h * 0.35), 24, shrubPaint);

    // Bedside Table / Wooden Cabinet
    final cabinetRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.35, h * 0.48, w * 0.34, h * 0.46),
      const Radius.circular(5),
    );
    final cabinetWoodPaint = Paint()..color = const Color(0xFFE2A76F);
    final cabinetBorderPaint = Paint()
      ..color = const Color(0xFF825325)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(cabinetRect, cabinetWoodPaint);
    canvas.drawRRect(cabinetRect, cabinetBorderPaint);

    // Cabinet Drawers
    final linePaint = Paint()
      ..color = const Color(0xFF825325)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(w * 0.35, h * 0.70), Offset(w * 0.69, h * 0.70), linePaint);

    // Drawer Knobs
    final knobPaint = Paint()..color = const Color(0xFF45240E);
    canvas.drawCircle(Offset(w * 0.52, h * 0.59), 2.2, knobPaint);
    canvas.drawCircle(Offset(w * 0.52, h * 0.80), 2.2, knobPaint);

    // Legs of the cabinet
    final legPaint = Paint()
      ..color = const Color(0xFF825325)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.38, h * 0.94), Offset(w * 0.37, h * 1.0), legPaint);
    canvas.drawLine(Offset(w * 0.66, h * 0.94), Offset(w * 0.67, h * 1.0), legPaint);

    // Small Pot on the Cabinet
    final smallPotRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.44, h * 0.37, w * 0.16, h * 0.12),
      bottomLeft: const Radius.circular(3),
      bottomRight: const Radius.circular(3),
      topLeft: const Radius.circular(2),
      topRight: const Radius.circular(2),
    );
    final smallPotPaint = Paint()..color = const Color(0xFFCBD5E1);
    final potStroke = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(smallPotRect, smallPotPaint);
    canvas.drawRRect(smallPotRect, potStroke);

    // Small Plant Leaves (Pink / Succulent)
    final succPaint = Paint()..color = const Color(0xFFF472B6);
    canvas.drawCircle(Offset(w * 0.48, h * 0.33), 4.5, succPaint);
    canvas.drawCircle(Offset(w * 0.54, h * 0.32), 5.5, succPaint);
    canvas.drawCircle(Offset(w * 0.52, h * 0.30), 4.5, succPaint);

    // Big Floor Terracotta Pot
    final bigPotPath = Path()
      ..moveTo(w * 0.72, h * 0.58)
      ..lineTo(w * 0.92, h * 0.58)
      ..lineTo(w * 0.89, h * 0.92)
      ..lineTo(w * 0.75, h * 0.92)
      ..close();
    final terraPaint = Paint()..color = const Color(0xFFD97745);
    final terraBorder = Paint()
      ..color = const Color(0xFF7C2D12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(bigPotPath, terraPaint);
    canvas.drawPath(bigPotPath, terraBorder);

    // Big Pot Rim
    final rimRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.70, h * 0.54, w * 0.24, h * 0.08),
      const Radius.circular(3),
    );
    canvas.drawRRect(rimRect, terraPaint);
    canvas.drawRRect(rimRect, terraBorder);

    // Large Lush Leaves
    final leafPaint = Paint()..color = const Color(0xFF22C55E);
    final leafBorder = Paint()
      ..color = const Color(0xFF14532D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    // Leaf 1 (Left)
    final leaf1 = Path()
      ..moveTo(w * 0.80, h * 0.54)
      ..quadraticBezierTo(w * 0.65, h * 0.35, w * 0.72, h * 0.18)
      ..quadraticBezierTo(w * 0.82, h * 0.32, w * 0.82, h * 0.54);
    canvas.drawPath(leaf1, leafPaint);
    canvas.drawPath(leaf1, leafBorder);

    // Leaf 2 (Center tall)
    final leaf2 = Path()
      ..moveTo(w * 0.82, h * 0.54)
      ..quadraticBezierTo(w * 0.76, h * 0.15, w * 0.84, h * 0.08)
      ..quadraticBezierTo(w * 0.90, h * 0.18, w * 0.84, h * 0.54);
    canvas.drawPath(leaf2, leafPaint);
    canvas.drawPath(leaf2, leafBorder);

    // Leaf 3 (Right)
    final leaf3 = Path()
      ..moveTo(w * 0.83, h * 0.54)
      ..quadraticBezierTo(w * 0.95, h * 0.30, w * 0.92, h * 0.20)
      ..quadraticBezierTo(w * 0.84, h * 0.35, w * 0.83, h * 0.54);
    canvas.drawPath(leaf3, leafPaint);
    canvas.drawPath(leaf3, leafBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Cartoon User Avatar matching the mockup
class CartoonUserAvatar extends StatelessWidget {
  const CartoonUserAvatar({
    super.key,
    this.size = 46.0,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFDE68A),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _CartoonBoyPainter(),
      ),
    );
  }
}

class _CartoonBoyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background circle tint
    final bgPaint = Paint()..color = const Color(0xFFFEF3C7);
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.5, bgPaint);

    // Shirt (yellow/gold with collar)
    final shirtPath = Path()
      ..moveTo(w * 0.15, h)
      ..quadraticBezierTo(w * 0.5, h * 0.72, w * 0.85, h)
      ..close();
    final shirtPaint = Paint()..color = const Color(0xFFFBBF24);
    final strokePaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(shirtPath, shirtPaint);
    canvas.drawPath(shirtPath, strokePaint);

    // Neck
    final neckRect = Rect.fromLTWH(w * 0.42, h * 0.62, w * 0.16, h * 0.18);
    final skinPaint = Paint()..color = const Color(0xFFFBCFE8);
    canvas.drawRect(neckRect, skinPaint);

    // Face / Head
    final headRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.46),
      width: w * 0.50,
      height: h * 0.46,
    );
    canvas.drawOval(headRect, skinPaint);
    canvas.drawOval(headRect, strokePaint);

    // Ears
    canvas.drawCircle(Offset(w * 0.24, h * 0.48), w * 0.07, skinPaint);
    canvas.drawCircle(Offset(w * 0.24, h * 0.48), w * 0.07, strokePaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.48), w * 0.07, skinPaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.48), w * 0.07, strokePaint);

    // Hair (Brown, spiky cartoon boy style)
    final hairPaint = Paint()..color = const Color(0xFF78350F);
    final hairPath = Path()
      ..moveTo(w * 0.24, h * 0.42)
      ..quadraticBezierTo(w * 0.18, h * 0.22, w * 0.35, h * 0.18)
      ..lineTo(w * 0.42, h * 0.12)
      ..lineTo(w * 0.52, h * 0.16)
      ..lineTo(w * 0.64, h * 0.14)
      ..quadraticBezierTo(w * 0.82, h * 0.22, w * 0.76, h * 0.42)
      ..quadraticBezierTo(w * 0.65, h * 0.32, w * 0.50, h * 0.32)
      ..quadraticBezierTo(w * 0.35, h * 0.32, w * 0.24, h * 0.42)
      ..close();
    canvas.drawPath(hairPath, hairPaint);
    canvas.drawPath(hairPath, strokePaint);

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawCircle(Offset(w * 0.41, h * 0.46), w * 0.04, eyePaint);
    canvas.drawCircle(Offset(w * 0.59, h * 0.46), w * 0.04, eyePaint);

    // Smile
    final smilePaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.54), width: w * 0.18, height: h * 0.12),
      0.2,
      2.74,
      false,
      smilePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Vacuum Cleaner Custom Painter for vacuum tasks
class VacuumCleanerWidget extends StatelessWidget {
  const VacuumCleanerWidget({super.key, this.size = 36.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _VacuumCleanerPainter(),
      ),
    );
  }
}

class _VacuumCleanerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Canister Body (Teal)
    final bodyPaint = Paint()..color = const Color(0xFF0D9488);
    final bodyPath = Path()
      ..moveTo(w * 0.12, h * 0.84)
      ..quadraticBezierTo(w * 0.10, h * 0.52, w * 0.38, h * 0.52)
      ..lineTo(w * 0.46, h * 0.84)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(bodyPath, strokePaint);

    // Wheel
    final wheelPaint = Paint()..color = const Color(0xFFE11D48);
    canvas.drawCircle(Offset(w * 0.28, h * 0.80), w * 0.10, wheelPaint);
    canvas.drawCircle(Offset(w * 0.28, h * 0.80), w * 0.10, strokePaint);

    // Hose & Wand (Metallic / Navy)
    final hosePaint = Paint()
      ..color = const Color(0xFF0369A1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    final wandPath = Path()
      ..moveTo(w * 0.38, h * 0.56)
      ..quadraticBezierTo(w * 0.52, h * 0.40, w * 0.56, h * 0.24)
      ..lineTo(w * 0.76, h * 0.74);
    canvas.drawPath(wandPath, hosePaint);
    canvas.drawPath(wandPath, strokePaint);

    // Vacuum Head
    final headRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.65, h * 0.74, w * 0.24, h * 0.10),
      const Radius.circular(3),
    );
    final headPaint = Paint()..color = const Color(0xFFE11D48);
    canvas.drawRRect(headRect, headPaint);
    canvas.drawRRect(headRect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Trash Bin Custom Painter
class TrashBinWidget extends StatelessWidget {
  const TrashBinWidget({super.key, this.size = 36.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/icons/trash_bin_icon.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/trash_bin.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return CustomPaint(
                size: Size(size, size),
                painter: _TrashCanPainter(),
              );
            },
          );
        },
      ),
    );
  }
}

class _TrashCanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final canPaint = Paint()..color = const Color(0xFF14B8A6);
    final strokePaint = Paint()
      ..color = const Color(0xFF0F766E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;

    // Body
    final bodyPath = Path()
      ..moveTo(w * 0.22, h * 0.36)
      ..lineTo(w * 0.78, h * 0.36)
      ..lineTo(w * 0.72, h * 0.88)
      ..lineTo(w * 0.28, h * 0.88)
      ..close();
    canvas.drawPath(bodyPath, canPaint);
    canvas.drawPath(bodyPath, strokePaint);

    // Ribs
    final ribPaint = Paint()
      ..color = const Color(0xFF0F766E)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(w * 0.38, h * 0.42), Offset(w * 0.39, h * 0.82), ribPaint);
    canvas.drawLine(Offset(w * 0.50, h * 0.42), Offset(w * 0.50, h * 0.82), ribPaint);
    canvas.drawLine(Offset(w * 0.62, h * 0.42), Offset(w * 0.61, h * 0.82), ribPaint);

    // Lid
    final lidRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.28, w * 0.68, h * 0.09),
      const Radius.circular(3),
    );
    canvas.drawRRect(lidRect, canPaint);
    canvas.drawRRect(lidRect, strokePaint);

    // Handle
    final handleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.40, h * 0.20, w * 0.20, h * 0.09),
      const Radius.circular(2),
    );
    canvas.drawRRect(handleRect, canPaint);
    canvas.drawRRect(handleRect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

