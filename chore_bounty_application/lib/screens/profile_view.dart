import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_user.dart';
import '../models/bounty.dart';
import '../models/household.dart';
import '../models/household_member.dart';
import '../models/leaderboard_entry.dart';
import '../widgets/profile/user_profile_sections.dart';
import '../widgets/ui.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({
    super.key,
    required this.currentUser,
    this.currentHousehold,
    required this.myHouseholds,
    this.leaderboardEntry,
    this.member,
    this.bounties = const [],
    this.memberHouseholdIds,
    this.activeMemberIds,
    required this.onRefresh,
    this.onMenuTap,
    required this.onEditProfile,
    required this.onSelectBounty,
    required this.onAddHousehold,
    required this.onSwitchHousehold,
    required this.onLeaveHousehold,
    required this.onLogout,
  });

  static const int _householdsPreviewLimit = 3;
  static const Color _primaryGreen = Color(0xFF1B8354);

  final AppUser currentUser;
  final Household? currentHousehold;
  final List<Household> myHouseholds;
  final LeaderboardEntry? leaderboardEntry;
  final HouseholdMember? member;
  final List<Bounty> bounties;
  final Set<String>? memberHouseholdIds;
  final Set<String>? activeMemberIds;
  final Future<void> Function() onRefresh;
  final VoidCallback? onMenuTap;
  final VoidCallback onEditProfile;
  final ValueChanged<Bounty> onSelectBounty;
  final VoidCallback onAddHousehold;
  final ValueChanged<Household> onSwitchHousehold;
  final ValueChanged<Household> onLeaveHousehold;
  final VoidCallback onLogout;

  List<Bounty> get _visibleBounties {
    final householdIds = memberHouseholdIds ??
        (myHouseholds.isNotEmpty
            ? myHouseholds.map((h) => h.id.toString()).toSet()
            : null);
    return bounties
        .where(
          (b) => b.isVisibleForHousehold(
            currentUserId: currentUser.id.toString(),
            memberHouseholdIds: householdIds,
            activeMemberIds: activeMemberIds,
            activeHouseholdId: currentHousehold?.id.toString(),
          ),
        )
        .toList();
  }

  int get _effectivePoints {
    if (leaderboardEntry != null) return leaderboardEntry!.totalTokens;
    final uid = currentUser.id.toString();
    return _visibleBounties
        .where((b) => b.assigneeId == uid && b.isCompleted)
        .fold<int>(
          0,
          (sum, b) =>
              sum + (b.points > 0 ? b.points : (b.rewardValue?.toInt() ?? 0)),
        );
  }

  int get _effectiveCompletedCount {
    if (leaderboardEntry != null && leaderboardEntry!.completedCount > 0) {
      return leaderboardEntry!.completedCount;
    }
    final uid = currentUser.id.toString();
    return _visibleBounties
        .where((b) => b.assigneeId == uid && b.isCompleted)
        .length;
  }

  String? get _effectiveRole => member?.role ?? currentHousehold?.role;

  List<Household> get _orderedHouseholds {
    if (currentHousehold == null) return myHouseholds;
    final activeId = currentHousehold!.id;
    return [
      ...myHouseholds.where((h) => h.id == activeId),
      ...myHouseholds.where((h) => h.id != activeId),
    ];
  }

  void _openAllHouseholdsSheet(BuildContext context) {
    final ordered = _orderedHouseholds;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _AllHouseholdsSheet(
        households: ordered,
        currentHouseholdId: currentHousehold?.id,
        onCopyInviteCode: (code) => _copyInviteCode(context, code),
        onAddHousehold: () {
          Navigator.of(sheetContext).pop();
          onAddHousehold();
        },
        onSwitchHousehold: (h) {
          Navigator.of(sheetContext).pop();
          onSwitchHousehold(h);
        },
        onLeaveHousehold: (h) {
          Navigator.of(sheetContext).pop();
          onLeaveHousehold(h);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderedHouseholds = _orderedHouseholds;
    final previewHouseholds =
        orderedHouseholds.take(_householdsPreviewLimit).toList();
    final hasMoreHouseholds =
        orderedHouseholds.length > _householdsPreviewLimit;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _primaryGreen,
      backgroundColor: Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 100),
        children: [
          PageMenuHeader(
            title: 'Profile',
            onMenuTap: onMenuTap,
          ),
          const SizedBox(height: 16),
          UserProfileHeaderCard(
            name: currentUser.name,
            avatarId: currentUser.avatar,
            email: currentUser.email,
            gender: currentUser.gender,
            role: _effectiveRole,
            household: currentHousehold,
            joinedAt: member?.joinedAt,
            isCurrentUser: false,
            onAvatarTap: onEditProfile,
            statsRow: UserProfileStatsRow(
              rank: leaderboardEntry?.rank,
              totalTokens: _effectivePoints,
              completedCount: _effectiveCompletedCount,
              standalone: false,
            ),
          ),
          const SizedBox(height: 22),
          UserChoreActivitySection(
            userId: currentUser.id,
            userName: currentUser.name,
            currentUserId: currentUser.id.toString(),
            currentUserName: currentUser.name,
            bounties: _visibleBounties,
            onSelectBounty: onSelectBounty,
          ),
          const SizedBox(height: 24),
          _buildHouseholdsHeader(context, hasMoreHouseholds),
          const SizedBox(height: 10),
          if (orderedHouseholds.isEmpty)
            _buildEmptyHouseholdsCard()
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (int i = 0; i < previewHouseholds.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    _HouseholdRow(
                      household: previewHouseholds[i],
                      isCurrent:
                          currentHousehold?.id == previewHouseholds[i].id,
                      onCopyInviteCode: () => _copyInviteCode(
                        context,
                        previewHouseholds[i].inviteCode,
                      ),
                      onSwitch: () => onSwitchHousehold(previewHouseholds[i]),
                      onLeave: () => onLeaveHousehold(previewHouseholds[i]),
                    ),
                  ],
                  if (hasMoreHouseholds) ...[
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    InkWell(
                      onTap: () => _openAllHouseholdsSheet(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View all ${orderedHouseholds.length} households',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _primaryGreen,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: _primaryGreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 18),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildHouseholdsHeader(BuildContext context, bool hasMore) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'My Households',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${myHouseholds.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF15803D),
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasMore) ...[
              TextButton(
                onPressed: () => _openAllHouseholdsSheet(context),
                style: TextButton.styleFrom(
                  foregroundColor: _primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Material(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onAddHousehold,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: _primaryGreen),
                      SizedBox(width: 4),
                      Text(
                        'Add / Join',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyHouseholdsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.holiday_village_outlined,
            size: 30,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 8),
          const Text(
            'No households yet',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create or join a household to collaborate with roommates.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onAddHousehold,
            icon: const Icon(Icons.add_home_rounded, size: 18),
            label: const Text('Create or Join Household'),
            style: TextButton.styleFrom(
              foregroundColor: _primaryGreen,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _copyInviteCode(BuildContext context, String inviteCode) {
    Clipboard.setData(ClipboardData(text: inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invite code "$inviteCode" copied to clipboard!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      onPressed: onLogout,
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: const Text('Log out'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFDC2626),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFFECACA), width: 1.4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HouseholdRow extends StatelessWidget {
  const _HouseholdRow({
    required this.household,
    required this.isCurrent,
    required this.onCopyInviteCode,
    required this.onSwitch,
    required this.onLeave,
  });

  static const Color _primaryGreen = Color(0xFF1B8354);

  final Household household;
  final bool isCurrent;
  final VoidCallback onCopyInviteCode;
  final VoidCallback onSwitch;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final memberLabel =
        '${household.membersCount} ${household.membersCount == 1 ? 'roommate' : 'roommates'}';

    return Material(
      color: isCurrent ? const Color(0xFFF0FDF4) : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrent
                      ? _primaryGreen.withAlpha(110)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Image.asset(
                'assets/images/home_icon.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.holiday_village_rounded,
                  color: _primaryGreen,
                  size: 20,
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
                      Flexible(
                        child: Text(
                          household.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _primaryGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                      if (household.isOwner) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'OWNER',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        memberLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const Text(
                        ' · ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      InkWell(
                        onTap: onCopyInviteCode,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 1,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                household.inviteCode,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryGreen,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.copy_rounded,
                                size: 12,
                                color: _primaryGreen,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isCurrent) ...[
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: onSwitch,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryGreen,
                  side: const BorderSide(color: _primaryGreen, width: 1.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Switch'),
              ),
            ],
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_horiz_rounded,
                size: 20,
                color: Color(0xFF64748B),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (value) {
                if (value == 'copy') {
                  onCopyInviteCode();
                } else if (value == 'switch') {
                  onSwitch();
                } else if (value == 'leave') {
                  onLeave();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy_rounded, size: 17, color: Color(0xFF475569)),
                      SizedBox(width: 8),
                      Text('Copy Invite Code'),
                    ],
                  ),
                ),
                if (!isCurrent)
                  const PopupMenuItem<String>(
                    value: 'switch',
                    child: Row(
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 17,
                          color: Color(0xFF1B8354),
                        ),
                        SizedBox(width: 8),
                        Text('Switch'),
                      ],
                    ),
                  ),
                const PopupMenuItem<String>(
                  value: 'leave',
                  child: Row(
                    children: [
                      Icon(
                        Icons.exit_to_app_rounded,
                        size: 17,
                        color: Color(0xFFDC2626),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Leave Household',
                        style: TextStyle(color: Color(0xFFDC2626)),
                      ),
                    ],
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

class _AllHouseholdsSheet extends StatefulWidget {
  const _AllHouseholdsSheet({
    required this.households,
    required this.currentHouseholdId,
    required this.onCopyInviteCode,
    required this.onAddHousehold,
    required this.onSwitchHousehold,
    required this.onLeaveHousehold,
  });

  final List<Household> households;
  final int? currentHouseholdId;
  final ValueChanged<String> onCopyInviteCode;
  final VoidCallback onAddHousehold;
  final ValueChanged<Household> onSwitchHousehold;
  final ValueChanged<Household> onLeaveHousehold;

  @override
  State<_AllHouseholdsSheet> createState() => _AllHouseholdsSheetState();
}

class _AllHouseholdsSheetState extends State<_AllHouseholdsSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty
        ? widget.households
        : widget.households
            .where(
              (h) =>
                  h.name.toLowerCase().contains(q) ||
                  h.inviteCode.toLowerCase().contains(q),
            )
            .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.68,
      minChildSize: 0.45,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'My Households (${widget.households.length})',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: widget.onAddHousehold,
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: const Text('Add / Join'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1B8354),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search households...',
                  hintStyle: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching households.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 24),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        color: Color(0xFFE2E8F0),
                      ),
                      itemBuilder: (context, index) {
                        final h = items[index];
                        return _HouseholdRow(
                          household: h,
                          isCurrent: widget.currentHouseholdId == h.id,
                          onCopyInviteCode: () =>
                              widget.onCopyInviteCode(h.inviteCode),
                          onSwitch: () => widget.onSwitchHousehold(h),
                          onLeave: () => widget.onLeaveHousehold(h),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
