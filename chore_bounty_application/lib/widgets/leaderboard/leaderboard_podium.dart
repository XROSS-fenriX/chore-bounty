import 'package:flutter/material.dart';

import '../../models/leaderboard_entry.dart';
import '../avatar/user_avatar_widget.dart';
import '../bounty_form/bounty_category_icons.dart';
import '../ui.dart';

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
        Expanded(
          child: second != null
              ? _PodiumColumn(
                  entry: second,
                  avatarSize: 54,
                  minHeight: 162,
                  isCenter: false,
                  isCurrentUser: currentUserId != null && second.userId == currentUserId,
                  onTap: () => onUserTap?.call(second),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PodiumColumn(
            entry: first,
            avatarSize: 66,
            minHeight: 192,
            isCenter: true,
            isCurrentUser: currentUserId != null && first.userId == currentUserId,
            onTap: () => onUserTap?.call(first),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: third != null
              ? _PodiumColumn(
                  entry: third,
                  avatarSize: 48,
                  minHeight: 138,
                  isCenter: false,
                  isCurrentUser: currentUserId != null && third.userId == currentUserId,
                  onTap: () => onUserTap?.call(third),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.entry,
    required this.avatarSize,
    required this.minHeight,
    required this.isCenter,
    required this.isCurrentUser,
    required this.onTap,
  });

  final LeaderboardEntry entry;
  final double avatarSize;
  final double minHeight;
  final bool isCenter;
  final bool isCurrentUser;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rankLabel =
        entry.totalTokens > 0 ? formatOrdinalRank(entry.rank) : '–';
    final firstName = entry.firstName.isNotEmpty
        ? entry.firstName
        : entry.name.split(' ').first;

    final cardBg = isCurrentUser ? const Color(0xFFF0FDF4) : Colors.white;
    final borderColor = isCurrentUser
        ? const Color(0xFF1B8354)
        : (isCenter ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0));
    final pillBg = isCurrentUser
        ? const Color(0xFFDCFCE7)
        : (isCenter ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9));
    final pillText = isCurrentUser
        ? const Color(0xFF166534)
        : (isCenter ? Colors.white : const Color(0xFF475569));

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: EdgeInsets.fromLTRB(8, isCenter ? 14 : 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: isCurrentUser ? 1.5 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 6,
                offset: Offset(0, 2),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: pillBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      rankLabel,
                      style: TextStyle(
                        fontSize: isCenter ? 11.5 : 11,
                        fontWeight: FontWeight.w700,
                        color: pillText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  UserAvatarWidget(
                    avatarId: entry.avatarUrl,
                    userName: entry.name,
                    size: avatarSize,
                    borderColor: borderColor,
                    borderWidth: isCenter ? 2.2 : 1.6,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    firstName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCenter ? 15 : 13.5,
                      fontWeight: isCenter ? FontWeight.w800 : FontWeight.w700,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BountyCoinWidget(size: isCenter ? 17 : 15),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.totalTokens}',
                        style: TextStyle(
                          fontSize: isCenter ? 14.5 : 13.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
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
