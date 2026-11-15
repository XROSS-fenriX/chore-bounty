import 'package:flutter/material.dart';

import '../../models/household.dart';

class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({
    super.key,
    required this.points,
    required this.tasksOngoing,
    this.householdName,
    this.onTap,
    this.onHouseholdTap,
    this.households = const [],
    this.currentHousehold,
    this.onHouseholdSelected,
    this.onAddHousehold,
    this.rank,
    this.completedCount,
    this.memberCount,
  });

  final int points;
  final int tasksOngoing;
  final String? householdName;
  final VoidCallback? onTap;
  final VoidCallback? onHouseholdTap;
  final List<Household> households;
  final Household? currentHousehold;
  final ValueChanged<Household>? onHouseholdSelected;
  final VoidCallback? onAddHousehold;
  final int? rank;
  final int? completedCount;
  final int? memberCount;

  static const Color _cardGreen = Color(0xFF1B8354);
  static const Color _borderColor = Color(0xFF13603D);
  static const Color _pillGreen = Color(0xFF156B44);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      decoration: BoxDecoration(
        color: _cardGreen,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _borderColor,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(21),
          splashColor: Colors.white.withAlpha(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 11,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Points & Ongoing Tasks
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$points',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.6,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Points',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withAlpha(230),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF86EFAC),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  tasksOngoing == 1
                                      ? '1 task ongoing'
                                      : '$tasksOngoing tasks ongoing',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withAlpha(220),
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (rank != null) ...[
                                const SizedBox(width: 8),
                                _FooterStatChip(
                                  icon: Icons.emoji_events_rounded,
                                  label: memberCount != null && memberCount! > 0
                                      ? 'Rank #$rank of $memberCount'
                                      : 'Rank #$rank',
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Household Selector Pill / Dropdown
                    if (households.isNotEmpty)
                      _buildHouseholdDropdown(context)
                    else
                      Material(
                        color: _pillGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: Colors.white.withAlpha(45),
                            width: 1.2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: onHouseholdTap ?? onTap,
                          borderRadius: BorderRadius.circular(20),
                          splashColor: Colors.white.withAlpha(30),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 112),
                                  child: Text(
                                    (householdName != null &&
                                            householdName!.isNotEmpty)
                                        ? householdName!
                                        : 'Apartment',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: Colors.white.withAlpha(230),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHouseholdDropdown(BuildContext context) {
    const primaryGreen = Color(0xFF1B8354);
    const createOrJoinId = -1;
    final selectedId = (currentHousehold != null &&
            households.any((h) => h.id == currentHousehold!.id))
        ? currentHousehold!.id
        : (households.isNotEmpty ? households.first.id : null);

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _pillGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withAlpha(50),
          width: 1.2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedId,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          icon: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
          selectedItemBuilder: (BuildContext context) {
            return [
              ...households.map((h) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 112),
                    child: Text(
                      h.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 112),
                  child: const Text(
                    '+ Add',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ];
          },
          items: [
            ...households.map((h) {
              final isCurrent = h.id == selectedId;
              return DropdownMenuItem<int>(
                value: h.id,
                child: Row(
                  children: [
                    Icon(
                      Icons.holiday_village_rounded,
                      size: 18,
                      color: isCurrent ? primaryGreen : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        h.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isCurrent ? FontWeight.w800 : FontWeight.w600,
                          color: isCurrent
                              ? primaryGreen
                              : const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const DropdownMenuItem<int>(
              value: createOrJoinId,
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 18,
                    color: primaryGreen,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '+ Add / Join',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryGreen,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (val) {
            if (val == createOrJoinId) {
              if (onAddHousehold != null) {
                onAddHousehold!();
              } else if (onHouseholdTap != null) {
                onHouseholdTap!();
              }
            } else if (val != null) {
              final found = households.firstWhere((h) => h.id == val);
              if (onHouseholdSelected != null) {
                onHouseholdSelected!(found);
              } else if (onHouseholdTap != null) {
                onHouseholdTap!();
              }
            }
          },
        ),
      ),
    );
  }
}

class _FooterStatChip extends StatelessWidget {
  const _FooterStatChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withAlpha(32),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: const Color(0xFFBBF7D0),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
