import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/bounty.dart';
import '../models/household.dart';
import '../models/leaderboard_entry.dart';
import '../widgets/dashboard/dashboard_chore_list.dart';
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
    this.onMenuTap,
    this.notificationCount,
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
  final VoidCallback? onMenuTap;
  final int? notificationCount;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  String _selectedFilter = 'All';

  int get _userPoints {
    final entry = widget.leaderboard.where((e) => e.userId == widget.user.id).firstOrNull;
    if (entry != null) {
      return entry.totalTokens;
    }
    // Calculate tokens from completed bounties by this user
    return widget.bounties
        .where((b) => b.isCompleted && b.assigneeId == widget.user.id.toString())
        .fold<int>(0, (sum, b) => sum + (b.points > 0 ? b.points : (b.rewardValue?.toInt() ?? 0)));
  }

  int get _notificationCount {
    if (widget.notificationCount != null) {
      return widget.notificationCount!;
    }
    final uid = widget.user.id.toString();
    return widget.bounties.where((b) => b.creatorId == uid && b.isSubmitted).length;
  }

  int get _tasksOngoing {
    final uid = widget.user.id.toString();
    final userOngoing = widget.bounties.where((b) {
      return b.assigneeId == uid && (b.isClaimed || b.isSubmitted);
    }).length;

    if (userOngoing > 0) return userOngoing;

    // Household ongoing tasks count
    return widget.bounties.where((b) => b.isClaimed || b.isSubmitted).length;
  }

  List<Bounty> get _availableChores =>
      widget.bounties.where((b) => b.isAvailable).toList();

  List<Bounty> get _myChores {
    final uid = widget.user.id.toString();
    return widget.bounties.where((b) {
      return b.assigneeId == uid && (b.isClaimed || b.isSubmitted);
    }).toList();
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
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
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
          const SizedBox(height: 16),

          // 2. Summary Banner Card (N Points, N Tasks Ongoing, Household Switcher)
          DashboardSummaryCard(
            points: _userPoints,
            tasksOngoing: _tasksOngoing,
            householdName: widget.currentHousehold?.name,
            onTap: widget.onViewMyTasks,
            onHouseholdTap: widget.onHouseholdSwitch ?? widget.onNotificationTap,
          ),
          const SizedBox(height: 16),

          // 3. Filter Pills (All, Available, My Chores)
          DashboardFilterPills(
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) {
              setState(() => _selectedFilter = filter);
            },
          ),
          const SizedBox(height: 20),

          // 4. Content / Loading / Error
          if (widget.isLoading && widget.bounties.isEmpty)
            _buildLoadingShimmer()
          else if (widget.errorMessage != null && widget.bounties.isEmpty)
            _buildErrorState(widget.errorMessage!)
          else ...[
            // Available Chores Section
            if (showAvailable) ...[
              _buildChoreSection(
                title: 'Available Chores',
                bounties: _availableChores,
                emptyTitle: 'No available chores',
                emptySubtitle: 'All household tasks are completed or claimed!',
                emptyIcon: Icons.check_circle_outline_rounded,
                showPostButton: true,
              ),
            ],

            // Spacing between sections when both are visible
            if (showAvailable && showMyChores) const SizedBox(height: 22),

            // My Chores Section
            if (showMyChores) ...[
              _buildChoreSection(
                title: 'My Chores',
                bounties: _myChores,
                emptyTitle: 'No ongoing chores',
                emptySubtitle: 'Claim an available chore above to earn points!',
                emptyIcon: Icons.assignment_outlined,
                showPostButton: false,
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
    bool showPostButton = false,
  }) {
    const primaryGreen = Color(0xFF1B8354);

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
              if (showPostButton && bounties.isNotEmpty)
                Material(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: widget.onCreateBounty,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 15, color: primaryGreen),
                          SizedBox(width: 3),
                          Text(
                            'Post',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: primaryGreen,
                            ),
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
          bounties: bounties,
          currentUserId: widget.user.id.toString(),
          currentUserName: widget.user.name,
          onSelectBounty: widget.onSelectBounty,
          emptyIcon: emptyIcon,
          emptyTitle: emptyTitle,
          emptySubtitle: emptySubtitle,
          showPostButton: showPostButton,
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
}

