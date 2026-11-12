import 'package:flutter/material.dart';

/// Renders visually rich icons for categories and coin reward matching the design.
class CategoryIconWidget extends StatelessWidget {
  const CategoryIconWidget({
    super.key,
    required this.category,
    this.size = 38.0,
  });

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (category.toLowerCase()) {
      case 'cleaning':
        return _buildCleaningIcon();
      case 'laundry':
        return _buildLaundryIcon();
      case 'kitchen':
      case 'dishes':
        return _buildKitchenIcon();
      case 'groceries':
      case 'shopping':
        return _buildGroceriesIcon();
      case 'maintenance':
        return _buildMaintenanceIcon();
      case 'trash':
      case 'trash bin':
      case 'waste':
        return _buildTrashIcon();
      case 'other':
      case 'miscellaneous':
      default:
        return _buildOtherIcon();
    }
  }

  Widget _buildCleaningIcon() {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/icons/clean_icon.png',
        cacheWidth: (size * 3).ceil(),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return CustomPaint(
            size: Size(size, size),
            painter: _BroomPainter(),
          );
        },
      ),
    );
  }

  Widget _buildLaundryIcon() {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/icons/laundry_icon.png',
        cacheWidth: (size * 3).ceil(),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return CustomPaint(
            size: Size(size, size),
            painter: _WashingMachinePainter(),
          );
        },
      ),
    );
  }

  Widget _buildKitchenIcon() {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/icons/dishes_icon.png',
        cacheWidth: (size * 3).ceil(),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return CustomPaint(
            size: Size(size, size),
            painter: _CookingPotPainter(),
          );
        },
      ),
    );
  }

  Widget _buildGroceriesIcon() {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/icons/shopping_icon.png',
        cacheWidth: (size * 3).ceil(),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return CustomPaint(
            size: Size(size, size),
            painter: _ShoppingCartPainter(),
          );
        },
      ),
    );
  }

  Widget _buildMaintenanceIcon() {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/icons/maintenance_icon.png',
        cacheWidth: (size * 3).ceil(),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return CustomPaint(
            size: Size(size, size),
            painter: _WrenchPainter(),
          );
        },
      ),
    );
  }

  Widget _buildTrashIcon() {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/icons/trash_bin_icon.png',
        cacheWidth: (size * 3).ceil(),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildOtherIcon() {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/icons/miscellaneous_icon.png',
        cacheWidth: (size * 3).ceil(),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size * 0.75,
            height: size * 0.75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF1F5F9),
              border: Border.all(color: const Color(0xFF94A3B8), width: 1.5),
            ),
            child: const Center(
              child: Icon(
                Icons.more_horiz_rounded,
                color: Color(0xFF475569),
                size: 18,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Gold Coin Widget matching the mockup design
class BountyCoinWidget extends StatelessWidget {
  const BountyCoinWidget({
    super.key,
    this.size = 28.0,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/icons/coin_icon.png',
        cacheWidth: (size * 3).ceil(),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withAlpha(70),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
            ),
            child: const Center(
              child: Text(
                '¢',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  height: 1.1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// CUSTOM PAINTERS FOR EXACT 1:1 VISUAL FIDELITY
// -------------------------------------------------------------

class _BroomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Angled broom handle
    final handlePaint = Paint()
      ..color = const Color(0xFF8D5B2E)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.72, h * 0.12), Offset(w * 0.38, h * 0.58), handlePaint);

    // Green brush bristles
    final brushPath = Path()
      ..moveTo(w * 0.38, h * 0.58)
      ..lineTo(w * 0.48, h * 0.65)
      ..lineTo(w * 0.28, h * 0.92)
      ..lineTo(w * 0.12, h * 0.82)
      ..close();

    final brushPaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.fill;
    canvas.drawPath(brushPath, brushPaint);

    final brushBorderPaint = Paint()
      ..color = const Color(0xFF14532D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(brushPath, brushBorderPaint);

    // Bristle lines
    final linePaint = Paint()
      ..color = const Color(0xFF15803D)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(w * 0.36, h * 0.68), Offset(w * 0.20, h * 0.86), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WashingMachinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.12, w * 0.7, h * 0.76),
      const Radius.circular(6),
    );
    final bodyPaint = Paint()..color = const Color(0xFFF8FAFC);
    final borderPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRRect(bodyRect, bodyPaint);
    canvas.drawRRect(bodyRect, borderPaint);

    // Top control bar
    final barPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(w * 0.15, h * 0.28), Offset(w * 0.85, h * 0.28), barPaint);

    // Dial
    final dialPaint = Paint()..color = const Color(0xFF0284C7);
    canvas.drawCircle(Offset(w * 0.72, h * 0.20), w * 0.05, dialPaint);

    // Drum outer
    final drumCenter = Offset(w * 0.5, h * 0.58);
    final drumRadius = w * 0.22;
    final drumPaint = Paint()
      ..color = const Color(0xFFBAE6FD)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(drumCenter, drumRadius, drumPaint);

    final drumBorder = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(drumCenter, drumRadius, drumBorder);

    // Reflection shine
    final shinePaint = Paint()
      ..color = Colors.white.withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: drumCenter, radius: drumRadius * 0.65),
      3.8,
      1.2,
      false,
      shinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CookingPotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Handles
    final handlePaint = Paint()
      ..color = const Color(0xFF7F1D1D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.12, h * 0.56), width: w * 0.18, height: h * 0.22),
      1.5,
      3.14,
      false,
      handlePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.88, h * 0.56), width: w * 0.18, height: h * 0.22),
      -1.5,
      3.14,
      false,
      handlePaint,
    );

    // Pot Body
    final potRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.2, h * 0.42, w * 0.6, h * 0.46),
      bottomLeft: const Radius.circular(8),
      bottomRight: const Radius.circular(8),
      topLeft: const Radius.circular(3),
      topRight: const Radius.circular(3),
    );
    final potPaint = Paint()..color = const Color(0xFFDC2626);
    final potBorder = Paint()
      ..color = const Color(0xFF7F1D1D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRRect(potRect, potPaint);
    canvas.drawRRect(potRect, potBorder);

    // Lid
    final lidPath = Path()
      ..moveTo(w * 0.16, h * 0.42)
      ..quadraticBezierTo(w * 0.5, h * 0.24, w * 0.84, h * 0.42)
      ..close();
    final lidPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawPath(lidPath, lidPaint);
    canvas.drawPath(lidPath, potBorder);

    // Knob
    final knobPaint = Paint()..color = const Color(0xFF451A03);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.27), width: w * 0.14, height: h * 0.08),
      knobPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShoppingCartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final cartPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cartPath = Path()
      ..moveTo(w * 0.16, h * 0.26)
      ..lineTo(w * 0.28, h * 0.26)
      ..lineTo(w * 0.38, h * 0.64)
      ..lineTo(w * 0.78, h * 0.64)
      ..lineTo(w * 0.86, h * 0.34)
      ..lineTo(w * 0.32, h * 0.34);
    canvas.drawPath(cartPath, cartPaint);

    // Internal wire
    final wirePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(w * 0.35, h * 0.48), Offset(w * 0.82, h * 0.48), wirePaint);
    canvas.drawLine(Offset(w * 0.52, h * 0.34), Offset(w * 0.56, h * 0.64), wirePaint);
    canvas.drawLine(Offset(w * 0.68, h * 0.34), Offset(w * 0.70, h * 0.64), wirePaint);

    // Wheels
    final wheelPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawCircle(Offset(w * 0.42, h * 0.76), w * 0.065, wheelPaint);
    canvas.drawCircle(Offset(w * 0.74, h * 0.76), w * 0.065, wheelPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WrenchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();
    canvas.translate(w * 0.5, h * 0.5);
    canvas.rotate(-0.785); // 45 degrees

    final wrenchPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Handle
    final handleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 0), width: w * 0.14, height: h * 0.7),
      const Radius.circular(4),
    );
    canvas.drawRRect(handleRect, wrenchPaint);
    canvas.drawRRect(handleRect, strokePaint);

    // Wrench Head
    final headCenter = Offset(0, -h * 0.35);
    final headRadius = w * 0.22;
    final headPath = Path()
      ..addOval(Rect.fromCircle(center: headCenter, radius: headRadius))
      ..addRect(Rect.fromCenter(center: Offset(0, -h * 0.42), width: w * 0.18, height: h * 0.2));
    headPath.fillType = PathFillType.evenOdd;

    canvas.drawPath(headPath, wrenchPaint);
    canvas.drawPath(headPath, strokePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

