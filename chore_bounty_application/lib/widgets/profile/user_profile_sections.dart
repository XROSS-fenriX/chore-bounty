import 'package:flutter/material.dart';
import '../../models/bounty.dart';
import '../../models/household.dart';
import '../avatar/user_avatar_widget.dart';
import '../bounty_form/bounty_category_icons.dart';
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
  static const int _previewLimit = 3;
  static const List<String> _filters = [
    'Completed',
    'In Progress',
    'Posted',
  ];

  String _selectedFilter = 'Completed';

  String get _uid => widget.userId.toString();

  List<Bounty> _choresForFilter(String filter) {
    switch (filter) {
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

  ({IconData icon, String title, String subtitle}) _emptySpec(String filter) {
    final isSelf = _uid == widget.currentUserId;
    switch (filter) {
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

  void _openAllSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ChoreActivitySheet(
        initialFilter: _selectedFilter,
        filters: _filters,
        choresForFilter: _choresForFilter,
        emptySpec: _emptySpec,
        onSelectBounty: (bounty) {
          Navigator.of(context).pop();
          widget.onSelectBounty(bounty);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _choresForFilter(_selectedFilter);
    final preview = filtered.take(_previewLimit).toList();
    final hasMore = filtered.length > _previewLimit;
    final spec = _emptySpec(_selectedFilter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
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
                if (filtered.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${filtered.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (hasMore)
              TextButton(
                onPressed: _openAllSheet,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1B8354),
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
          ],
        ),
        const SizedBox(height: 10),
        DashboardFilterPills(
          selectedFilter: _selectedFilter,
          filters: _filters,
          onFilterChanged: (filter) {
            setState(() => _selectedFilter = filter);
          },
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          _EmptyActivityCard(
            icon: spec.icon,
            title: spec.title,
            subtitle: spec.subtitle,
          )
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
                for (int i = 0; i < preview.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  _CompactActivityRow(
                    bounty: preview[i],
                    onTap: () => widget.onSelectBounty(preview[i]),
                  ),
                ],
                if (hasMore) ...[
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  InkWell(
                    onTap: _openAllSheet,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'View all ${filtered.length} chores',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B8354),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: Color(0xFF1B8354),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _CompactActivityRow extends StatelessWidget {
  const _CompactActivityRow({
    required this.bounty,
    required this.onTap,
  });

  final Bounty bounty;
  final VoidCallback onTap;

  static String _relativeTime(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return '1d ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = bounty.points > 0
        ? bounty.points
        : (bounty.rewardValue?.toInt() ?? 0);
    final timestamp = bounty.completedAt ??
        bounty.submittedAt ??
        bounty.claimedAt ??
        bounty.createdAt;
    final ago = _relativeTime(timestamp);
    final meta = ago.isEmpty
        ? bounty.statusLabel
        : '${bounty.statusLabel} · $ago';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: CategoryIconWidget(category: bounty.category, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bounty.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const BountyCoinWidget(size: 14),
            const SizedBox(width: 4),
            Text(
              '$tokens',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyActivityCard extends StatelessWidget {
  const _EmptyActivityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _ChoreActivitySheet extends StatefulWidget {
  const _ChoreActivitySheet({
    required this.initialFilter,
    required this.filters,
    required this.choresForFilter,
    required this.emptySpec,
    required this.onSelectBounty,
  });

  final String initialFilter;
  final List<String> filters;
  final List<Bounty> Function(String filter) choresForFilter;
  final ({IconData icon, String title, String subtitle}) Function(String filter)
      emptySpec;
  final ValueChanged<Bounty> onSelectBounty;

  @override
  State<_ChoreActivitySheet> createState() => _ChoreActivitySheetState();
}

class _ChoreActivitySheetState extends State<_ChoreActivitySheet> {
  late String _filter;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final baseList = widget.choresForFilter(_filter);
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty
        ? baseList
        : baseList
            .where(
              (b) =>
                  b.title.toLowerCase().contains(q) ||
                  b.category.toLowerCase().contains(q),
            )
            .toList();
    final spec = widget.emptySpec(_filter);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
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
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chore Activity',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
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
              child: DashboardFilterPills(
                selectedFilter: _filter,
                filters: widget.filters,
                onFilterChanged: (f) => setState(() => _filter = f),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search chores...',
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
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: _EmptyActivityCard(
                        icon: spec.icon,
                        title: q.isEmpty ? spec.title : 'No matching chores',
                        subtitle: q.isEmpty
                            ? spec.subtitle
                            : 'Try another search term.',
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        color: Color(0xFFE2E8F0),
                      ),
                      itemBuilder: (context, index) => _CompactActivityRow(
                        bounty: items[index],
                        onTap: () => widget.onSelectBounty(items[index]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

