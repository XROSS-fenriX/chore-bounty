import 'package:flutter/material.dart';

import '../../models/leaderboard_entry.dart';
import '../avatar/user_avatar_widget.dart';
import '../bounty_form/bounty_category_icons.dart';

class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.entry,
    required this.totalHouseholdTokens,
    required this.isCurrentUser,
    required this.onTap,
  });

  final LeaderboardEntry entry;
  final int totalHouseholdTokens;
  final bool isCurrentUser;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rankLabel = entry.totalTokens > 0 ? '${entry.rank}' : '–';
    final ratio = totalHouseholdTokens > 0
        ? (entry.totalTokens / totalHouseholdTokens).clamp(0.0, 1.0)
        : 0.0;
    final pct = totalHouseholdTokens > 0
        ? ((entry.totalTokens / totalHouseholdTokens) * 100).round()
        : 0;
    final choreLabel =
        '${entry.completedCount} ${entry.completedCount == 1 ? 'chore' : 'chores'}';

    return Material(
      color: isCurrentUser ? const Color(0xFFF0FDF4) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  rankLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: entry.totalTokens > 0
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              UserAvatarWidget(
                avatarId: entry.avatarUrl,
                userName: entry.name,
                size: 38,
                borderColor: isCurrentUser
                    ? const Color(0xFF1B8354)
                    : const Color(0xFFE2E8F0),
                borderWidth: 1.5,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  entry.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              if (isCurrentUser) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'You',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const BountyCoinWidget(size: 16),
                            const SizedBox(width: 5),
                            Text(
                              '${entry.totalTokens}',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$choreLabel · $pct%',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFEEF2F6),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1B8354),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
