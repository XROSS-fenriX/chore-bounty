import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/household.dart';
import '../models/leaderboard_entry.dart';
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
  static const _periods = <({String key, String label})>[
    (key: 'week', label: 'Week'),
    (key: 'month', label: 'Month'),
    (key: 'all', label: 'All time'),
  ];

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

  void _selectPeriod(String key) {
    if (_selectedPeriod == key) return;
    setState(() => _selectedPeriod = key);
    widget.onPeriodChanged?.call(key);
  }

  @override
  Widget build(BuildContext context) {
    final household = widget.currentHousehold;
    final entries = widget.leaderboard;
    final memberCount = household != null
        ? (household.membersCount > 0 ? household.membersCount : entries.length)
        : entries.length;
    final totalHouseholdTokens =
        entries.fold<int>(0, (sum, e) => sum + e.totalTokens);

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
                    _PeriodSegmentedControl(
                      periods: _periods,
                      selectedKey: _selectedPeriod,
                      onChanged: _selectPeriod,
                    ),
                    const SizedBox(height: 14),
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
                      LeaderboardSummaryCard(
                        entries: entries,
                        currentUser: widget.currentUser,
                      ),
                      const SizedBox(height: 18),
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
                                totalHouseholdTokens: totalHouseholdTokens,
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

class _PeriodSegmentedControl extends StatelessWidget {
  const _PeriodSegmentedControl({
    required this.periods,
    required this.selectedKey,
    required this.onChanged,
  });

  final List<({String key, String label})> periods;
  final String selectedKey;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: periods.map((item) {
          final isSelected = item.key == selectedKey;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(item.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x0F0F172A),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
