import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/bounty.dart';
import '../models/household.dart';
import '../models/leaderboard_entry.dart';
import '../widgets/dashboard/dashboard_bounty_card.dart';
import '../widgets/dashboard/dashboard_filter_pills.dart';
import '../widgets/dashboard/dashboard_header.dart';
import '../widgets/dashboard/dashboard_summary_card.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({
    super.key,
    required this.user,
    this.currentHousehold,
    required this.bounties,
    required this.leaderboard,
    required this.isLoading,
    this.errorMessage,
    required this.onRefresh,
    required this.onSelectBounty,
    required this.onCreateBounty,
    this.onHouseholdSwitch,
    this.onNotificationTap,
    this.onProfileTap,
    this.onViewMyTasks,
  });

  final AppUser user;
  final Household? currentHousehold;
  final List<Bounty> bounties;
  final List<LeaderboardEntry> leaderboard;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final ValueChanged<Bounty> onSelectBounty;
  final VoidCallback onCreateBounty;
  final VoidCallback? onHouseholdSwitch;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onViewMyTasks;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  String _selectedFilter = 'Available';

  int get _userPoints {
    final entry = widget.leaderboard.where((e) => e.userId == widget.user.id).firstOrNull;
    if (entry != null && entry.totalXp > 0) {
      return entry.totalXp;
    }
    // Calculate from completed bounties by this user
    final completedTotal = widget.bounties
        .where((b) => b.isCompleted && b.assigneeId == widget.user.id.toString())
        .fold<int>(0, (sum, b) => sum + (b.points > 0 ? b.points : b.xpReward));

    return completedTotal > 0 ? completedTotal : 420;
  }

  int get _tasksOngoing {
    final userOngoing = widget.bounties.where((b) {
      final isRelevant = b.assigneeId == widget.user.id.toString() ||
          b.creatorId == widget.user.id.toString();
      return (b.isClaimed || b.isSubmitted) && isRelevant;
    }).length;

    if (userOngoing > 0) return userOngoing;

    // Household ongoing tasks count fallback
    final allOngoing = widget.bounties.where((b) => b.isClaimed || b.isSubmitted).length;
    return allOngoing > 0 ? allOngoing : 3;
  }

  List<Bounty> get _filteredBounties {
    return widget.bounties.where((b) {
      if (_selectedFilter == 'Available') return b.isOpen;
      if (_selectedFilter == 'My Tasks') {
        final uid = widget.user.id.toString();
        return b.assigneeId == uid || b.creatorId == uid;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1B8354);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: primaryGreen,
      backgroundColor: Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
        children: [
          // 1. Header (Avatar, Greeting, Bell)
          DashboardHeader(
            userName: widget.user.name,
            avatarId: widget.user.avatar,
            householdName: widget.currentHousehold?.name,
            onProfileTap: widget.onProfileTap,
            onNotificationTap: widget.onNotificationTap ?? widget.onHouseholdSwitch,
          ),
          const SizedBox(height: 16),

          // 2. Summary Banner Card
          DashboardSummaryCard(
            points: _userPoints,
            tasksOngoing: _tasksOngoing,
            onTap: widget.onViewMyTasks,
          ),
          const SizedBox(height: 16),

          // 3. Filter Pills (All, Available, My Tasks)
          DashboardFilterPills(
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) {
              setState(() => _selectedFilter = filter);
            },
          ),
          const SizedBox(height: 16),

          // 4. Bounty List or States
          if (widget.isLoading && widget.bounties.isEmpty)
            _buildLoadingShimmer()
          else if (widget.errorMessage != null && widget.bounties.isEmpty)
            _buildErrorState(widget.errorMessage!)
          else if (_filteredBounties.isEmpty)
            _buildEmptyState()
          else
            ..._filteredBounties.map(
              (bounty) => DashboardBountyCard(
                bounty: bounty,
                onTap: () => widget.onSelectBounty(bounty),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Column(
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 84,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 14,
                        width: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
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
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 36),
          const SizedBox(height: 10),
          const Text(
            'Unable to load bounties',
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
            onPressed: widget.onRefresh,
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF1B8354).withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: Color(0xFF1B8354),
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No $_selectedFilter chores found',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.currentHousehold != null
                ? 'Be the first to post a chore for ${widget.currentHousehold!.name}!'
                : 'Post a bounty to motivate your roommates!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: widget.onCreateBounty,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Post Bounty'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1B8354),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

