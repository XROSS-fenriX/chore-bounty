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
        // 2nd Place (Left, Medium Height)
        Expanded(
          child: second != null
              ? _buildPodiumColumn(
                  entry: second,
                  crownType: CrownColor.silver,
                  bgColor: const Color(0xFFF1F5F9),
                  borderColor: const Color(0xFFE2E8F0),
                  avatarSize: 58.0,
                  crownSize: 26.0,
                  minHeight: 168.0,
                  isCenter: false,
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 10),

        // 1st Place (Center, Tallest)
        Expanded(
          child: _buildPodiumColumn(
            entry: first,
            crownType: CrownColor.gold,
            bgColor: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFDE68A),
            avatarSize: 70.0,
            crownSize: 32.0,
            minHeight: 198.0,
            isCenter: true,
          ),
        ),
        const SizedBox(width: 10),

        // 3rd Place (Right, Shortest)
        Expanded(
          child: third != null
              ? _buildPodiumColumn(
                  entry: third,
                  crownType: CrownColor.bronze,
                  bgColor: const Color(0xFFFFF7ED),
                  borderColor: const Color(0xFFFED7AA),
                  avatarSize: 52.0,
                  crownSize: 24.0,
                  minHeight: 142.0,
                  isCenter: false,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPodiumColumn({
    required LeaderboardEntry entry,
    required CrownColor crownType,
    required Color bgColor,
    required Color borderColor,
    required double avatarSize,
    required double crownSize,
    required double minHeight,
    required bool isCenter,
  }) {
    final isMe = currentUserId != null && entry.userId == currentUserId;
    final effectiveBorder = isMe ? const Color(0xFF1B8354) : borderColor;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => onUserTap?.call(entry),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: EdgeInsets.fromLTRB(8, isCenter ? 14 : 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: effectiveBorder,
              width: isMe ? 1.8 : 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: isMe ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CrownWidget(type: crownType, size: crownSize),
                  const SizedBox(height: 6),
                  UserAvatarWidget(
                    avatarId: entry.avatarUrl,
                    userName: entry.name,
                    size: avatarSize,
                    borderColor: effectiveBorder,
                    borderWidth: isCenter ? 2.5 : 2.0,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.name.split(' ').first,
                    style: TextStyle(
                      fontSize: isCenter ? 15.5 : 13.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BountyCoinWidget(size: isCenter ? 18 : 16),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.totalTokens}',
                        style: TextStyle(
                          fontSize: isCenter ? 15 : 13.5,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
