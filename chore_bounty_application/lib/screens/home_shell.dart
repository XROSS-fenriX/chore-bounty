import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/rpg_theme.dart';
import '../models/app_user.dart';
import '../models/bounty.dart';
import '../models/household.dart';
import '../models/leaderboard_entry.dart';
import '../services/auth_service.dart';
import '../services/bounty_service.dart';
import '../services/household_service.dart';
import 'household_prompt_screen.dart';
import 'login_screen.dart';
import 'create_bounty_screen.dart';
export 'create_bounty_screen.dart';
import 'dashboard_view.dart';
export 'dashboard_view.dart';
import '../widgets/avatar/user_avatar_widget.dart';
import '../widgets/avatar/avatar_picker_modal.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.user,
    required this.auth,
    required this.bounties,
    required this.households,
  });

  final AppUser user;
  final AuthService auth;
  final BountyService bounties;
  final HouseholdService households;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  late AppUser currentUser;
  late Future<List<Bounty>> future;
  late Future<List<LeaderboardEntry>> leaderboardFuture;
  String filter = 'All';

  List<Household> myHouseholds = [];
  Household? currentHousehold;
  bool isHouseholdsLoading = false;

  static const Color primaryGreen = Color(0xFF1B8354);
  static const Color bgLight = Color(0xFFFAF8F5);

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    future = widget.bounties.all();
    leaderboardFuture = widget.bounties.getLeaderboard();
    _initHouseholds();
  }

  Future<void> changeAvatar() async {
    await AvatarPickerModal.show(
      context: context,
      currentAvatarId: currentUser.avatar,
      onSave: (newAvatarId) async {
        final previousAvatar = currentUser.avatar;
        // Optimistic update across all active UI components
        setState(() {
          currentUser = currentUser.copyWith(avatar: newAvatarId);
        });

        try {
          final updatedUser = await widget.auth.updateAvatar(newAvatarId);
          if (mounted) {
            setState(() {
              currentUser = updatedUser;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Profile avatar updated successfully!'),
                  ],
                ),
                backgroundColor: const Color(0xFF1B8354),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        } catch (e) {
          // Rollback on failure
          if (mounted) {
            setState(() {
              currentUser = currentUser.copyWith(avatar: previousAvatar);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update avatar: ${widget.auth.error(e)}'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
          rethrow;
        }
      },
    );
  }

  Future<void> _initHouseholds() async {
    setState(() => isHouseholdsLoading = true);
    try {
      final list = await widget.households.all();
      if (!mounted) return;

      setState(() {
        myHouseholds = list;
      });

      if (list.isEmpty) {
        // No households found, prompt user to create or join
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HouseholdPromptScreen(
              auth: widget.auth,
              bounties: widget.bounties,
              households: widget.households,
              user: widget.user,
            ),
          ),
        );
        return;
      }

      final savedId = await widget.auth.storage.readHouseholdId();
      Household? active;

      if (savedId != null) {
        active = list.where((h) => h.id.toString() == savedId).firstOrNull;
      }

      active ??= list.first;

      await widget.auth.storage.saveHouseholdId(active.id.toString());

      if (mounted) {
        setState(() {
          currentHousehold = active;
        });
        await refresh();
      }
    } catch (_) {
      // Handled via state
    } finally {
      if (mounted) setState(() => isHouseholdsLoading = false);
    }
  }

  Future<void> switchHousehold(Household h) async {
    if (currentHousehold?.id == h.id) return;

    await widget.auth.storage.saveHouseholdId(h.id.toString());
    if (!mounted) return;

    setState(() {
      currentHousehold = h;
    });

    await refresh();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${h.name}!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> refresh() async {
    final hId = currentHousehold?.id.toString();
    setState(() {
      future = widget.bounties.all(householdId: hId);
      leaderboardFuture = widget.bounties.getLeaderboard(householdId: hId);
    });

    try {
      await Future.wait([future, leaderboardFuture]);
    } catch (_) {
      // Handled by FutureBuilder
    }
  }

  Future<void> logout() async {
    try {
      await widget.auth.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            auth: widget.auth,
            bounties: widget.bounties,
            households: widget.households,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to log out: $e')));
    }
  }

  Future<void> create() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateBounty(
          service: widget.bounties,
          currentHouseholdId: currentHousehold?.id,
        ),
      ),
    );

    if (created == true && mounted) {
      await refresh();
      setState(() => tab = 0);
    }
  }

  Future<void> openAddHousehold() async {
    final newHousehold = await Navigator.push<Household?>(
      context,
      MaterialPageRoute(
        builder: (context) => HouseholdPromptScreen(
          auth: widget.auth,
          bounties: widget.bounties,
          households: widget.households,
          user: widget.user,
          isOptional: true,
        ),
      ),
    );

    if (newHousehold != null && mounted) {
      await _initHouseholds();
      await switchHousehold(newHousehold);
    }
  }

  void openHouseholdSwitcher() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Households',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Switch active household to see its quest board and leaderboard.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),

                  // List of Households
                  ...myHouseholds.map((h) {
                    final isSelected = currentHousehold?.id == h.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryGreen.withValues(alpha: 0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? primaryGreen
                              : const Color(0xFFE5E7EB),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? primaryGreen
                              : Colors.grey.shade200,
                          foregroundColor:
                              isSelected ? Colors.white : Colors.black87,
                          child: const Icon(Icons.holiday_village_rounded, size: 20),
                        ),
                        title: Row(
                          children: [
                            Text(
                              h.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? primaryGreen
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: h.isOwner
                                    ? Colors.amber.shade100
                                    : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                h.role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: h.isOwner
                                      ? Colors.amber.shade900
                                      : Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${h.membersCount} members • Code: ${h.inviteCode}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: primaryGreen,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          switchHousehold(h);
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 12),

                  // Add or Join Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryGreen, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      openAddHousehold();
                    },
                    icon: const Icon(Icons.add_home_rounded, color: primaryGreen),
                    label: const Text(
                      'Create or Join Another Household',
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> handleLeaveHousehold(Household h) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Leave ${h.name}?'),
        content: const Text(
          'You will forfeit active quests and remove yourself from this household leaderboard. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Leave Household'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await widget.households.leave(h.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Left ${h.name}')),
        );
        await _initHouseholds();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.households.error(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: tab,
          children: [questBoard(), myTasks(), leaderboardView(), profileView()],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: create,
        tooltip: 'Post Bounty',
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 10,
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.check_box_outlined,
                activeIcon: Icons.check_box_rounded,
                label: 'My Tasks',
                index: 1,
              ),
              const SizedBox(width: 48),
              _buildNavItem(
                icon: Icons.military_tech_outlined,
                activeIcon: Icons.military_tech_rounded,
                label: 'Leaderboard',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = tab == index;
    final color = isSelected ? primaryGreen : Colors.grey.shade400;

    return InkWell(
      onTap: () => setState(() => tab = index),
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 0: QUEST BOARD (GAMIFIED ROOMMATE TASK BOARD)
  // -------------------------------------------------------------
  Widget questBoard() {
    return FutureBuilder<List<Bounty>>(
      future: future,
      builder: (context, bountySnapshot) {
        return FutureBuilder<List<LeaderboardEntry>>(
          future: leaderboardFuture,
          builder: (context, lbSnapshot) {
            final bountiesList = bountySnapshot.data ?? [];
            final leaderboardList = lbSnapshot.data ?? [];
            final isLoading = bountySnapshot.connectionState == ConnectionState.waiting;
            final errorMessage = bountySnapshot.hasError ? widget.bounties.error(bountySnapshot.error!) : null;

            return DashboardView(
              user: currentUser,
              currentHousehold: currentHousehold,
              bounties: bountiesList,
              leaderboard: leaderboardList,
              isLoading: isLoading,
              errorMessage: errorMessage,
              onRefresh: refresh,
              onSelectBounty: openDetail,
              onCreateBounty: create,
              onHouseholdSwitch: openHouseholdSwitcher,
              onNotificationTap: openHouseholdSwitcher,
              onProfileTap: () => setState(() => tab = 3),
              onViewMyTasks: () => setState(() => tab = 1),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // QUEST CARD WIDGET
  // -------------------------------------------------------------
  Widget questCard(Bounty bounty) {
    final diffColor = RpgTheme.getDifficultyColor(bounty.difficulty);
    final statusColor = RpgTheme.getStatusColor(bounty.status);
    final statusLabel = RpgTheme.getStatusLabel(bounty.status);

    final isAssignee =
        bounty.assigneeId != null &&
        bounty.assigneeId == widget.user.id.toString();
    final isCreator =
        bounty.creatorId.isNotEmpty &&
        bounty.creatorId == widget.user.id.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: bounty.isOpen
              ? diffColor.withValues(alpha: 0.35)
              : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => openDetail(bounty),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: diffColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: diffColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      bounty.difficulty.toUpperCase(),
                      style: TextStyle(
                        color: diffColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFFD166,
                          ).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.stars_rounded,
                              size: 14,
                              color: Color(0xFFB47D00),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+${bounty.xpReward} XP',
                              style: const TextStyle(
                                color: Color(0xFF8B5E00),
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Text(
                bounty.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              if (bounty.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  bounty.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
              const SizedBox(height: 10),

              if (bounty.reward.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: Row(
                    children: [
                      const Text('🎁', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          bounty.reward,
                          style: const TextStyle(
                            color: Color(0xFF7A5900),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (bounty.rewardValue != null &&
                          bounty.rewardValue! > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '\$${bounty.rewardValue!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF1E8E4E),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    bounty.isClaimed && bounty.assignee != null
                        ? 'Claimed by ${isAssignee ? "You" : bounty.assignee}'
                        : 'Posted by ${isCreator ? "You" : bounty.creator}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  if (bounty.isOpen && !isCreator)
                    ElevatedButton.icon(
                      onPressed: () => handleClaim(bounty),
                      icon: const Icon(Icons.flash_on_rounded, size: 14),
                      label: const Text('Claim'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    )
                  else if (bounty.isClaimed && isAssignee)
                    ElevatedButton.icon(
                      onPressed: () => openDetail(bounty),
                      icon: const Icon(Icons.check_circle_outline, size: 14),
                      label: const Text('Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    )
                  else if (bounty.isSubmitted && isCreator)
                    ElevatedButton.icon(
                      onPressed: () => openDetail(bounty),
                      icon: const Icon(Icons.verified_rounded, size: 14),
                      label: const Text('Verify'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB800),
                        foregroundColor: Colors.black87,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: MY TASKS (ACTIVE ASSIGNED & CREATED BY ME)
  // -------------------------------------------------------------
  Widget myTasks() {
    return RefreshIndicator(
      onRefresh: refresh,
      color: primaryGreen,
      child: FutureBuilder<List<Bounty>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          }

          final all = snapshot.data ?? [];
          final myClaimed = all.where((b) {
            return b.assigneeId != null &&
                b.assigneeId == widget.user.id.toString();
          }).toList();
          final myCreated = all.where((b) {
            return b.creatorId == widget.user.id.toString();
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
            children: [
              Text(
                'My Quests (${currentHousehold?.name ?? "Guild"})',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Bounties you have accepted in this household.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 14),
              if (myClaimed.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 44,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No Active Quests Claimed',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Browse the Quest Board and accept chores to earn rewards!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...myClaimed.map((b) => questCard(b)),
              const SizedBox(height: 24),
              const Text(
                'Bounties Posted By Me',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage chores you posted for roommates.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 14),
              if (myCreated.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('You have not posted any bounties yet.'),
                  ),
                )
              else
                ...myCreated.map((b) => questCard(b)),
            ],
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: ROOMMATE LEADERBOARD (HALL OF FAME)
  // -------------------------------------------------------------
  Widget leaderboardView() {
    return RefreshIndicator(
      onRefresh: refresh,
      color: primaryGreen,
      child: FutureBuilder<List<LeaderboardEntry>>(
        future: leaderboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          }

          final entries = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF0C8), Color(0xFFFFE082)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 54,
                      color: Color(0xFFB47D00),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${currentHousehold?.name ?? "Household"} Standings',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF5D4017),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Compete with your roommates, finish quests & earn rewards.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF7A5900), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (entries.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (entries.length > 1)
                      _buildPodiumItem(
                        entries[1],
                        rank: 2,
                        height: 110,
                        medal: '🥈',
                        color: const Color(0xFFC0C0C0),
                      ),
                    const SizedBox(width: 10),
                    _buildPodiumItem(
                      entries[0],
                      rank: 1,
                      height: 140,
                      medal: '👑',
                      color: const Color(0xFFFFD700),
                    ),
                    const SizedBox(width: 10),
                    if (entries.length > 2)
                      _buildPodiumItem(
                        entries[2],
                        rank: 3,
                        height: 90,
                        medal: '🥉',
                        color: const Color(0xFFCD7F32),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              const Text(
                'Roommate Rankings',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (entries.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('No leaderboard records for this household yet.'),
                  ),
                )
              else
                ...entries.map((entry) => _buildLeaderboardTile(entry)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPodiumItem(
    LeaderboardEntry entry, {
    required int rank,
    required double height,
    required String medal,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(medal, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          CircleAvatar(
            radius: rank == 1 ? 26 : 22,
            backgroundColor: color.withValues(alpha: 0.3),
            child: Text(
              entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: rank == 1 ? 18 : 15,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            entry.name.split(' ').first,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${entry.totalXp} XP',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTile(LeaderboardEntry entry) {
    final isMe = entry.userId == widget.user.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? primaryGreen : const Color(0xFFF0EAE0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            alignment: Alignment.center,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: entry.rank <= 3 ? primaryGreen : Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: primaryGreen.withValues(alpha: 0.15),
            child: Text(
              entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: primaryGreen,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primaryGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${entry.tier} • ${entry.completedCount} quests finished',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.totalXp} XP',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF8B5E00),
                  fontSize: 13,
                ),
              ),
              if (entry.totalRewardValue > 0)
                Text(
                  '\$${entry.totalRewardValue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: primaryGreen,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 3: PROFILE & MULTI-HOUSEHOLD MANAGEMENT
  // -------------------------------------------------------------
  Widget profileView() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const SizedBox(height: 18),
        Center(
          child: Column(
            children: [
              UserAvatarWidget(
                avatarId: currentUser.avatar,
                userName: currentUser.name,
                size: 92,
                showEditBadge: true,
                onTap: changeAvatar,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: changeAvatar,
                icon: const Icon(Icons.palette_outlined, size: 16),
                label: const Text('Change Avatar'),
                style: TextButton.styleFrom(
                  foregroundColor: primaryGreen,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          currentUser.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        Text(
          currentUser.email,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),

        // Households Management Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Households',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextButton.icon(
              onPressed: openAddHousehold,
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text('Add / Join'),
              style: TextButton.styleFrom(foregroundColor: primaryGreen),
            ),
          ],
        ),
        const SizedBox(height: 8),

        ...myHouseholds.map((h) {
          final isCurrent = currentHousehold?.id == h.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrent ? primaryGreen : const Color(0xFFF0EAE0),
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          h.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: h.isOwner
                                ? Colors.amber.shade100
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            h.role.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: h.isOwner
                                  ? Colors.amber.shade900
                                  : Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primaryGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Invite Code: ',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    SelectableText(
                      h.inviteCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                        letterSpacing: 0.8,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      color: primaryGreen,
                      tooltip: 'Copy Invite Code',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: h.inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Invite code "${h.inviteCode}" copied to clipboard!',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${h.membersCount} roommates',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    Row(
                      children: [
                        if (!isCurrent)
                          TextButton(
                            onPressed: () => switchHousehold(h),
                            child: const Text(
                              'Switch to this',
                              style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                            ),
                          ),
                        TextButton(
                          onPressed: () => handleLeaveHousehold(h),
                          child: const Text(
                            'Leave',
                            style: TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: logout,
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          label: const Text('Log out', style: TextStyle(color: Colors.redAccent)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.redAccent),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // ACTION HANDLERS & BOTTOM SHEET
  // -------------------------------------------------------------
  Future<void> handleClaim(Bounty bounty) async {
    try {
      await widget.bounties.claim(bounty.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚔️ Quest accepted! Good luck!')),
      );
      await refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.bounties.error(e))));
    }
  }

  Future<void> openDetail(Bounty bounty) async {
    final proofController = TextEditingController(
      text: bounty.submissionProof ?? '',
    );
    final isAssignee =
        bounty.assigneeId != null &&
        bounty.assigneeId == widget.user.id.toString();
    final isCreator =
        bounty.creatorId.isNotEmpty &&
        bounty.creatorId == widget.user.id.toString();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: RpgTheme.getDifficultyColor(
                              bounty.difficulty,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            bounty.difficulty.toUpperCase(),
                            style: TextStyle(
                              color: RpgTheme.getDifficultyColor(
                                bounty.difficulty,
                              ),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFFD166,
                            ).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+${bounty.xpReward} XP',
                            style: const TextStyle(
                              color: Color(0xFF8B5E00),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      bounty.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      bounty.description.isEmpty
                          ? 'No special instructions.'
                          : bounty.description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Row(
                        children: [
                          const Text('🎁', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quest Reward',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: Color(0xFF7A5900),
                                  ),
                                ),
                                Text(
                                  bounty.reward.isEmpty
                                      ? 'Roommate Gratitude'
                                      : bounty.reward,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (bounty.rewardValue != null &&
                              bounty.rewardValue! > 0)
                            Text(
                              '\$${bounty.rewardValue!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: primaryGreen,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (bounty.isClaimed && isAssignee) ...[
                      const Text(
                        'Submission Note / Proof',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: proofController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText:
                              'e.g. Wiped the counter, took recycling out',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (bounty.submissionProof != null &&
                        bounty.submissionProof!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Proof Submitted:',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              bounty.submissionProof!,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (bounty.isOpen && !isCreator)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          await handleClaim(bounty);
                        },
                        icon: const Icon(Icons.flash_on_rounded),
                        label: const Text(
                          'Accept Quest',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                    if (bounty.isClaimed && isAssignee) ...[
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            final proof = proofController.text.trim();
                            await widget.bounties.submit(
                              bounty.id,
                              proof: proof.isEmpty ? 'Chore finished' : proof,
                            );
                            if (!context.mounted) return;
                            Navigator.pop(sheetContext);
                            await refresh();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Submitted for roommate verification!',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(widget.bounties.error(e))),
                            );
                          }
                        },
                        icon: const Icon(Icons.send_rounded),
                        label: const Text(
                          'Submit for Review',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          try {
                            await widget.bounties.unclaim(bounty.id);
                            if (!context.mounted) return;
                            Navigator.pop(sheetContext);
                            await refresh();
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(widget.bounties.error(e))),
                            );
                          }
                        },
                        child: const Text(
                          'Abandon Quest',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],

                    if (bounty.isSubmitted && isCreator) ...[
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            await widget.bounties.verify(bounty.id);
                            if (!context.mounted) return;
                            Navigator.pop(sheetContext);
                            await refresh();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Quest verified! XP & Reward disbursed.',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(widget.bounties.error(e))),
                            );
                          }
                        },
                        icon: const Icon(Icons.verified_rounded),
                        label: const Text(
                          'Approve & Disburse Reward',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],

                    if (bounty.isOpen && isCreator)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            await widget.bounties.cancel(bounty.id);
                            if (!context.mounted) return;
                            Navigator.pop(sheetContext);
                            await refresh();
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(widget.bounties.error(e))),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        label: const Text(
                          'Cancel This Bounty',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}


