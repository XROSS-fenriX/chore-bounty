import 'package:flutter/material.dart';
import '../../models/bounty.dart';
import '../bounty_form/bounty_category_icons.dart';
import 'dashboard_illustrations.dart';

class DashboardBountyCard extends StatelessWidget {
  const DashboardBountyCard({
    super.key,
    required this.bounty,
    required this.onTap,
  });

  final Bounty bounty;
  final VoidCallback onTap;

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return '2h ago';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return '1d ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  Widget _buildChoreIcon() {
    final t = bounty.title.toLowerCase();
    final c = bounty.category.toLowerCase();

    Color bgColor = const Color(0xFFFEF3C7); // Soft peach default
    Widget iconWidget;

    if (t.contains('trash') || t.contains('bin') || t.contains('garbage') || t.contains('rubbish')) {
      bgColor = const Color(0xFFD1FAE5); // Mint
      iconWidget = const TrashBinWidget(size: 32);
    } else if (t.contains('vacuum') || t.contains('living room') || t.contains('carpet') || t.contains('rug')) {
      bgColor = const Color(0xFFFEF3C7); // Apricot/Peach
      iconWidget = const VacuumCleanerWidget(size: 32);
    } else if (t.contains('laundry') || t.contains('wash') || c == 'laundry' || t.contains('clothes')) {
      bgColor = const Color(0xFFEDE9FE); // Lavender
      iconWidget = const CategoryIconWidget(category: 'Laundry', size: 32);
    } else if (t.contains('clean') || t.contains('sweep') || t.contains('mop') || c == 'cleaning') {
      bgColor = const Color(0xFFFEF3C7); // Peach
      iconWidget = const CategoryIconWidget(category: 'Cleaning', size: 32);
    } else if (t.contains('kitchen') || t.contains('dish') || c == 'kitchen' || t.contains('cook')) {
      bgColor = const Color(0xFFFFEDD5); // Soft orange
      iconWidget = const CategoryIconWidget(category: 'Kitchen', size: 32);
    } else if (t.contains('grocer') || t.contains('shop') || c == 'groceries' || t.contains('market')) {
      bgColor = const Color(0xFFE0F2FE); // Soft blue
      iconWidget = const CategoryIconWidget(category: 'Groceries', size: 32);
    } else if (t.contains('fix') || t.contains('repair') || c == 'maintenance' || t.contains('bulb')) {
      bgColor = const Color(0xFFF1F5F9); // Slate
      iconWidget = const CategoryIconWidget(category: 'Maintenance', size: 32);
    } else {
      bgColor = const Color(0xFFF1F5F9);
      iconWidget = CategoryIconWidget(category: bounty.category, size: 32);
    }

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: iconWidget),
    );
  }

  Widget _buildDifficultyChip() {
    final diff = bounty.difficulty.toLowerCase();

    Color pillBg;
    Color pillTextColor;
    IconData icon;
    String label;

    switch (diff) {
      case 'epic':
      case 'hard':
        pillBg = const Color(0xFFFEE2E2);
        pillTextColor = const Color(0xFFB91C1C);
        icon = Icons.star_rounded;
        label = diff == 'epic' ? 'Epic' : 'Hard';
        break;
      case 'medium':
      case 'moderate':
        pillBg = const Color(0xFFFFEDD5);
        pillTextColor = const Color(0xFFC2410C);
        icon = Icons.access_time_filled_rounded;
        label = 'Medium';
        break;
      case 'easy':
      default:
        pillBg = const Color(0xFFDCFCE7);
        pillTextColor = const Color(0xFF15803D);
        icon = Icons.check_circle_rounded;
        label = 'Quick';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: pillTextColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: pillTextColor,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rewardDisplay = bounty.points > 0
        ? bounty.points
        : (bounty.rewardValue != null && bounty.rewardValue! > 0
            ? bounty.rewardValue!.toInt()
            : bounty.xpReward);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: const Color(0xFF1B8354).withAlpha(25),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Chore category pastel icon box
                _buildChoreIcon(),
                const SizedBox(width: 14),

                // Chore details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chore Title
                      Text(
                        bounty.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),

                      // Reward & Difficulty Pills
                      Row(
                        children: [
                          const BountyCoinWidget(size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '$rewardDisplay',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _buildDifficultyChip(),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Posted by author • Time ago
                      Text(
                        'Posted by ${bounty.creator.split(' ').first} • ${_formatTimeAgo(bounty.createdAt ?? bounty.claimedAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Trailing Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

