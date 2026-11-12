import 'package:flutter/material.dart';
import '../../models/bounty.dart';
import 'dashboard_bounty_card.dart';

/// Renders a list of [DashboardBountyCard] widgets directly, or a styled empty
/// state card when [bounties] is empty.
class DashboardChoreList extends StatelessWidget {
  const DashboardChoreList({
    super.key,
    required this.bounties,
    required this.currentUserId,
    required this.currentUserName,
    required this.onSelectBounty,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.showPostButton = false,
    this.onCreateBounty,
  });

  final List<Bounty> bounties;
  final String currentUserId;
  final String currentUserName;
  final ValueChanged<Bounty> onSelectBounty;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final bool showPostButton;
  final VoidCallback? onCreateBounty;

  @override
  Widget build(BuildContext context) {
    if (bounties.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.4),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(emptyIcon, size: 36, color: const Color(0xFF94A3B8)),
              const SizedBox(height: 8),
              Text(
                emptyTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                emptySubtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
                textAlign: TextAlign.center,
              ),
              if (showPostButton && onCreateBounty != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onCreateBounty,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Post a Bounty'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1B8354),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      children: bounties.asMap().entries.map((entry) {
        final isLast = entry.key == bounties.length - 1;
        return DashboardBountyCard(
          bounty: entry.value,
          currentUserId: currentUserId,
          currentUserName: currentUserName,
          onTap: () => onSelectBounty(entry.value),
          margin: isLast ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
        );
      }).toList(),
    );
  }
}

