import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/household.dart';
import '../models/leaderboard_entry.dart';
import '../widgets/leaderboard/leaderboard_list_tile.dart';
import '../widgets/leaderboard/leaderboard_podium.dart';
import '../widgets/ui.dart';
import 'user_detail_screen.dart';

class LeaderboardView extends StatelessWidget {
  const LeaderboardView({
    super.key,
    required this.currentUser,
    this.currentHousehold,
    required this.leaderboard,
    required this.isLoading,
    this.errorMessage,
    required this.onRefresh,
    this.onMenuTap,
    this.onUserTap,
  });

  final AppUser currentUser;
  final Household? currentHousehold;
  final List<LeaderboardEntry> leaderboard;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback? onMenuTap;
  final ValueChanged<LeaderboardEntry>? onUserTap;

  void _handleUserTap(BuildContext context, LeaderboardEntry entry) {
    if (onUserTap != null) {
      onUserTap!(entry);
      return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen.fromLeaderboard(
          currentUser: currentUser,
          entry: entry,
          household: currentHousehold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1B8354);
    final podiumEntries = leaderboard.take(3).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: primaryGreen,
      backgroundColor: Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 100),
        children: [
          PageMenuHeader(
            title: 'Leaderboard',
            onMenuTap: onMenuTap,
          ),
          const SizedBox(height: 18),
          if (isLoading && leaderboard.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: CircularProgressIndicator(color: primaryGreen),
              ),
            )
          else if (errorMessage != null && leaderboard.isEmpty)
            _buildErrorState(errorMessage!)
          else if (leaderboard.isEmpty)
            _buildEmptyState()
          else ...[
            LeaderboardPodiumSection(
              entries: podiumEntries,
              currentUserId: currentUser.id,
              onUserTap: (entry) => _handleUserTap(context, entry),
            ),
            const SizedBox(height: 20),
            ...leaderboard.asMap().entries.map((item) {
              final index = item.key;
              final entry = item.value;
              final displayRank = entry.rank > 0 ? entry.rank : index + 1;
              final isMe = entry.userId == currentUser.id;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == leaderboard.length - 1 ? 0 : 10,
                ),
                child: LeaderboardListTile(
                  entry: entry,
                  displayRank: displayRank,
                  isCurrentUser: isMe,
                  onTap: () => _handleUserTap(context, entry),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 38,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 10),
          Text(
            'No rankings yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Complete chores in this household to appear on the leaderboard.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 36,
          ),
          const SizedBox(height: 10),
          const Text(
            'Unable to load leaderboard',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1B8354),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
