import 'package:flutter/material.dart';
import '../../models/bounty.dart';
import '../bounty_form/bounty_category_icons.dart';
import 'dashboard_illustrations.dart';

class DashboardBountyCard extends StatelessWidget {
  const DashboardBountyCard({
    super.key,
    required this.bounty,
    required this.onTap,
    this.currentUserId,
    this.currentUserName,
    this.margin,
  });

  final Bounty bounty;
  final VoidCallback onTap;
  final String? currentUserId;
  final String? currentUserName;
  final EdgeInsetsGeometry? margin;

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

  String _formatTimeLeft() {
    final due = bounty.dueAt;
    if (due == null) {
      return 'No due date';
    }

    final now = DateTime.now();
    final diff = due.difference(now);
    if (diff.isNegative || diff.inSeconds <= 0) {
      return '0 Seconds';
    }

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    final parts = <String>[];

    if (days > 0) {
      parts.add('$days ${days > 1 ? "Days" : "Day"}');
    }
    if (hours > 0) {
      parts.add('$hours ${hours > 1 ? "Hours" : "Hour"}');
    }
    if (minutes > 0) {
      parts.add('$minutes ${minutes > 1 ? "Minutes" : "Minute"}');
    } else {
      // Show seconds if the value of minute is 0
      parts.add('$seconds ${seconds == 1 ? "Second" : "Seconds"}');
    }

    return parts.isEmpty ? '0 Seconds' : parts.join(', ');
  }

  Widget _buildChoreIcon() {
    final t = bounty.title.toLowerCase();
    final c = bounty.category.toLowerCase();

    Color bgColor = const Color(0xFFFEF3C7); // Soft peach default
    Widget iconWidget;

    if (t.contains('trash') || t.contains('bin') || t.contains('garbage') || t.contains('rubbish') || c == 'trash') {
      bgColor = const Color(0xFFD1FAE5); // Mint
      iconWidget = const TrashBinWidget(size: 44);
    } else if (t.contains('vacuum') || t.contains('living room') || t.contains('carpet') || t.contains('rug')) {
      bgColor = const Color(0xFFFEF3C7); // Apricot/Peach
      iconWidget = const VacuumCleanerWidget(size: 44);
    } else if (t.contains('laundry') || t.contains('wash') || c == 'laundry' || t.contains('clothes')) {
      bgColor = const Color(0xFFEDE9FE); // Lavender
      iconWidget = const CategoryIconWidget(category: 'Laundry', size: 44);
    } else if (t.contains('clean') || t.contains('sweep') || t.contains('mop') || c == 'cleaning') {
      bgColor = const Color(0xFFFEF3C7); // Peach
      iconWidget = const CategoryIconWidget(category: 'Cleaning', size: 44);
    } else if (t.contains('kitchen') || t.contains('dish') || c == 'kitchen' || c == 'dishes' || t.contains('cook')) {
      bgColor = const Color(0xFFFFEDD5); // Soft orange
      iconWidget = const CategoryIconWidget(category: 'Kitchen', size: 44);
    } else if (t.contains('grocer') || t.contains('shop') || c == 'groceries' || c == 'shopping' || t.contains('market')) {
      bgColor = const Color(0xFFE0F2FE); // Soft blue
      iconWidget = const CategoryIconWidget(category: 'Groceries', size: 44);
    } else if (t.contains('fix') || t.contains('repair') || c == 'maintenance' || t.contains('bulb')) {
      bgColor = const Color(0xFFF1F5F9); // Slate
      iconWidget = const CategoryIconWidget(category: 'Maintenance', size: 44);
    } else {
      bgColor = const Color(0xFFF1F5F9);
      iconWidget = CategoryIconWidget(category: bounty.category, size: 44);
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

  ({String label, IconData icon, Color bgColor, Color fgColor}) _chipSpec() {
    if (bounty.isCompleted) {
      return (
        label: 'Completed',
        icon: Icons.check_circle_rounded,
        bgColor: const Color(0xFFDCFCE7),
        fgColor: const Color(0xFF15803D),
      );
    }
    if (bounty.isCancelled) {
      return (
        label: 'Cancelled',
        icon: Icons.cancel_outlined,
        bgColor: const Color(0xFFFEF2F2),
        fgColor: const Color(0xFFDC2626),
      );
    }
    if (bounty.isClaimed || bounty.isSubmitted) {
      return (
        label: 'Taken',
        icon: Icons.hourglass_bottom_rounded,
        bgColor: const Color(0xFFFEF3C7),
        fgColor: const Color(0xFFB45309),
      );
    }
    if (bounty.isPastDue) {
      return (
        label: 'Past Due',
        icon: Icons.event_busy_rounded,
        bgColor: const Color(0xFFFFF7ED),
        fgColor: const Color(0xFFC2410C),
      );
    }
    if (bounty.dueAt == null) {
      return (
        label: 'No due date',
        icon: Icons.schedule_rounded,
        bgColor: const Color(0xFFF1F5F9),
        fgColor: const Color(0xFF475569),
      );
    }
    return (
      label: _formatTimeLeft(),
      icon: Icons.access_time_rounded,
      bgColor: const Color(0xFFEFF6FF),
      fgColor: const Color(0xFF2563EB),
    );
  }

  Widget _buildTimeLeftChip() {
    final spec = _chipSpec();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: spec.bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            spec.icon,
            size: 11,
            color: spec.fgColor,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              spec.label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: spec.fgColor,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

    final isCreator = (currentUserId != null &&
            currentUserId!.isNotEmpty &&
            bounty.creatorId.isNotEmpty &&
            currentUserId == bounty.creatorId) ||
        (currentUserName != null &&
            currentUserName!.isNotEmpty &&
            bounty.creator.isNotEmpty &&
            currentUserName!.trim().toLowerCase() ==
                bounty.creator.trim().toLowerCase());

    final creatorName = isCreator ? 'you' : bounty.creator.split(' ').first;

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
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

                      // Reward & Time Left Pills
                      Row(
                        children: [
                          const BountyCoinWidget(size: 18),
                          const SizedBox(width: 5),
                          Text(
                            '$rewardDisplay',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: _buildTimeLeftChip(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Posted by author • Time ago
                      Text(
                        'Posted by $creatorName • ${_formatTimeAgo(bounty.createdAt ?? bounty.claimedAt)}',
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

