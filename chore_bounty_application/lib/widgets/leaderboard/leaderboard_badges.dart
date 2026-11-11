import 'package:flutter/material.dart';

class LeaderboardBadgeItem {
  const LeaderboardBadgeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.isUnlocked,
  });

  final String id;
  final String title;
  final String description;
  final bool isUnlocked;
}

class LeaderboardBadgesSection extends StatelessWidget {
  const LeaderboardBadgesSection({
    super.key,
    this.onBadgeTap,
  });

  final ValueChanged<LeaderboardBadgeItem>? onBadgeTap;

  static const List<LeaderboardBadgeItem> defaultBadges = [
    LeaderboardBadgeItem(
      id: 'first_clean',
      title: 'First Clean',
      description: 'Completed your first household cleaning chore',
      isUnlocked: true,
    ),
    LeaderboardBadgeItem(
      id: 'streak_5',
      title: 'Streak 5',
      description: 'Completed chores for 5 days in a row',
      isUnlocked: true,
    ),
    LeaderboardBadgeItem(
      id: 'team_player',
      title: 'Team Player',
      description: 'Coordinated chores with all household roommates',
      isUnlocked: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Badges',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: defaultBadges.map((badge) {
            return InkWell(
              onTap: () => onBadgeTap != null ? onBadgeTap!(badge) : _showBadgeDetail(context, badge),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Column(
                  children: [
                    _buildBadgeVisual(badge.id, 68),
                    const SizedBox(height: 8),
                    Text(
                      badge.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showBadgeDetail(BuildContext context, LeaderboardBadgeItem badge) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBadgeVisual(badge.id, 88),
                const SizedBox(height: 16),
                Text(
                  badge.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  badge.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Badge Unlocked',
                        style: TextStyle(
                          color: Color(0xFF15803D),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgeVisual(String id, double size) {
    switch (id) {
      case 'streak_5':
        return _StreakBadge(size: size);
      case 'team_player':
        return _TeamPlayerBadge(size: size);
      case 'first_clean':
      default:
        return _FirstCleanBadge(size: size);
    }
  }
}

class _FirstCleanBadge extends StatelessWidget {
  const _FirstCleanBadge({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFA7F3D0),
        border: Border.all(color: const Color(0xFF6EE7B7), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _FirstCleanPainter(),
      ),
    );
  }
}

class _FirstCleanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Golden Laurel Leaves along the outer rim
    final laurelPaint = Paint()
      ..color = const Color(0xFFEAB308)
      ..style = PaintingStyle.fill;

    // Draw laurel leaf pairs
    for (int i = 0; i < 5; i++) {
      final y1 = h * (0.24 + i * 0.12);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.20, y1), width: w * 0.12, height: h * 0.08),
        laurelPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.80, y1), width: w * 0.12, height: h * 0.08),
        laurelPaint,
      );
    }

    // Angled Broom Handle
    final handlePaint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.70, h * 0.26), Offset(w * 0.44, h * 0.60), handlePaint);

    // Broom Bristles (Yellow/Gold Brush with black outlines)
    final brushPath = Path()
      ..moveTo(w * 0.44, h * 0.60)
      ..lineTo(w * 0.52, h * 0.66)
      ..lineTo(w * 0.34, h * 0.88)
      ..lineTo(w * 0.22, h * 0.78)
      ..close();

    final brushPaint = Paint()..color = const Color(0xFFFACC15);
    final borderPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawPath(brushPath, brushPaint);
    canvas.drawPath(brushPath, borderPaint);

    // Inner bristle lines
    final linePaint = Paint()
      ..color = const Color(0xFFCA8A04)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(w * 0.42, h * 0.68), Offset(w * 0.30, h * 0.82), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFED7AA),
        border: Border.all(color: const Color(0xFFFDBA74), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _StreakPainter(),
      ),
    );
  }
}

