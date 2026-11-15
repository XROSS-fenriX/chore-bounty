import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/household.dart';
import '../models/leaderboard_entry.dart';
import '../widgets/dashboard/dashboard_filter_pills.dart';
import '../widgets/leaderboard/leaderboard_podium.dart';
import '../widgets/leaderboard/leaderboard_row.dart';
import '../widgets/leaderboard/leaderboard_summary_card.dart';
import '../widgets/ui.dart';

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({
    super.key,
    required this.currentUser,
    required this.currentHousehold,
    required this.leaderboard,
    required this.isLoading,
    this.errorMessage,
    required this.onRefresh,
    required this.onMenuTap,
    required this.onUserTap,
    this.period = 'all',
    this.onPeriodChanged,
  });

  final AppUser? currentUser;
  final Household? currentHousehold;
  final List<LeaderboardEntry> leaderboard;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback onMenuTap;
  final void Function(LeaderboardEntry entry) onUserTap;
  final String period;
  final ValueChanged<String>? onPeriodChanged;

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  static const _periodKeyToLabel = <String, String>{
    'week': 'Week',
    'month': 'Month',
    'all': 'All time',
  };

  static const _periodLabelToKey = <String, String>{
    'Week': 'week',
    'Month': 'month',
    'All time': 'all',
  };

  static const _periodLabels = ['Week', 'Month', 'All time'];

  late String _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.period;
  }

  @override
  void didUpdateWidget(covariant LeaderboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.period != oldWidget.period) {
      _selectedPeriod = widget.period;
    }
  }

  void _onFilterLabelSelected(String label) {
    final key = _periodLabelToKey[label];
    if (key == null || _selectedPeriod == key) return;
    setState(() => _selectedPeriod = key);
    widget.onPeriodChanged?.call(key);
  }

  @override
  Widget build(BuildContext context) {
    final household = widget.currentHousehold;
    final entries = widget.leaderboard;
    final podiumEntries = entries.take(3).toList();
    final memberCount = household != null
        ? (household.membersCount > 0 ? household.membersCount : entries.length)
        : entries.length;
    final selectedLabel = _periodKeyToLabel[_selectedPeriod] ?? 'All time';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F4),
      body: SafeArea(
        child: Column(
          children: [
            PageMenuHeader(
              title: 'Leaderboard',
              onMenuTap: widget.onMenuTap,
            ),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF1B8354),
                onRefresh: widget.onRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  children: [
                    if (household != null) ...[
                      Text(
                        '${household.name} · $memberCount ${memberCount == 1 ? 'member' : 'members'}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    DashboardFilterPills(
                      filters: _periodLabels,
                      selectedFilter: selectedLabel,
                      onFilterChanged: _onFilterLabelSelected,
                    ),
                    const SizedBox(height: 16),
                    if (widget.isLoading && entries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1B8354),
                          ),
                        ),
                      )
                    else if (widget.errorMessage != null && entries.isEmpty)
                      _StateCard(
                        icon: Icons.cloud_off_rounded,
                        message: widget.errorMessage!,
                        actionLabel: 'Retry',
                        onAction: widget.onRefresh,
                      )
                    else if (entries.isEmpty)
                      const _StateCard(
                        icon: Icons.bar_chart_rounded,
                        message: 'No household members on the leaderboard yet.',
                      )
                    else ...[
                      LeaderboardSummaryCard(entries: entries),
                      const SizedBox(height: 18),
                      LeaderboardPodiumSection(
                        entries: podiumEntries,
                        currentUserId: widget.currentUser?.id,
                        onUserTap: widget.onUserTap,
                      ),
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'RANKING',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            for (int i = 0; i < entries.length; i++) ...[
                              if (i > 0)
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFE2E8F0),
                                ),
                              LeaderboardRow(
                                entry: entries[i],
                                isCurrentUser: widget.currentUser != null &&
                                    entries[i].userId == widget.currentUser!.id,
                                onTap: () => widget.onUserTap(entries[i]),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: Color(0xFF1B8354),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
