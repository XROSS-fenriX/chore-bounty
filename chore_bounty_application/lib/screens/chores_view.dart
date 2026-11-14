import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/bounty.dart';
import '../models/household.dart';
import '../widgets/dashboard/dashboard_chore_list.dart';
import '../widgets/dashboard/dashboard_filter_pills.dart';
import '../widgets/ui.dart';

class ChoresView extends StatefulWidget {
  const ChoresView({
    super.key,
    required this.user,
    this.currentHousehold,
    required this.bounties,
    required this.isLoading,
    this.errorMessage,
    required this.onRefresh,
    required this.onSelectBounty,
    required this.onCreateBounty,
    this.onMenuTap,
  });

  final AppUser user;
  final Household? currentHousehold;
  final List<Bounty> bounties;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final ValueChanged<Bounty> onSelectBounty;
  final VoidCallback onCreateBounty;
  final VoidCallback? onMenuTap;

  @override
  State<ChoresView> createState() => _ChoresViewState();
}

class _ChoresViewState extends State<ChoresView> {
  static const List<String> primaryFilters = [
    'Available',
    'In Progress',
    'Completed',
    'Posted by Me',
  ];

  static const List<String> postedStatusFilters = [
    'All',
    'Available',
    'Taken',
    'Completed',
    'Past Due',
    'Cancelled',
  ];

  String _selectedFilter = 'Available';
  String _selectedPostedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isPostedByMe(Bounty b) {
    final uid = widget.user.id.toString();
    if (b.creatorId.isNotEmpty) {
      return b.creatorId == uid;
    }
    return b.creator.trim().toLowerCase() ==
        widget.user.name.trim().toLowerCase();
  }

  bool _matchesPostedStatus(Bounty b) {
    switch (_selectedPostedStatus) {
      case 'Available':
        return b.isAvailable;
      case 'Taken':
        return b.isClaimed || b.isSubmitted;
      case 'Completed':
        return b.isCompleted;
      case 'Past Due':
        return b.isPastDue;
      case 'Cancelled':
        return b.isCancelled;
      case 'All':
      default:
        return true;
    }
  }

  List<Bounty> get _readyForApprovalChores =>
      widget.bounties.where((b) => _isPostedByMe(b) && b.isSubmitted).toList();

  List<Bounty> get _filteredBounties {
    final uid = widget.user.id.toString();
    final baseList = switch (_selectedFilter) {
      'In Progress' => widget.bounties
          .where((b) =>
              !_isPostedByMe(b) &&
              b.assigneeId == uid &&
              (b.isClaimed || b.isSubmitted))
          .toList(),
      'Completed' =>
        widget.bounties.where((b) => !_isPostedByMe(b) && b.isCompleted).toList(),
      'Posted by Me' => widget.bounties
          .where((b) => _isPostedByMe(b) && _matchesPostedStatus(b))
          .toList(),
      _ => widget.bounties
          .where((b) => !_isPostedByMe(b) && b.isAvailable)
          .toList(),
    };

    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return baseList;
    return baseList.where((b) {
      return b.title.toLowerCase().contains(query) ||
          b.category.toLowerCase().contains(query) ||
          b.creator.toLowerCase().contains(query);
    }).toList();
  }

  ({IconData icon, String title, String subtitle, bool showPostButton})
      _emptyStateSpec() {
    switch (_selectedFilter) {
      case 'In Progress':
        return (
          icon: Icons.assignment_outlined,
          title: 'No chores in progress',
          subtitle: 'Claim an available chore from a roommate to get started.',
          showPostButton: false,
        );
      case 'Completed':
        return (
          icon: Icons.verified_outlined,
          title: 'No completed chores yet',
          subtitle: 'Finished chores posted by roommates will appear here.',
          showPostButton: false,
        );
      case 'Posted by Me':
        if (_selectedPostedStatus != 'All') {
          return (
            icon: Icons.filter_list_off_rounded,
            title: 'No ${_selectedPostedStatus.toLowerCase()} chores',
            subtitle: 'None of your posted chores match this status.',
            showPostButton: false,
          );
        }
        return (
          icon: Icons.post_add_rounded,
          title: 'No posted chores yet',
          subtitle: 'Post a chore for roommates to claim.',
          showPostButton: true,
        );
      case 'Available':
      default:
        return (
          icon: Icons.check_circle_outline_rounded,
          title: 'No available chores',
          subtitle: 'No open chores posted by roommates right now.',
          showPostButton: false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1B8354);
    final filtered = _filteredBounties;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: primaryGreen,
      backgroundColor: Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 100),
        children: [
          // Row 1: Menu icon, Chores title, Square [+] button
          PageMenuHeader(
            title: 'Chores',
            onMenuTap: widget.onMenuTap,
            trailing: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                tooltip: 'Post a chore',
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: widget.onCreateBounty,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Row 2: Search input on left, Dropdown on right
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search chores...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                size: 16,
                                color: Color(0xFF94A3B8),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    items: primaryFilters.map((filter) {
                      return DropdownMenuItem<String>(
                        value: filter,
                        child: Text(filter),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedFilter = value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          // Row 3: Only show Pill filters when "Posted by Me" is the chosen filter
          if (_selectedFilter == 'Posted by Me') ...[
            const SizedBox(height: 12),
            DashboardFilterPills(
              selectedFilter: _selectedPostedStatus,
              filters: postedStatusFilters,
              scrollable: true,
              onFilterChanged: (filter) {
                setState(() => _selectedPostedStatus = filter);
              },
            ),
          ],
          const SizedBox(height: 16),

          // Content / Loading / Error
          if (widget.isLoading && widget.bounties.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: CircularProgressIndicator(color: primaryGreen),
              ),
            )
          else if (widget.errorMessage != null && widget.bounties.isEmpty)
            _buildErrorState(widget.errorMessage!)
          else ...[
            if (_readyForApprovalChores.isNotEmpty) ...[
              _buildReadyForApprovalSection(),
              const SizedBox(height: 22),
            ],
            _buildChoreList(filtered),
          ],
        ],
      ),
    );
  }

  Widget _buildReadyForApprovalSection() {
    final readyList = _readyForApprovalChores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            children: [
              const Text(
                'Ready for Approval',
                style: TextStyle(
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
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${readyList.length}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
        ),
        DashboardChoreList(
          bounties: readyList,
          currentUserId: widget.user.id.toString(),
          currentUserName: widget.user.name,
          onSelectBounty: widget.onSelectBounty,
          emptyIcon: Icons.fact_check_outlined,
          emptyTitle: 'No chores awaiting approval',
          emptySubtitle: 'Submitted chores from roommates will appear here.',
          showPostButton: false,
          onCreateBounty: widget.onCreateBounty,
        ),
      ],
    );
  }

  Widget _buildChoreList(List<Bounty> filtered) {
    final spec = _emptyStateSpec();
    return DashboardChoreList(
      bounties: filtered,
      currentUserId: widget.user.id.toString(),
      currentUserName: widget.user.name,
      onSelectBounty: widget.onSelectBounty,
      emptyIcon: spec.icon,
      emptyTitle: spec.title,
      emptySubtitle: spec.subtitle,
      showPostButton: spec.showPostButton,
      onCreateBounty: widget.onCreateBounty,
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
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 36,
          ),
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

