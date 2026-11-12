import 'package:flutter/material.dart';
import '../../models/leaderboard_entry.dart';
import '../avatar/user_avatar_widget.dart';
import '../bounty_form/bounty_category_icons.dart';
import '../ui.dart';

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

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFD97706);
      case 2:
        return const Color(0xFF475569);
      case 3:
        return const Color(0xFFC2410C);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1B8354);
    final displayName = isCurrentUser ? '${entry.name} (You)' : entry.name;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrentUser ? primaryGreen : const Color(0xFFE2E8F0),
              width: isCurrentUser ? 1.6 : 1.2,
            ),
          ),
          child: Row(
            children: [
              UserAvatarWidget(
                avatarId: entry.avatarUrl,
                userName: entry.name,
                size: 44,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BountyCoinWidget(size: 15),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.totalTokens}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatOrdinalRank(displayRank),
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: _rankColor(displayRank),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
