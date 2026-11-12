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
    required this.onRefresh,
    this.onMenuTap,
    required this.onEditProfile,
    required this.onSelectBounty,
    required this.onAddHousehold,
    required this.onSwitchHousehold,
    required this.onLeaveHousehold,
    required this.onLogout,
  });

  final AppUser currentUser;
  final Household? currentHousehold;
  final List<Household> myHouseholds;
  final LeaderboardEntry? leaderboardEntry;
  final HouseholdMember? member;
  final List<Bounty> bounties;
  final Future<void> Function() onRefresh;
  final VoidCallback? onMenuTap;
  final VoidCallback onEditProfile;
  final ValueChanged<Bounty> onSelectBounty;
  final VoidCallback onAddHousehold;
  final ValueChanged<Household> onSwitchHousehold;
  final ValueChanged<Household> onLeaveHousehold;
  final VoidCallback onLogout;

  int get _effectivePoints {
    if (leaderboardEntry != null) return leaderboardEntry!.totalTokens;
    final uid = currentUser.id.toString();
    return bounties
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
    return bounties.where((b) => b.assigneeId == uid && b.isCompleted).length;
  }

  String? get _effectiveRole => member?.role ?? currentHousehold?.role;

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1B8354);

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
          ),
          const SizedBox(height: 16),
          UserProfileStatsRow(
            rank: leaderboardEntry?.rank,
            totalTokens: _effectivePoints,
            completedCount: _effectiveCompletedCount,
          ),
          const SizedBox(height: 22),
          UserChoreActivitySection(
            userId: currentUser.id,
            userName: currentUser.name,
            currentUserId: currentUser.id.toString(),
            currentUserName: currentUser.name,
            bounties: bounties,
            onSelectBounty: onSelectBounty,
          ),
          const SizedBox(height: 26),
          _buildHouseholdsHeader(primaryGreen),
          const SizedBox(height: 12),
          if (myHouseholds.isEmpty)
            _buildEmptyHouseholdsCard(primaryGreen)
          else
            ...myHouseholds.map(
              (h) => _buildHouseholdCard(context, h, primaryGreen),
            ),
          const SizedBox(height: 16),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildHouseholdsHeader(Color primaryGreen) {
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
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
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
        Material(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onAddHousehold,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 16, color: primaryGreen),
                  const SizedBox(width: 4),
                  Text(
                    'Add / Join',
                    style: TextStyle(
                      fontSize: 12.5,
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
    );
  }

  Widget _buildEmptyHouseholdsCard(Color primaryGreen) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.4),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.holiday_village_outlined,
            size: 34,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 8),
          const Text(
            'No households yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create or join a household to collaborate with roommates.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onAddHousehold,
            icon: const Icon(Icons.add_home_rounded, size: 18),
            label: const Text('Create or Join Household'),
            style: TextButton.styleFrom(
              foregroundColor: primaryGreen,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseholdCard(
    BuildContext context,
    Household h,
    Color primaryGreen,
  ) {
    final isCurrent = currentHousehold?.id == h.id;
    final memberLabel =
        '${h.membersCount} ${h.membersCount == 1 ? 'roommate' : 'roommates'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent ? primaryGreen : const Color(0xFFE2E8F0),
          width: isCurrent ? 1.6 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCurrent
                        ? primaryGreen.withAlpha(90)
                        : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Image.asset(
                  'assets/images/home_icon.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.holiday_village_rounded,
                      color: primaryGreen,
                      size: 24,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      memberLabel,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: h.isOwner
                          ? Colors.amber.shade100
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      h.role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: h.isOwner
                            ? Colors.amber.shade900
                            : Colors.blue.shade800,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _copyInviteCode(context, h.inviteCode),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.vpn_key_outlined,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Invite Code',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const Spacer(),
                    SelectableText(
                      h.inviteCode,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: primaryGreen,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.copy_rounded,
                      size: 15,
                      color: primaryGreen,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isCurrent) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onSwitchHousehold(h),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 17),
                    label: const Text('Switch'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryGreen,
                      side: BorderSide(color: primaryGreen, width: 1.3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onLeaveHousehold(h),
                  icon: const Icon(Icons.exit_to_app_rounded, size: 17),
                  label: const Text('Leave Household'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    backgroundColor: const Color(0xFFFEF2F2),
                    side: const BorderSide(
                      color: Color(0xFFFECACA),
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
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