class _StreakPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cyan/Blue Sunburst outer trim
    final trimPaint = Paint()..color = const Color(0xFF38BDF8);
    for (int i = 0; i < 8; i++) {
      final angle = i * 3.14159 / 4;
      final dx = w * 0.5 + (w * 0.44) * (angle == 0 ? 1 : (angle == 3.14159 ? -1 : 0));
      final dy = h * 0.5 + (h * 0.44) * (angle == 1.57 ? 1 : (angle == 4.71 ? -1 : 0));
      canvas.drawCircle(Offset(dx, dy), 3, trimPaint);
    }

    // Fiery Flame (Red outer, Orange inner)
    final flamePath = Path()
      ..moveTo(w * 0.5, h * 0.16)
      ..quadraticBezierTo(w * 0.72, h * 0.34, w * 0.78, h * 0.58)
      ..quadraticBezierTo(w * 0.78, h * 0.84, w * 0.5, h * 0.84)
      ..quadraticBezierTo(w * 0.22, h * 0.84, w * 0.22, h * 0.58)
      ..quadraticBezierTo(w * 0.28, h * 0.34, w * 0.5, h * 0.16)
      ..close();

    final flamePaint = Paint()..color = const Color(0xFFEF4444);
    final flameStroke = Paint()
      ..color = const Color(0xFF991B1B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawPath(flamePath, flamePaint);
    canvas.drawPath(flamePath, flameStroke);

    // Inner orange fire
    final innerFlame = Path()
      ..moveTo(w * 0.5, h * 0.30)
      ..quadraticBezierTo(w * 0.66, h * 0.44, w * 0.70, h * 0.62)
      ..quadraticBezierTo(w * 0.66, h * 0.80, w * 0.5, h * 0.80)
      ..quadraticBezierTo(w * 0.34, h * 0.80, w * 0.30, h * 0.62)
      ..quadraticBezierTo(w * 0.34, h * 0.44, w * 0.5, h * 0.30)
      ..close();

    final innerPaint = Paint()..color = const Color(0xFFF97316);
    canvas.drawPath(innerFlame, innerPaint);

    // Center White Disc with '5'
    final centerDisc = Offset(w * 0.5, h * 0.58);
    final discPaint = Paint()..color = Colors.white;
    final discBorder = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawCircle(centerDisc, w * 0.18, discPaint);
    canvas.drawCircle(centerDisc, w * 0.18, discBorder);

    // Numeral 5
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '5',
        style: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(centerDisc.dx - textPainter.width / 2, centerDisc.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TeamPlayerBadge extends StatelessWidget {
  const _TeamPlayerBadge({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFBAE6FD),
        border: Border.all(color: const Color(0xFF7DD3FC), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _TeamPlayerPainter(),
      ),
    );
  }
}

class _TeamPlayerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final stroke = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    // Left Figure (Cyan/Teal)
    final p1Paint = Paint()..color = const Color(0xFF0284C7);
    canvas.drawCircle(Offset(w * 0.32, h * 0.44), w * 0.08, p1Paint);
    canvas.drawCircle(Offset(w * 0.32, h * 0.44), w * 0.08, stroke);

    final p1Body = Path()
      ..moveTo(w * 0.20, h * 0.82)
      ..quadraticBezierTo(w * 0.32, h * 0.58, w * 0.42, h * 0.82)
      ..close();
    canvas.drawPath(p1Body, p1Paint);
    canvas.drawPath(p1Body, stroke);

    // Right Figure (Orange)
    final p3Paint = Paint()..color = const Color(0xFFEA580C);
    canvas.drawCircle(Offset(w * 0.68, h * 0.44), w * 0.08, p3Paint);
    canvas.drawCircle(Offset(w * 0.68, h * 0.44), w * 0.08, stroke);

    final p3Body = Path()
      ..moveTo(w * 0.58, h * 0.82)
      ..quadraticBezierTo(w * 0.68, h * 0.58, w * 0.80, h * 0.82)
      ..close();
    canvas.drawPath(p3Body, p3Paint);
    canvas.drawPath(p3Body, stroke);

    // Center Figure (Yellow/Gold - Taller leader)
    final p2Paint = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawCircle(Offset(w * 0.50, h * 0.34), w * 0.09, p2Paint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.34), w * 0.09, stroke);

    final p2Body = Path()
      ..moveTo(w * 0.38, h * 0.82)
      ..quadraticBezierTo(w * 0.50, h * 0.48, w * 0.62, h * 0.82)
      ..close();
    canvas.drawPath(p2Body, p2Paint);
    canvas.drawPath(p2Body, stroke);

    // Trophy in middle hands
    final trophyPaint = Paint()..color = const Color(0xFFF59E0B);
    final trophyRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.72),
      width: w * 0.16,
      height: h * 0.14,
    );
    canvas.drawOval(trophyRect, trophyPaint);
    canvas.drawOval(trophyRect, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

