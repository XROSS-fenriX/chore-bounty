import 'package:flutter/material.dart';

import '../../models/leaderboard_entry.dart';

class LeaderboardSummaryCard extends StatelessWidget {
  const LeaderboardSummaryCard({
    super.key,
    required this.entries,
  });

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final totalTokens = entries.fold<int>(0, (sum, e) => sum + e.totalTokens);
    final totalCompleted = entries.fold<int>(0, (sum, e) => sum + e.completedCount);
    final totalActive = entries.fold<int>(0, (sum, e) => sum + e.activeCount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MetricCell(
              label: 'TOKENS EARNED',
              value: '$totalTokens',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricCell(
              label: 'CHORES DONE',
              value: '$totalCompleted',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricCell(
              label: 'IN PROGRESS',
              value: '$totalActive',
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
