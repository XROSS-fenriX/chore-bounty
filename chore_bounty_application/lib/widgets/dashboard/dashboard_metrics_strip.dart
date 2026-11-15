import 'package:flutter/material.dart';

class DashboardMetricsStrip extends StatelessWidget {
  const DashboardMetricsStrip({
    super.key,
    required this.completedCount,
    required this.totalChoresCount,
    required this.openCount,
    required this.openTokensPool,
    this.myCompletedCount = 0,
    this.inProgressCount = 0,
    this.reviewQueueCount = 0,
    this.dueSoonCount = 0,
    this.onProgressTap,
    this.onBoardTap,
  });

  final int completedCount;
  final int totalChoresCount;
  final int openCount;
  final int openTokensPool;
  final int myCompletedCount;
  final int inProgressCount;
  final int reviewQueueCount;
  final int dueSoonCount;
  final VoidCallback? onProgressTap;
  final VoidCallback? onBoardTap;

  static const Color _primaryGreen = Color(0xFF1B8354);
  static const Color _trackGreenBg = Color(0xFFE2EDE6);
  static const Color _slateDark = Color(0xFF0F172A);
  static const Color _slateMuted = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _amberText = Color(0xFFB45309);
  static const Color _amberBg = Color(0xFFFEF3C7);

  @override
  Widget build(BuildContext context) {
    final ratio = totalChoresCount > 0
        ? (completedCount / totalChoresCount).clamp(0.0, 1.0)
        : 0.0;
    final completionPct = (ratio * 100).round();

    final hasReview = reviewQueueCount > 0;
    final hasDueSoon = !hasReview && dueSoonCount > 0;
    final rightValue = hasReview
        ? '$reviewQueueCount review'
        : hasDueSoon
            ? '$dueSoonCount due soon'
            : '$myCompletedCount done';
    final rightSub = hasReview
        ? 'awaiting you'
        : hasDueSoon
            ? '$inProgressCount active'
            : 'your completed';

    return Row(
      children: [
        Expanded(
          child: _CompactMetricTile(
            onTap: onProgressTap,
            value: '$completionPct% done',
            subtitle: '$completedCount of $totalChoresCount chores',
            progress: ratio,
            accentColor: _primaryGreen,
            trackColor: _trackGreenBg,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CompactMetricTile(
            onTap: onBoardTap,
            value: '$openTokensPool pts',
            subtitle: '$openCount open · $inProgressCount active',
            accentColor: const Color(0xFF0EA5E9),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CompactMetricTile(
            onTap: hasReview ? onBoardTap : onProgressTap,
            value: rightValue,
            subtitle: rightSub,
            accentColor: hasReview ? _amberText : _primaryGreen,
            highlightBg: hasReview ? _amberBg : null,
          ),
        ),
      ],
    );
  }
}

class _CompactMetricTile extends StatelessWidget {
  const _CompactMetricTile({
    required this.value,
    required this.subtitle,
    required this.accentColor,
    this.progress,
    this.trackColor,
    this.highlightBg,
    this.onTap,
  });

  final String value;
  final String subtitle;
  final Color accentColor;
  final double? progress;
  final Color? trackColor;
  final Color? highlightBg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: highlightBg ?? Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: highlightBg != null
              ? accentColor.withAlpha(60)
              : DashboardMetricsStrip._borderColor,
          width: 1.1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: highlightBg != null
                        ? accentColor
                        : DashboardMetricsStrip._slateDark,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: DashboardMetricsStrip._slateMuted,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (progress != null) ...[
                  const SizedBox(height: 5),
                  Container(
                    height: 3.5,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: trackColor ?? const Color(0xFFE2EDE6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress!,
                      child: Container(
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
