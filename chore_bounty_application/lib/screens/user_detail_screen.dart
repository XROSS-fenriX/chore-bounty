import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/bounty.dart';
import '../models/household.dart';
import '../models/household_member.dart';
import '../models/leaderboard_entry.dart';
import '../services/bounty_service.dart';
import '../widgets/profile/user_profile_sections.dart';
import 'bounty_detail_screen.dart';

class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({
    super.key,
    required this.currentUser,
    required this.userId,
    required this.name,
    this.avatarId,
    this.email = '',
    this.gender,
    this.role,
    this.joinedAt,
    this.rank,
    this.totalTokens = 0,
    this.completedCount = 0,
    this.activeCount = 0,
    this.household,
    this.bounties = const [],
    this.bountyService,
    this.memberAvatars = const {},
    this.onRefresh,
    this.onUserTap,
  });

  factory UserDetailScreen.fromLeaderboard({
    Key? key,
    required AppUser currentUser,
    required LeaderboardEntry entry,
    HouseholdMember? member,
    Household? household,
    List<Bounty> bounties = const [],
    BountyService? bountyService,
    Map<String, String> memberAvatars = const {},
    Future<void> Function()? onRefresh,
  }) {
    return UserDetailScreen(
      key: key,
      currentUser: currentUser,
      userId: entry.userId,
      name: entry.name,
      avatarId: member?.avatar ?? entry.avatarUrl,
      email: member?.email ?? '',
      gender: member?.gender ?? entry.gender,
      role: member?.role,
      joinedAt: member?.joinedAt,
      rank: entry.rank,
      totalTokens: entry.totalTokens,
      completedCount: entry.completedCount,
      activeCount: entry.activeCount,
      household: household,
      bounties: bounties,
      bountyService: bountyService,
      memberAvatars: memberAvatars,
      onRefresh: onRefresh,
    );
  }

  final AppUser currentUser;
  final int userId;
  final String name;
  final String? avatarId;
  final String email;
  final String? gender;
  final String? role;
  final DateTime? joinedAt;
  final int? rank;
  final int totalTokens;
  final int completedCount;
  final int activeCount;
  final Household? household;
  final List<Bounty> bounties;
  final BountyService? bountyService;
  final Map<String, String> memberAvatars;
  final Future<void> Function()? onRefresh;
  final BountyUserTapCallback? onUserTap;

  int get _effectiveCompletedCount {
    if (completedCount > 0) return completedCount;
    final uid = userId.toString();
    return bounties.where((b) => b.assigneeId == uid && b.isCompleted).length;
  }

  Future<void> _openBounty(BuildContext context, Bounty bounty) async {
    final service = bountyService;
    if (service == null) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => BountyDetailScreen(
          bounty: bounty,
          currentUser: currentUser,
          service: service,
          memberAvatars: memberAvatars,
          refreshOnOpen: true,
          onRefresh: onRefresh,
          onUserTap: onUserTap,
        ),
      ),
    );

    if (updated == true && onRefresh != null) {
      await onRefresh!();
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgLight = Color(0xFFFAF8F5);
    final isCurrentUser = userId == currentUser.id;

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Color(0xFF0F172A),
            size: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'User Profile',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            UserProfileHeaderCard(
              name: name,
              avatarId: avatarId,
              email: email,
              gender: gender,
              role: role,
              household: household,
              joinedAt: joinedAt,
              isCurrentUser: isCurrentUser,
            ),
            const SizedBox(height: 16),
            UserProfileStatsRow(
              rank: rank,
              totalTokens: totalTokens,
              completedCount: _effectiveCompletedCount,
            ),
            const SizedBox(height: 22),
            UserChoreActivitySection(
              userId: userId,
              userName: name,
              currentUserId: currentUser.id.toString(),
              currentUserName: currentUser.name,
              bounties: bounties,
              onSelectBounty: (bounty) => _openBounty(context, bounty),
            ),
          ],
        ),
      ),
    );
  }
}
