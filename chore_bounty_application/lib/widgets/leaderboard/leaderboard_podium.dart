import 'package:flutter/material.dart';
import '../../models/leaderboard_entry.dart';
import '../avatar/user_avatar_widget.dart';
import '../bounty_form/bounty_category_icons.dart';
import 'leaderboard_decorations.dart';

class LeaderboardPodiumSection extends StatelessWidget {
  const LeaderboardPodiumSection({
    super.key,
    required this.entries,
    this.currentUserId,
    this.onUserTap,
  });

  final List<LeaderboardEntry> entries;
  final int? currentUserId;
  final ValueChanged<LeaderboardEntry>? onUserTap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final first = entries.first;
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place (Silver)
        Expanded(
          child: second != null
              ? _buildPodiumColumn(
                  entry: second,
                  rank: 2,
                  crownType: CrownColor.silver,
                  bgColor: const Color(0xFFF1F5F9),
                  borderColor: const Color(0xFFE2E8F0),
                  avatarSize: 62.0,
                  crownSize: 28.0,
                  isCenter: false,
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),

        // 1st Place (Gold) - Center, Elevated & Taller
        Expanded(
          child: _buildPodiumColumn(
            entry: first,
            rank: 1,
            crownType: CrownColor.gold,
            bgColor: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFDE68A),
            avatarSize: 74.0,
            crownSize: 36.0,
            isCenter: true,
          ),
        ),
        const SizedBox(width: 8),

        // 3rd Place (Bronze)
        Expanded(
          child: third != null
              ? _buildPodiumColumn(
                  entry: third,
                  rank: 3,
                  crownType: CrownColor.bronze,
                  bgColor: const Color(0xFFFFF7ED),
                  borderColor: const Color(0xFFFED7AA),
                  avatarSize: 62.0,
                  crownSize: 28.0,
                  isCenter: false,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPodiumColumn({
    required LeaderboardEntry entry,
    required int rank,
    required CrownColor crownType,
    required Color bgColor,
    required Color borderColor,
    required double avatarSize,
    required double crownSize,
    required bool isCenter,
  }) {
    final score = entry.totalTokens;

    return InkWell(
      onTap: () => onUserTap?.call(entry),
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.fromLTRB(8, isCenter ? 12 : 16, 8, 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withAlpha(isCenter ? 80 : 40),
              blurRadius: isCenter ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Crown
            CrownWidget(type: crownType, size: crownSize),
            const SizedBox(height: 2),

            // Avatar with Medal Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatarWidget(
                  avatarId: entry.avatarUrl,
                  userName: entry.name,
                  size: avatarSize,
                  borderColor: borderColor,
                  borderWidth: isCenter ? 2.5 : 2.0,
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: RankMedalBadgeWidget(
                    rank: rank,
                    size: isCenter ? 24.0 : 20.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // User Name
            Text(
              entry.name.split(' ').first,
              style: TextStyle(
                fontSize: isCenter ? 16 : 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Score with Coin Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BountyCoinWidget(size: isCenter ? 20 : 18),
                const SizedBox(width: 4),
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: isCenter ? 16 : 14,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E293B),
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

