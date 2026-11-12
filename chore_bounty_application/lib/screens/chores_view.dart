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
  bool _showSearch = false;
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
          PageMenuHeader(
            title: 'Bounties',
            onMenuTap: widget.onMenuTap,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: _showSearch ? 'Close search' : 'Search bounties',
                  onPressed: () {
                    setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) {
                        _searchController.clear();
                        _searchQuery = '';
                      }
                    });
                  },
                  icon: Icon(
                    _showSearch ? Icons.close_rounded : Icons.search_rounded,
                    color: const Color(0xFF475569),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 2),
                Material(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: widget.onCreateBounty,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Post',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
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
          if (_showSearch) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Search bounties by title or category...',
                hintStyle: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF94A3B8),
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
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: primaryGreen, width: 1.4),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Primary Category Filters
          DashboardFilterPills(
            selectedFilter: _selectedFilter,
            filters: primaryFilters,
            scrollable: true,
            onFilterChanged: (filter) {
              setState(() => _selectedFilter = filter);
            },
          ),

          // Secondary Status Dropdown Filter for 'Posted by Me'
          if (_selectedFilter == 'Posted by Me') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPostedStatus,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF475569),
                          size: 19,
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        items: postedStatusFilters.map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPostedStatus = value);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),

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
          else
            _buildChoreList(filtered),
        ],
      ),
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

