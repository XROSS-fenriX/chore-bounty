import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/leaderboard_entry.dart';
import '../ui.dart';

class LeaderboardSummaryCard extends StatelessWidget {
  const LeaderboardSummaryCard({
    super.key,
    required this.entries,
    required this.currentUser,
  });

  final List<LeaderboardEntry> entries;
  final AppUser? currentUser;

  String? _standingText() {
    if (currentUser == null) return null;
    LeaderboardEntry? myEntry;
    for (final entry in entries) {
      if (entry.userId == currentUser!.id) {
        myEntry = entry;
        break;
      }
    }
    if (myEntry == null) return null;
    if (myEntry.totalTokens <= 0) {
      return 'Complete a chore to get ranked';
    }

    final sameRankCount = entries
        .where((e) => e.totalTokens > 0 && e.rank == myEntry!.rank)
        .length;

    if (myEntry.rank == 1) {
      if (sameRankCount > 1) {
        return 'Tied for 1st';
      }
      final runnerUp = entries
          .where((e) => e.userId != myEntry!.userId && e.totalTokens > 0)
          .toList();
      if (runnerUp.isEmpty) {
        return 'You are 1st';
      }
      final lead = myEntry.totalTokens - runnerUp.first.totalTokens;
      final unit = lead == 1 ? 'token' : 'tokens';
      return 'You lead by $lead $unit';
    }

    final ahead = entries.where((e) => e.totalTokens > myEntry!.totalTokens);
    final prefix = sameRankCount > 1
        ? 'Tied for ${formatOrdinalRank(myEntry.rank)}'
        : 'You are ${formatOrdinalRank(myEntry.rank)}';
    if (ahead.isEmpty) return prefix;

    final target = ahead.last;
    final gap = target.totalTokens - myEntry.totalTokens;
    final unit = gap == 1 ? 'token' : 'tokens';
    final targetFirstName = target.firstName.isNotEmpty
        ? target.firstName
        : target.name.split(' ').first;
    return '$prefix · $gap $unit behind $targetFirstName';
  }

  @override
  Widget build(BuildContext context) {
    final totalTokens = entries.fold<int>(0, (sum, e) => sum + e.totalTokens);
    final totalCompleted = entries.fold<int>(0, (sum, e) => sum + e.completedCount);
    final totalActive = entries.fold<int>(0, (sum, e) => sum + e.activeCount);
    final standing = _standingText();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          ),
          if (standing != null) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                standing,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ],
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
