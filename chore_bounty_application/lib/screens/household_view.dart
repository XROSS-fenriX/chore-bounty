import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_user.dart';
import '../models/bounty.dart';
import '../models/household.dart';
import '../models/household_member.dart';
import '../models/leaderboard_entry.dart';
import '../widgets/avatar/user_avatar_widget.dart';
import '../widgets/bounty_form/bounty_category_icons.dart';
import '../widgets/ui.dart';

class HouseholdView extends StatelessWidget {
  const HouseholdView({
    super.key,
    required this.currentUser,
    this.currentHousehold,
    required this.members,
    this.leaderboard = const [],
    this.bounties = const [],
    required this.isLoading,
    this.errorMessage,
    required this.onRefresh,
    this.onMenuTap,
    this.onMemberTap,
    this.onRenameHousehold,
    this.onRemoveMember,
  });

  final AppUser currentUser;
  final Household? currentHousehold;
  final List<HouseholdMember> members;
  final List<LeaderboardEntry> leaderboard;
  final List<Bounty> bounties;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback? onMenuTap;
  final ValueChanged<HouseholdMember>? onMemberTap;
  final Future<void> Function(Household household, String newName)?
      onRenameHousehold;
  final Future<void> Function(Household household, HouseholdMember member)?
      onRemoveMember;

  ({int tokens, int bountiesCount}) _memberStats(HouseholdMember member) {
    final entry =
        leaderboard.where((e) => e.userId == member.userId).firstOrNull;
    if (entry != null) {
      return (tokens: entry.totalTokens, bountiesCount: entry.completedCount);
    }

    final uid = member.userId.toString();
    final completed = bounties
        .where((b) => b.assigneeId == uid && b.isCompleted)
        .toList();
    final tokens = completed.fold<int>(
      0,
      (sum, b) =>
          sum + (b.points > 0 ? b.points : (b.rewardValue?.toInt() ?? 0)),
    );
    return (tokens: tokens, bountiesCount: completed.length);
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1B8354);
    final household = currentHousehold;
    final sortedMembers = HouseholdMember.sortOwnerFirst(
      members,
      createdBy: household?.createdBy,
    );

    final memberCount = sortedMembers.isNotEmpty || !isLoading
        ? sortedMembers.length
        : (household?.membersCount ?? 0);

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
            title: 'Household',
            onMenuTap: onMenuTap,
          ),
          const SizedBox(height: 18),
          if (household == null)
            _buildEmptyBox(
              icon: Icons.holiday_village_outlined,
              title: 'No active household',
              subtitle:
                  'Select or join a household from the menu to see members.',
            )
          else ...[
            _buildHouseholdHero(context, household, memberCount, primaryGreen),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Roommates',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$memberCount',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (isLoading && sortedMembers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(color: primaryGreen),
                ),
              )
            else if (errorMessage != null && sortedMembers.isEmpty)
              _buildEmptyBox(
                icon: Icons.error_outline_rounded,
                title: 'Unable to load members',
                subtitle: errorMessage!,
              )
            else if (sortedMembers.isEmpty)
              _buildEmptyBox(
                icon: Icons.group_outlined,
                title: 'No roommates found',
                subtitle: 'Pull down to refresh household members.',
              )
            else
              ...sortedMembers.map(
                (member) => _buildMemberRow(
                  context,
                  household,
                  member,
                  primaryGreen,
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _copyInviteCode(BuildContext context, String inviteCode) {
    Clipboard.setData(ClipboardData(text: inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invite code "$inviteCode" copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    Household household,
  ) async {
    final updatedName = await showDialog<String>(
      context: context,
      builder: (_) => PromptInputDialog(
        title: 'Rename Household',
        initialValue: household.name,
        labelText: 'Household Name',
        confirmLabel: 'Save',
        autofocus: true,
        textCapitalization: TextCapitalization.words,
      ),
    );
    if (updatedName != null &&
        updatedName.trim().isNotEmpty &&
        updatedName.trim() != household.name &&
        onRenameHousehold != null) {
      await onRenameHousehold!(household, updatedName.trim());
    }
  }

  Future<void> _confirmRemoveMember(
    BuildContext context,
    Household household,
    HouseholdMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${member.name}?'),
        content: Text(
          '${member.name} will be removed from ${household.name}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && onRemoveMember != null) {
      await onRemoveMember!(household, member);
    }
  }

  Widget _buildHouseholdHero(
    BuildContext context,
    Household household,
    int memberCount,
    Color primaryGreen,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Image.asset(
              'assets/images/home_icon.png',
              cacheWidth: 256,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.holiday_village_rounded,
                  color: primaryGreen,
                  size: 40,
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        household.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (household.isOwner && onRenameHousehold != null)
                      IconButton(
                        tooltip: 'Rename household',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () => _showRenameDialog(context, household),
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (household.inviteCode.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Material(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _copyInviteCode(context, household.inviteCode),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Code: ${household.inviteCode}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF15803D),
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.copy_rounded,
                              size: 13,
                              color: Color(0xFF15803D),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(
    BuildContext context,
    Household household,
    HouseholdMember member,
    Color primaryGreen,
  ) {
    final isYou = member.userId == currentUser.id;
    final displayName = isYou ? '${member.name} (You)' : member.name;
    final stats = _memberStats(member);
    final canRemove = household.isOwner &&
        !member.isOwner &&
        !isYou &&
        onRemoveMember != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isYou ? primaryGreen : const Color(0xFFE2E8F0),
          width: isYou ? 1.5 : 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onMemberTap != null ? () => onMemberTap!(member) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                UserAvatarWidget(
                  avatarId: member.avatar,
                  userName: member.name,
                  size: 52,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: member.isOwner
                                  ? Colors.amber.shade100
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              member.isOwner ? 'Owner' : 'Member',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: member.isOwner
                                    ? Colors.amber.shade900
                                    : Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const BountyCoinWidget(size: 16),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    '${stats.tokens} ${stats.tokens == 1 ? 'token' : 'tokens'}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF475569),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.task_alt_rounded,
                                  size: 15,
                                  color: primaryGreen,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    '${stats.bountiesCount} ${stats.bountiesCount == 1 ? 'chore' : 'chores'}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF475569),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (canRemove) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Remove member',
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        _confirmRemoveMember(context, household, member),
                    icon: const Icon(
                      Icons.person_remove_outlined,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyBox({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
