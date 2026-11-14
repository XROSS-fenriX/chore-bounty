import 'dart:async';
import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/bounty.dart';
import '../models/household.dart';
import '../models/household_member.dart';
import '../models/leaderboard_entry.dart';
import '../services/auth_service.dart';
import '../services/bounty_service.dart';
import '../services/household_service.dart';
import 'household_prompt_screen.dart';
import 'household_view.dart';
export 'household_view.dart';
import 'login_screen.dart';
import 'bounty_detail_screen.dart';
export 'bounty_detail_screen.dart';
import 'chores_view.dart';
export 'chores_view.dart';
import 'create_bounty_screen.dart';
export 'create_bounty_screen.dart';
import 'dashboard_view.dart';
export 'dashboard_view.dart';
import 'edit_profile_screen.dart';
export 'edit_profile_screen.dart';
import 'leaderboard_view.dart';
export 'leaderboard_view.dart';
import 'notifications_screen.dart';
export 'notifications_screen.dart';
import 'profile_view.dart';
export 'profile_view.dart';
import 'user_detail_screen.dart';
export 'user_detail_screen.dart';
import '../widgets/avatar/user_avatar_widget.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int tab = 0;
  late AppUser currentUser;
  late Future<List<Bounty>> future;
  late Future<List<LeaderboardEntry>> leaderboardFuture;
  late Future<List<HouseholdMember>> membersFuture;
  String filter = 'All';

  List<Household> myHouseholds = [];
  Household? currentHousehold;
  bool isHouseholdsLoading = false;
  final Map<String, String> _memberAvatars = {};
  List<Bounty> _latestBounties = const [];
  List<LeaderboardEntry> _latestLeaderboard = const [];
  List<HouseholdMember> _latestMembers = const [];
  List<AppNotification> _latestNotifications = const [];
  final Set<String> _seenNotificationIds = {};
  bool _hasCompletedInitialNotificationLoad = false;
  Timer? _realtimeTimer;

  static const Color primaryGreen = Color(0xFF1B8354);
  static const Color bgLight = Color(0xFFFAF8F5);

  bool get _isTestEnvironment =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  int get _unreadNotificationCount {
    final uid = currentUser.id.toString();
    final uname = currentUser.name;
    if (_latestNotifications.isNotEmpty) {
      return _latestNotifications
          .where((n) => !n.isRead && !n.isTriggeredBy(uid, uname))
          .length;
    }
    return _latestBounties
        .where((b) => b.creatorId == uid && b.isSubmitted)
        .length;
  }

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    if (currentUser.avatar != null && currentUser.avatar!.isNotEmpty) {
      _memberAvatars['${currentUser.id}'] = currentUser.avatar!;
    }
    future = widget.bounties.all();
    leaderboardFuture = widget.bounties.getLeaderboard();
    membersFuture = Future.value(const <HouseholdMember>[]);
    _initHouseholds();
    if (!_isTestEnvironment) {
      _realtimeTimer = Timer.periodic(
        const Duration(seconds: 4),
        (_) => _pollRealtimeUpdates(),
      );
    }
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    refresh();
  }

  void _syncMemberAvatars(
    List<Bounty> bounties,
    List<LeaderboardEntry> leaderboard, {
    List<HouseholdMember> members = const [],
  }) {
    _latestBounties = bounties;
    _latestLeaderboard = leaderboard;
    if (members.isNotEmpty) {
      _latestMembers = members;
    }
    if (currentUser.avatar != null && currentUser.avatar!.isNotEmpty) {
      _memberAvatars['${currentUser.id}'] = currentUser.avatar!;
    }
    for (final member in members) {
      if (member.avatar != null && member.avatar!.isNotEmpty) {
        _memberAvatars['${member.userId}'] = member.avatar!;
      }
    }
    for (final entry in leaderboard) {
      if (entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty) {
        _memberAvatars['${entry.userId}'] = entry.avatarUrl!;
      }
    }
    for (final bounty in bounties) {
      if (bounty.creatorId.isNotEmpty &&
          bounty.creatorAvatar != null &&
          bounty.creatorAvatar!.isNotEmpty) {
        _memberAvatars[bounty.creatorId] = bounty.creatorAvatar!;
      }
      if (bounty.assigneeId != null &&
          bounty.assigneeId!.isNotEmpty &&
          bounty.assigneeAvatar != null &&
          bounty.assigneeAvatar!.isNotEmpty) {
        _memberAvatars[bounty.assigneeId!] = bounty.assigneeAvatar!;
      }
    }
  }

  Future<void> openEditProfile() async {
    final updatedUser = await Navigator.push<AppUser?>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          user: currentUser,
          auth: widget.auth,
        ),
      ),
    );

    if (updatedUser != null && mounted) {
      setState(() {
        currentUser = updatedUser;
        if (updatedUser.avatar != null && updatedUser.avatar!.isNotEmpty) {
          _memberAvatars['${updatedUser.id}'] = updatedUser.avatar!;
        }
      });
      await refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Profile updated successfully!'),
            ],
          ),
          backgroundColor: const Color(0xFF1B8354),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
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

  Future<void> _pollRealtimeUpdates() async {
    if (!mounted) return;
    final hId = currentHousehold?.id.toString();
    try {
      final bounties = await widget.bounties.all(householdId: hId);
      final notifications = await widget.bounties.notifications(
        householdId: hId,
        fallbackBounties: bounties,
        currentUserId: currentUser.id.toString(),
        currentUserName: currentUser.name,
      );
      if (!mounted) return;
      _processNotifications(notifications);
      setState(() {
        _latestBounties = bounties;
        future = Future.value(bounties);
      });
    } catch (_) {}
  }

  void _processNotifications(
    List<AppNotification> notifications, {
    bool notifyNew = true,
  }) {
    final uid = currentUser.id.toString();
    final uname = currentUser.name;
    final filtered = notifications
        .where((n) => !n.isTriggeredBy(uid, uname))
        .toList();

    AppNotification? newestUnseen;
    if (_hasCompletedInitialNotificationLoad && notifyNew) {
      for (final n in filtered) {
        if (!_seenNotificationIds.contains(n.id) && !n.isRead) {
          newestUnseen ??= n;
        }
      }
    }
    for (final n in filtered) {
      _seenNotificationIds.add(n.id);
    }
    _hasCompletedInitialNotificationLoad = true;
    _latestNotifications = filtered;

    if (newestUnseen != null && mounted && !_isTestEnvironment) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                newestUnseen.eventName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                newestUnseen.description,
                style: const TextStyle(fontSize: 12.5, color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View',
            textColor: const Color(0xFF86EFAC),
            onPressed: openNotificationsPage,
          ),
        ),
      );
    }
  }

  Future<void> refresh({bool showError = false}) async {
    final hId = currentHousehold?.id.toString();
    final householdIntId = currentHousehold?.id;
    setState(() {
      future = widget.bounties.all(householdId: hId);
      leaderboardFuture = widget.bounties.getLeaderboard(householdId: hId);
      membersFuture = householdIntId != null
          ? widget.households.members(householdIntId)
          : Future.value(const <HouseholdMember>[]);
    });

    try {
      final bounties = await future;
      final lb = await leaderboardFuture;
      final members = await membersFuture;
      final notifications = await widget.bounties.notifications(
        householdId: hId,
        fallbackBounties: bounties,
        currentUserId: currentUser.id.toString(),
        currentUserName: currentUser.name,
      );
      if (mounted) {
        setState(() {
          _syncMemberAvatars(bounties, lb, members: members);
          _processNotifications(notifications);
        });
      }
    } catch (e) {
      if (showError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.bounties.error(e)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

  Future<void> openNotificationsPage() async {
    final uid = currentUser.id.toString();
    final uname = currentUser.name;
    final filteredNotifications = _latestNotifications
        .where((n) => !n.isTriggeredBy(uid, uname))
        .toList();
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(
          user: currentUser,
          bounties: widget.bounties,
          householdId: currentHousehold?.id.toString(),
          initialBounties: _latestBounties,
          initialNotifications: filteredNotifications,
          onSelectBounty: (bounty) async {
            await openDetail(bounty);
            if (mounted) {
              await refresh();
            }
          },
          onRefreshParent: refresh,
        ),
      ),
    );
    if (mounted) {
      await refresh();
    }
  }

  void openNotificationsSheet() => openNotificationsPage();

  Future<void> handleRenameHousehold(Household h, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == h.name) return;
    try {
      final updated = await widget.households.update(h.id, trimmed);
      if (!mounted) return;
      setState(() {
        myHouseholds = myHouseholds
            .map((item) => item.id == h.id ? updated : item)
            .toList();
        if (currentHousehold?.id == h.id) {
          currentHousehold = updated;
        }
      });
      await refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Household renamed to ${updated.name}'),
          backgroundColor: primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.households.error(e))),
      );
    }
  }

  Future<void> handleRemoveMember(
    Household h,
    HouseholdMember member,
  ) async {
    try {
      await widget.households.removeMember(h.id, member.userId);
      if (!mounted) return;
      await refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed ${member.name} from ${h.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.households.error(e))),
      );
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
      key: _scaffoldKey,
      backgroundColor: bgLight,
      drawer: _buildDrawer(),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: tab,
          children: [
            questBoard(),
            choresView(),
            leaderboardView(),
            householdView(),
            profileView(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Navigation Items + Quick Actions
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 6),
                    child: Text(
                      'MENU',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  _buildDrawerNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                  ),
                  _buildDrawerNavItem(
                    icon: Icons.task_alt_outlined,
                    activeIcon: Icons.task_alt_rounded,
                    label: 'Chores',
                    index: 1,
                  ),
                  _buildDrawerNavItem(
                    icon: Icons.emoji_events_outlined,
                    activeIcon: Icons.emoji_events_rounded,
                    label: 'Leaderboard',
                    index: 2,
                  ),
                  _buildDrawerNavItem(
                    icon: Icons.holiday_village_outlined,
                    activeIcon: Icons.holiday_village_rounded,
                    label: 'Household',
                    index: 3,
                  ),
                  _buildDrawerNavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    index: 4,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 46,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        create();
                      },
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        'Post a Chore',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDrawerHouseholdDropdown(),
                ],
              ),
            ),

            // User Profile Section (bottom card)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Material(
                color: const Color(0xFFFAF8F5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => tab = 4);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        UserAvatarWidget(
                          avatarId: currentUser.avatar,
                          userName: currentUser.name,
                          size: 44,
                          onTap: () {
                            Navigator.pop(context);
                            setState(() => tab = 4);
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currentUser.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentUser.email,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHouseholdDropdown() {
    const createOrJoinId = -1;
    final selectedId = (currentHousehold != null &&
            myHouseholds.any((h) => h.id == currentHousehold!.id))
        ? currentHousehold!.id
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.holiday_village_outlined,
                size: 16,
                color: Color(0xFF64748B),
              ),
              SizedBox(width: 6),
              Text(
                'Active Household',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFCBD5E1),
                width: 1.1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedId,
                isExpanded: true,
                hint: Text(
                  currentHousehold?.name ?? 'Select household',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF475569),
                  size: 20,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
                items: [
                  ...myHouseholds.map(
                    (h) => DropdownMenuItem<int>(
                      value: h.id,
                      child: Text(
                        h.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const DropdownMenuItem<int>(
                    value: createOrJoinId,
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          size: 17,
                          color: primaryGreen,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Create or Join',
                            style: TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  _scaffoldKey.currentState?.closeDrawer();
                  if (value == createOrJoinId) {
                    openAddHousehold();
                    return;
                  }
                  final selected = myHouseholds.firstWhere((h) => h.id == value);
                  switchHousehold(selected);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = tab == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Material(
        color: isSelected ? const Color(0xFFECFDF5) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isSelected
                ? primaryGreen.withValues(alpha: 0.25)
                : Colors.transparent,
            width: 1.2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            setState(() => tab = index);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? primaryGreen : const Color(0xFF64748B),
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 15,
                      color:
                          isSelected ? primaryGreen : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryGreen,
                    ),
                  ),
              ],
            ),
          ),
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
            _syncMemberAvatars(bountiesList, leaderboardList);
            final isLoading = bountySnapshot.connectionState == ConnectionState.waiting;
            final errorMessage = bountySnapshot.hasError ? widget.bounties.error(bountySnapshot.error!) : null;

            return DashboardView(
              user: currentUser,
              currentHousehold: currentHousehold,
              myHouseholds: myHouseholds,
              bounties: bountiesList,
              leaderboard: leaderboardList,
              isLoading: isLoading,
              errorMessage: errorMessage,
              notificationCount: _unreadNotificationCount,
              onRefresh: () => refresh(showError: true),
              onSelectBounty: openDetail,
              onCreateBounty: create,
              onHouseholdSwitch: openHouseholdSwitcher,
              onHouseholdSelected: (h) async {
                await switchHousehold(h);
              },
              onAddHousehold: openAddHousehold,
              onNotificationTap: openNotificationsPage,
              onProfileTap: () => setState(() => tab = 4),
              onViewMyTasks: () => setState(() => tab = 1),
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 1: CHORES (AVAILABLE, IN PROGRESS, COMPLETED, POSTED BY ME)
  // -------------------------------------------------------------
  Widget choresView() {
    return FutureBuilder<List<Bounty>>(
      future: future,
      builder: (context, snapshot) {
        final bountiesList = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final errorMessage = snapshot.hasError
            ? widget.bounties.error(snapshot.error!)
            : null;

        return ChoresView(
          user: currentUser,
          currentHousehold: currentHousehold,
          bounties: bountiesList,
          isLoading: isLoading,
          errorMessage: errorMessage,
          onRefresh: () => refresh(showError: true),
          onSelectBounty: openDetail,
          onCreateBounty: create,
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 2: ROOMMATE LEADERBOARD (HALL OF FAME)
  // -------------------------------------------------------------
  Widget leaderboardView() {
    return FutureBuilder<List<LeaderboardEntry>>(
      future: leaderboardFuture,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        if (snapshot.hasData) {
          _latestLeaderboard = entries;
        }
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final errorMessage = snapshot.hasError ? widget.bounties.error(snapshot.error!) : null;

        return LeaderboardView(
          currentUser: currentUser,
          currentHousehold: currentHousehold,
          leaderboard: entries,
          isLoading: isLoading,
          errorMessage: errorMessage,
          onRefresh: () => refresh(showError: true),
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          onUserTap: (entry) => openUserDetail(
            userId: entry.userId,
            name: entry.name,
            avatarId: entry.avatarUrl,
            leaderboardEntry: entry,
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 3: HOUSEHOLD MEMBERS
  // -------------------------------------------------------------
  Widget householdView() {
    return FutureBuilder<List<HouseholdMember>>(
      future: membersFuture,
      builder: (context, snapshot) {
        final membersList = snapshot.data ?? [];
        if (snapshot.hasData) {
          _latestMembers = membersList;
        }
        final isLoading = snapshot.connectionState == ConnectionState.waiting ||
            isHouseholdsLoading;
        final errorMessage = snapshot.hasError
            ? widget.households.error(snapshot.error!)
            : null;

        return HouseholdView(
          currentUser: currentUser,
          currentHousehold: currentHousehold,
          members: membersList,
          leaderboard: _latestLeaderboard,
          bounties: _latestBounties,
          isLoading: isLoading,
          errorMessage: errorMessage,
          onRefresh: () => refresh(showError: true),
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          onMemberTap: (member) => openUserDetail(
            userId: member.userId,
            name: member.name,
            avatarId: member.avatar,
            member: member,
          ),
          onRenameHousehold: handleRenameHousehold,
          onRemoveMember: handleRemoveMember,
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 4: PROFILE & MULTI-HOUSEHOLD MANAGEMENT
  // -------------------------------------------------------------
  Widget profileView() {
    final myEntry = _latestLeaderboard
        .where((e) => e.userId == currentUser.id)
        .firstOrNull;
    final myMember = _latestMembers
        .where((m) => m.userId == currentUser.id)
        .firstOrNull;

    return ProfileView(
      currentUser: currentUser,
      currentHousehold: currentHousehold,
      myHouseholds: myHouseholds,
      leaderboardEntry: myEntry,
      member: myMember,
      bounties: _latestBounties,
      onRefresh: () => refresh(showError: true),
      onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      onEditProfile: openEditProfile,
      onSelectBounty: openDetail,
      onAddHousehold: openAddHousehold,
      onSwitchHousehold: switchHousehold,
      onLeaveHousehold: handleLeaveHousehold,
      onLogout: logout,
    );
  }

  // -------------------------------------------------------------
  // ACTION HANDLERS & NAVIGATION
  // -------------------------------------------------------------
  Future<void> openUserDetail({
    required int userId,
    required String name,
    String? avatarId,
    LeaderboardEntry? leaderboardEntry,
    HouseholdMember? member,
  }) async {
    if (userId == currentUser.id) {
      final homeRoute = ModalRoute.of(context);
      if (homeRoute != null && !homeRoute.isCurrent) {
        Navigator.popUntil(context, (route) => route == homeRoute);
      }
      setState(() => tab = 4);
      return;
    }

    final matchedEntry = leaderboardEntry ??
        _latestLeaderboard.where((e) => e.userId == userId).firstOrNull;
    final matchedMember = member ??
        _latestMembers.where((m) => m.userId == userId).firstOrNull;
    final resolvedAvatar =
        matchedMember?.avatar ?? matchedEntry?.avatarUrl ?? avatarId ?? _memberAvatars['$userId'];

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(
          currentUser: currentUser,
          userId: userId,
          name: matchedMember?.name ?? matchedEntry?.name ?? name,
          avatarId: resolvedAvatar,
          email: matchedMember?.email ?? '',
          gender: matchedMember?.gender ?? matchedEntry?.gender,
          role: matchedMember?.role,
          joinedAt: matchedMember?.joinedAt,
          rank: matchedEntry?.rank,
          totalTokens: matchedEntry?.totalTokens ?? 0,
          completedCount: matchedEntry?.completedCount ?? 0,
          activeCount: matchedEntry?.activeCount ?? 0,
          household: currentHousehold,
          bounties: _latestBounties,
          bountyService: widget.bounties,
          memberAvatars: Map<String, String>.from(_memberAvatars),
          onRefresh: refresh,
          onUserTap: ({
            required int userId,
            required String name,
            String? avatarId,
          }) =>
              openUserDetail(
                userId: userId,
                name: name,
                avatarId: avatarId,
              ),
        ),
      ),
    );
  }

  Future<void> openDetail(Bounty bounty) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => BountyDetailScreen(
          bounty: bounty,
          currentUser: currentUser,
          service: widget.bounties,
          memberAvatars: Map<String, String>.from(_memberAvatars),
          refreshOnOpen: true,
          onRefresh: refresh,
          onUserTap: ({
            required int userId,
            required String name,
            String? avatarId,
          }) =>
              openUserDetail(
                userId: userId,
                name: name,
                avatarId: avatarId,
              ),
        ),
      ),
    );
    if (updated == true && mounted) {
      await refresh();
    }
  }
}


