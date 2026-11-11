import 'package:flutter/material.dart';
import '../../models/leaderboard_entry.dart';
import '../avatar/user_avatar_widget.dart';
import '../bounty_form/bounty_category_icons.dart';

class LeaderboardListTile extends StatelessWidget {
  const LeaderboardListTile({
    super.key,
    required this.entry,
    required this.displayRank,
    this.isCurrentUser = false,
    this.onTap,
  });

  final LeaderboardEntry entry;
  final int displayRank;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final score = entry.totalTokens;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentUser ? const Color(0xFF1B8354).withAlpha(12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Rank Number
            SizedBox(
              width: 28,
              child: Text(
                '$displayRank',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // User Avatar
            UserAvatarWidget(
              avatarId: entry.avatarUrl,
              userName: entry.name,
              size: 42,
            ),
            const SizedBox(width: 14),

            // User Name & Optional 'You' Badge
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      entry.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCurrentUser) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B8354),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'You',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Score with Coin
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BountyCoinWidget(size: 20),
                const SizedBox(width: 6),
                Text(
                  '$score',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

