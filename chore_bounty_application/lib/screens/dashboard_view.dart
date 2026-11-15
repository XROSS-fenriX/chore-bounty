import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/bounty.dart';
import '../models/household.dart';
import '../models/leaderboard_entry.dart';
import '../widgets/dashboard/dashboard_chore_list.dart';
import '../widgets/dashboard/dashboard_filter_pills.dart';
import '../widgets/dashboard/dashboard_header.dart';
import '../widgets/dashboard/dashboard_metrics_strip.dart';
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
    this.myHouseholds = const [],
    this.memberHouseholdIds,
    this.activeMemberIds,
    this.onHouseholdSwitch,
    this.onHouseholdSelected,
    this.onAddHousehold,
    this.onNotificationTap,
    this.onProfileTap,
    this.onViewMyTasks,
    this.onViewChores,
    this.onMenuTap,
    this.notificationCount,
  });

  static const int maxDisplayedChores = 5;

  final AppUser user;
  final Household? currentHousehold;
  final List<Household> myHouseholds;
  final Set<String>? memberHouseholdIds;
  final Set<String>? activeMemberIds;
  final List<Bounty> bounties;
  final List<LeaderboardEntry> leaderboard;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final ValueChanged<Bounty> onSelectBounty;
  final VoidCallback onCreateBounty;
  final VoidCallback? onHouseholdSwitch;
  final ValueChanged<Household>? onHouseholdSelected;
  final VoidCallback? onAddHousehold;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onViewMyTasks;
  final VoidCallback? onViewChores;
  final VoidCallback? onMenuTap;
  final int? notificationCount;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  String _selectedFilter = 'All';

  List<Bounty> get _visibleBounties => widget.bounties
      .where(
        (b) => b.isVisibleForHousehold(
          currentUserId: widget.user.id.toString(),
          memberHouseholdIds: widget.memberHouseholdIds,
          activeMemberIds: widget.activeMemberIds,
          activeHouseholdId: widget.currentHousehold?.id.toString(),
        ),
      )
      .toList();

  LeaderboardEntry? get _myLeaderboardEntry =>
      widget.leaderboard.where((e) => e.userId == widget.user.id).firstOrNull;

  int get _userPoints {
    final entry = _myLeaderboardEntry;
    if (entry != null) {
      return entry.totalTokens;
    }
    return _visibleBounties
        .where((b) => b.isCompleted && b.assigneeId == widget.user.id.toString())
        .fold<int>(
          0,
          (sum, b) => sum + (b.points > 0 ? b.points : (b.rewardValue?.toInt() ?? 0)),
        );
  }

  int? get _userRank {
    final index = widget.leaderboard.indexWhere((e) => e.userId == widget.user.id);
    if (index == -1) return null;
    final entry = widget.leaderboard[index];
    return entry.rank > 0 ? entry.rank : index + 1;
  }

  int get _myCompletedCount {
    final entry = _myLeaderboardEntry;
    if (entry != null && entry.completedCount > 0) {
      return entry.completedCount;
    }
    final uid = widget.user.id.toString();
    return _visibleBounties.where((b) => b.isCompleted && b.assigneeId == uid).length;
  }

  int get _notificationCount {
    if (widget.notificationCount != null) {
      return widget.notificationCount!;
    }
    final uid = widget.user.id.toString();
    return _visibleBounties.where((b) => b.creatorId == uid && b.isSubmitted).length;
  }

  int get _tasksOngoing {
    final uid = widget.user.id.toString();
    return _visibleBounties.where((b) {
      return b.assigneeId == uid && (b.isClaimed || b.isSubmitted);
    }).length;
  }

  bool _isPostedByMe(Bounty b) {
    final uid = widget.user.id.toString();
    if (b.creatorId.isNotEmpty) {
      return b.creatorId == uid;
    }
    return b.creator.trim().toLowerCase() ==
        widget.user.name.trim().toLowerCase();
  }

  List<Bounty> get _readyForApprovalChores =>
      _visibleBounties.where((b) => _isPostedByMe(b) && b.isSubmitted).toList();

  List<Bounty> get _availableChores =>
      _visibleBounties.where((b) => b.isAvailable).toList();

  List<Bounty> get _myChores {
    final uid = widget.user.id.toString();
    return _visibleBounties.where((b) {
      return b.assigneeId == uid && (b.isClaimed || b.isSubmitted);
    }).toList();
  }

  int get _completedChoresCount =>
      _visibleBounties.where((b) => b.isCompleted).length;

  int get _actionableChoresCount =>
      _visibleBounties.where((b) => !b.isCancelled && !b.isExpired).length;

  int get _openTokensPool => _availableChores.fold<int>(
        0,
        (sum, b) => sum + (b.points > 0 ? b.points : (b.rewardValue?.toInt() ?? 0)),
      );

  int get _inProgressCount =>
      _visibleBounties.where((b) => b.isClaimed).length;

  int get _dueSoonCount {
    final cutoff = DateTime.now().add(const Duration(hours: 24));
    return _visibleBounties.where((b) {
      if (!b.isAvailable && !b.isClaimed) return false;
      final due = b.dueAt;
      return due != null && due.isBefore(cutoff);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1B8354);

    final showAvailable = _selectedFilter == 'All' || _selectedFilter == 'Available';
    final showMyChores = _selectedFilter == 'All' || _selectedFilter == 'My Tasks' || _selectedFilter == 'My Chores';

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: primaryGreen,
      backgroundColor: Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          // 1. Header (Avatar, Hello, Name, Apartment Dropdown, Notification Icon)
          DashboardHeader(
            userName: widget.user.name,
            avatarId: widget.user.avatar,
            householdName: widget.currentHousehold?.name,
            notificationCount: _notificationCount,
            onProfileTap: widget.onProfileTap,
            onNotificationTap: widget.onNotificationTap ?? widget.onHouseholdSwitch,
            onHouseholdTap: widget.onHouseholdSwitch ?? widget.onNotificationTap,
            onMenuTap: widget.onMenuTap,
          ),
          const SizedBox(height: 8),

          // 2. Summary Banner Card (N Points, N Tasks Ongoing, Household Switcher)
          DashboardSummaryCard(
            points: _userPoints,
            tasksOngoing: _tasksOngoing,
            householdName: widget.currentHousehold?.name,
            currentHousehold: widget.currentHousehold,
            households: widget.myHouseholds,
            rank: _userRank,
            completedCount: _myCompletedCount,
            memberCount:
                widget.leaderboard.isNotEmpty ? widget.leaderboard.length : null,
            onHouseholdSelected: widget.onHouseholdSelected,
            onAddHousehold: widget.onAddHousehold,
            onTap: widget.onViewMyTasks,
            onHouseholdTap: widget.onHouseholdSwitch ?? widget.onNotificationTap,
          ),
          const SizedBox(height: 8),

          if (!widget.isLoading || _visibleBounties.isNotEmpty) ...[
            DashboardMetricsStrip(
              completedCount: _completedChoresCount,
              totalChoresCount: _actionableChoresCount,
              openCount: _availableChores.length,
              openTokensPool: _openTokensPool,
              myCompletedCount: _myCompletedCount,
              inProgressCount: _inProgressCount,
              reviewQueueCount: _readyForApprovalChores.length,
              dueSoonCount: _dueSoonCount,
              onProgressTap: widget.onViewChores,
              onBoardTap: () {
                setState(() {
                  _selectedFilter =
                      _readyForApprovalChores.isNotEmpty ? 'All' : 'Available';
                });
              },
            ),
            const SizedBox(height: 8),
          ] else
            const SizedBox(height: 4),

          // 3. Filter Pills (All, Available, My Chores)
          DashboardFilterPills(
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) {
              setState(() => _selectedFilter = filter);
            },
          ),
          const SizedBox(height: 10),

          // 4. Content / Loading / Error
          if (widget.isLoading && widget.bounties.isEmpty)
            _buildLoadingShimmer()
          else if (widget.errorMessage != null && widget.bounties.isEmpty)
            _buildErrorState(widget.errorMessage!)
          else ...[
            // Ready for Approval Section (shown when a chore is ready for approval)
            if (_selectedFilter == 'All' && _readyForApprovalChores.isNotEmpty) ...[
              _buildChoreSection(
                title: 'Ready for Approval',
                bounties: _readyForApprovalChores,
                emptyTitle: 'No chores awaiting approval',
                emptySubtitle: 'Submitted chores from roommates will appear here.',
                emptyIcon: Icons.fact_check_outlined,
              ),
              const SizedBox(height: 22),
            ],

            // Available Chores Section
            if (showAvailable) ...[
              _buildChoreSection(
                title: 'Available Chores',
                bounties: _availableChores,
                emptyTitle: 'No available chores',
                emptySubtitle: 'All household tasks are completed or claimed!',
                emptyIcon: Icons.check_circle_outline_rounded,
                showSeeMoreButton: true,
                showEmptyPostButton: true,
              ),
            ],

            // Spacing between sections when both are visible
            if (showAvailable && showMyChores) const SizedBox(height: 14),

            // My Chores Section
            if (showMyChores) ...[
              _buildChoreSection(
                title: 'My Chores',
                bounties: _myChores,
                emptyTitle: 'No ongoing chores',
                emptySubtitle: 'Claim an available chore above to earn points!',
                emptyIcon: Icons.assignment_outlined,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildChoreSection({
    required String title,
    required List<Bounty> bounties,
    required String emptyTitle,
    required String emptySubtitle,
    required IconData emptyIcon,
    bool showSeeMoreButton = false,
    bool showEmptyPostButton = false,
  }) {
    const primaryGreen = Color(0xFF1B8354);
    final visibleBounties = bounties.length > DashboardView.maxDisplayedChores
        ? bounties.take(DashboardView.maxDisplayedChores).toList()
        : bounties;
    final seeMoreAction = widget.onViewChores ?? widget.onViewMyTasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: bounties.isNotEmpty
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${bounties.length}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: bounties.isNotEmpty
                        ? const Color(0xFF15803D)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              const Spacer(),
              if (showSeeMoreButton && bounties.isNotEmpty)
                Material(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: seeMoreAction,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'See more',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: primaryGreen,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 15,
                            color: primaryGreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        DashboardChoreList(
          bounties: visibleBounties,
          currentUserId: widget.user.id.toString(),
          currentUserName: widget.user.name,
          onSelectBounty: widget.onSelectBounty,
          emptyIcon: emptyIcon,
          emptyTitle: emptyTitle,
          emptySubtitle: emptySubtitle,
          showPostButton: showEmptyPostButton,
          onCreateBounty: widget.onCreateBounty,
        ),
      ],
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
            'Unable to load chores',
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
}

