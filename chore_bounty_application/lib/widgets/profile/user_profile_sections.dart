import 'package:flutter/material.dart';
import '../../models/bounty.dart';
import '../../models/household.dart';
import '../avatar/user_avatar_widget.dart';
import '../bounty_form/bounty_category_icons.dart';
import '../dashboard/dashboard_chore_list.dart';
import '../dashboard/dashboard_filter_pills.dart';
import '../ui.dart';

class UserProfileHeaderCard extends StatelessWidget {
  const UserProfileHeaderCard({
    super.key,
    required this.name,
    this.avatarId,
    this.email = '',
    this.gender,
    this.role,
    this.household,
    this.joinedAt,
    this.isCurrentUser = false,
    this.onAvatarTap,
    this.statsRow,
  });

  final String name;
  final String? avatarId;
  final String email;
  final String? gender;
  final String? role;
  final Household? household;
  final DateTime? joinedAt;
  final bool isCurrentUser;
  final VoidCallback? onAvatarTap;
  final Widget? statsRow;

  String _formatJoinedDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month =
        (date.month >= 1 && date.month <= 12) ? months[date.month - 1] : '';
    return 'Joined $month ${date.year}';
  }

  IconData? _genderIcon(String? rawGender) {
    if (rawGender == null) return null;
    final g = rawGender.trim().toLowerCase();
    if (g == 'male') return Icons.male_rounded;
    if (g == 'female') return Icons.female_rounded;
    if (g.isNotEmpty) return Icons.transgender_rounded;
    return null;
  }

  Color _genderColor(String? rawGender) {
    if (rawGender == null) return const Color(0xFF64748B);
    final g = rawGender.trim().toLowerCase();
    if (g == 'male') return const Color(0xFF2563EB);
    if (g == 'female') return const Color(0xFFEC4899);
    return const Color(0xFF8B5CF6);
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1B8354);
    final displayName = isCurrentUser ? '$name (You)' : name;
    final isOwner = role?.toLowerCase() == 'owner';
    final gIcon = _genderIcon(gender);
    final gColor = _genderColor(gender);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.4),
      ),
      child: Column(
        children: [
          UserAvatarWidget(
            avatarId: avatarId,
            userName: name,
            size: 86,
            borderColor: primaryGreen,
            borderWidth: 2.5,
            showEditBadge: onAvatarTap != null,
            onTap: onAvatarTap,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (gIcon != null) ...[
                const SizedBox(width: 6),
                Icon(
                  gIcon,
                  size: 22,
                  color: gColor,
                ),
              ],
            ],
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (role != null ||
              household != null ||
              joinedAt != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (role != null)
                  _ProfileTag(
                    label: isOwner ? 'Owner' : 'Member',
                    bgColor:
                        isOwner ? Colors.amber.shade100 : Colors.blue.shade50,
                    textColor: isOwner
                        ? Colors.amber.shade900
                        : Colors.blue.shade800,
                  ),
                if (household != null)
                  _ProfileTag(
                    label: household!.name,
                    bgColor: const Color(0xFFDCFCE7),
                    textColor: const Color(0xFF15803D),
                  ),
                if (joinedAt != null)
                  _ProfileTag(
                    label: _formatJoinedDate(joinedAt!),
                    bgColor: const Color(0xFFF1F5F9),
                    textColor: const Color(0xFF475569),
                  ),
              ],
            ),
          ],
          if (statsRow != null) ...[
            const SizedBox(height: 18),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 14),
            statsRow!,
          ],
        ],
      ),
    );
  }
}

class _ProfileTag extends StatelessWidget {
  const _ProfileTag({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class UserProfileStatsRow extends StatelessWidget {
  const UserProfileStatsRow({
    super.key,
    required this.rank,
    required this.totalTokens,
    required this.completedCount,
    this.standalone = true,
  });

  final int? rank;
  final int totalTokens;
  final int completedCount;
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1B8354);
    final rankLabel =
        rank != null && rank! > 0 ? formatOrdinalRank(rank!) : '—';

    final statsContent = Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rankLabel,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 1,
          height: 32,
          color: const Color(0xFFE2E8F0),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BountyCoinWidget(size: 18),
                  const SizedBox(width: 5),
                  Text(
                    '$totalTokens',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              const Text(
                'Points',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 1,
          height: 32,
          color: const Color(0xFFE2E8F0),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$completedCount',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Completed',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!standalone) {
      return statsContent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: statsContent,
    );
  }
}

class UserChoreActivitySection extends StatefulWidget {
  const UserChoreActivitySection({
    super.key,
    required this.userId,
    required this.userName,
    required this.currentUserId,
    required this.currentUserName,
    required this.bounties,
    required this.onSelectBounty,
  });

  final int userId;
  final String userName;
  final String currentUserId;
  final String currentUserName;
  final List<Bounty> bounties;
  final ValueChanged<Bounty> onSelectBounty;

  @override
  State<UserChoreActivitySection> createState() =>
      _UserChoreActivitySectionState();
}

class _UserChoreActivitySectionState extends State<UserChoreActivitySection> {
  static const List<String> _filters = [
    'Completed',
    'In Progress',
    'Posted',
  ];

  String _selectedFilter = 'Completed';

  String get _uid => widget.userId.toString();

  List<Bounty> get _filteredChores {
    switch (_selectedFilter) {
      case 'In Progress':
        return widget.bounties
            .where((b) => b.assigneeId == _uid && (b.isClaimed || b.isSubmitted))
            .toList();
      case 'Posted':
        return widget.bounties.where((b) => b.creatorId == _uid).toList();
      case 'Completed':
      default:
        return widget.bounties
            .where((b) => b.assigneeId == _uid && b.isCompleted)
            .toList();
    }
  }

  ({IconData icon, String title, String subtitle}) _emptySpec() {
    final isSelf = _uid == widget.currentUserId;
    switch (_selectedFilter) {
      case 'In Progress':
        return (
          icon: Icons.assignment_outlined,
          title: 'No chores in progress',
          subtitle: isSelf
              ? 'You have no active claimed chores right now.'
              : '${widget.userName} has no active claimed chores.',
        );
      case 'Posted':
        return (
          icon: Icons.post_add_rounded,
          title: 'No posted chores',
          subtitle: isSelf
              ? 'You have not posted any chores yet.'
              : '${widget.userName} has not posted any chores yet.',
        );
      case 'Completed':
      default:
        return (
          icon: Icons.verified_outlined,
          title: 'No completed chores yet',
          subtitle: isSelf
              ? 'Your completed chores will appear here.'
              : 'Completed chores by ${widget.userName} will appear here.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _emptySpec();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chore Activity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        DashboardFilterPills(
          selectedFilter: _selectedFilter,
          filters: _filters,
          onFilterChanged: (filter) {
            setState(() => _selectedFilter = filter);
          },
        ),
        const SizedBox(height: 14),
        DashboardChoreList(
          bounties: _filteredChores,
          currentUserId: widget.currentUserId,
          currentUserName: widget.currentUserName,
          onSelectBounty: widget.onSelectBounty,
          emptyIcon: spec.icon,
          emptyTitle: spec.title,
          emptySubtitle: spec.subtitle,
        ),
      ],
    );
  }
}

