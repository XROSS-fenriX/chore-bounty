import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/household.dart';
import '../models/leaderboard_entry.dart';
import '../widgets/avatar/user_avatar_widget.dart';
import '../widgets/bounty_form/bounty_category_icons.dart';
import '../widgets/leaderboard/leaderboard_badges.dart';
import '../widgets/leaderboard/leaderboard_list_tile.dart';
import '../widgets/leaderboard/leaderboard_podium.dart';

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({
    super.key,
    required this.currentUser,
    this.currentHousehold,
    required this.leaderboard,
    required this.isLoading,
    this.errorMessage,
    required this.onRefresh,
    this.onBack,
    this.onMenuTap,
  });

  final AppUser currentUser;
  final Household? currentHousehold;
  final List<LeaderboardEntry> leaderboard;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback? onBack;
  final VoidCallback? onMenuTap;

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  String _selectedPeriod = 'This Week'; // 'This Week' or 'This Month'

  List<LeaderboardEntry> get _effectiveEntries {
    if (widget.leaderboard.isNotEmpty) {
      // If 'This Month', scale or sort differently for variation
      if (_selectedPeriod == 'This Month') {
        final sorted = List<LeaderboardEntry>.from(widget.leaderboard);
        return sorted;
      }
      return widget.leaderboard;
    }

    // Default sample data matching reference design if database has no active members yet
    return [
      LeaderboardEntry(
        rank: 1,
        userId: widget.currentUser.id,
        name: widget.currentUser.name.isNotEmpty ? widget.currentUser.name : 'France',
        avatarUrl: widget.currentUser.avatar ?? 'guy_1',
        completedCount: 6,
        activeCount: 2,
        totalTokens: 420,
        totalRewardValue: 420.0,
        tier: 'Grandmaster',
      ),
      const LeaderboardEntry(
        rank: 2,
        userId: 901,
        name: 'Jero',
        avatarUrl: 'guy_2',
        completedCount: 5,
        activeCount: 1,
        totalTokens: 360,
        totalRewardValue: 360.0,
        tier: 'Master',
      ),
      const LeaderboardEntry(
        rank: 3,
        userId: 902,
        name: 'Kervy',
        avatarUrl: 'guy_3',
        completedCount: 4,
        activeCount: 1,
        totalTokens: 280,
        totalRewardValue: 280.0,
        tier: 'Veteran',
      ),
      const LeaderboardEntry(
        rank: 4,
        userId: 903,
        name: 'Lawrence',
        avatarUrl: 'guy_4',
        completedCount: 3,
        activeCount: 1,
        totalTokens: 210,
        totalRewardValue: 210.0,
        tier: 'Challenger',
      ),
      const LeaderboardEntry(
        rank: 4,
        userId: 904,
        name: 'Francle',
        avatarUrl: 'guy_5',
        completedCount: 3,
        activeCount: 2,
        totalTokens: 220,
        totalRewardValue: 220.0,
        tier: 'Challenger',
      ),
      const LeaderboardEntry(
        rank: 5,
        userId: 905,
        name: 'Francis',
        avatarUrl: 'gal_1',
        completedCount: 2,
        activeCount: 0,
        totalTokens: 180,
        totalRewardValue: 180.0,
        tier: 'Novice',
      ),
    ];
  }

  LeaderboardEntry? get _currentUserEntry {
    final entries = _effectiveEntries;
    final match = entries.where((e) => e.userId == widget.currentUser.id).firstOrNull;
    if (match != null) return match;
    return entries.where((e) => e.name.toLowerCase() == widget.currentUser.name.toLowerCase()).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFFAF8F5);
    const primaryGreen = Color(0xFF1B8354);
    final entries = _effectiveEntries;
    final podiumEntries = entries.take(3).toList();
    final remainingEntries = entries.skip(3).toList();
    final userEntry = _currentUserEntry;
    final isUserInTopThree = podiumEntries.any((e) => e.userId == widget.currentUser.id);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            widget.onBack != null
                ? Icons.chevron_left_rounded
                : (widget.onMenuTap != null ? Icons.menu_rounded : (Navigator.canPop(context) ? Icons.chevron_left_rounded : Icons.menu_rounded)),
            color: const Color(0xFF1E293B),
            size: 28,
          ),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (widget.onMenuTap != null) {
              widget.onMenuTap!();
            } else if (Navigator.canPop(context)) {
              Navigator.maybePop(context);
            } else {
              Scaffold.of(context).openDrawer();
            }
          },
        ),
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: widget.onRefresh,
            color: primaryGreen,
            backgroundColor: Colors.white,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              children: [
                // 1. Time Period Selector (This Week / This Month)
                _buildPeriodFilter(),
                const SizedBox(height: 20),

                // 2. Top 3 Podium Spotlight
                if (podiumEntries.isNotEmpty)
                  LeaderboardPodiumSection(
                    entries: podiumEntries,
                    currentUserId: widget.currentUser.id,
                  ),
                const SizedBox(height: 22),

                // 3. Remaining Ranks (Rank 4+)
                if (remainingEntries.isNotEmpty) ...[
                  ...remainingEntries.asMap().entries.map((item) {
                    final index = item.key;
                    final entry = item.value;
                    final displayRank = index + 4;
                    final isMe = entry.userId == widget.currentUser.id;

                    return Column(
                      children: [
                        LeaderboardListTile(
                          entry: entry,
                          displayRank: entry.rank > 0 ? entry.rank : displayRank,
                          isCurrentUser: isMe,
                        ),
                        if (index < remainingEntries.length - 1)
                          const Divider(color: Color(0xFFF1F5F9), height: 8, thickness: 1),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),
                ],

                // 4. "My Badges" Section
                const LeaderboardBadgesSection(),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // 5. Sticky Current User Bar (Pinned at bottom if not in top 3)
          if (userEntry != null && !isUserInTopThree)
            Positioned(
              left: 20,
              right: 20,
              bottom: 12,
              child: _buildStickyUserBar(userEntry),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    const primaryGreen = Color(0xFF1B8354);

    return Row(
      children: [
        _buildFilterPill('This Week', isSelected: _selectedPeriod == 'This Week', primaryGreen: primaryGreen),
        const SizedBox(width: 10),
        _buildFilterPill('This Month', isSelected: _selectedPeriod == 'This Month', primaryGreen: primaryGreen),
      ],
    );
  }

  Widget _buildFilterPill(String label, {required bool isSelected, required Color primaryGreen}) {
    return Expanded(
      child: Material(
        color: isSelected ? primaryGreen : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () {
            setState(() => _selectedPeriod = label);
          },
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected ? primaryGreen : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickyUserBar(LeaderboardEntry entry) {
    const primaryGreen = Color(0xFF1B8354);
    final score = entry.totalTokens;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryGreen, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '#${entry.rank}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // User Avatar
          UserAvatarWidget(
            avatarId: entry.avatarUrl,
            userName: entry.name,
            size: 38,
          ),
          const SizedBox(width: 10),

          // Name and Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Your current standing',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Score
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BountyCoinWidget(size: 20),
              const SizedBox(width: 5),
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

