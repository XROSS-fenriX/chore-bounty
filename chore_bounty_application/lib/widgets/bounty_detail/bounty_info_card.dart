import 'package:flutter/material.dart';
import '../../models/bounty.dart';
import '../avatar/user_avatar_widget.dart';
import '../bounty_form/bounty_category_icons.dart';
import 'bounty_status_chip.dart';

class BountyInfoCard extends StatelessWidget {
  const BountyInfoCard({
    super.key,
    required this.bounty,
    required this.formattedCategory,
    required this.tokenAmount,
    required this.posterName,
    this.creatorAvatar,
    this.onCreatorTap,
  });

  final Bounty bounty;
  final String formattedCategory;
  final int tokenAmount;
  final String posterName;
  final String? creatorAvatar;
  final VoidCallback? onCreatorTap;

  static const _labelStyle = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: Color(0xFF94A3B8),
  );

  static const _valueStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(0xFF0F172A),
  );

  String _formatDueDate(DateTime? due) {
    if (due == null) return 'No due date';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final targetDay = DateTime(due.year, due.month, due.day);

    final hour = due.hour % 12 == 0 ? 12 : due.hour % 12;
    final period = due.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = due.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minuteStr $period';

    if (targetDay == today) return 'Today, $timeStr';
    if (targetDay == tomorrow) return 'Tomorrow, $timeStr';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final monthStr =
        (due.month >= 1 && due.month <= 12) ? months[due.month - 1] : '';

    if (due.year == now.year) {
      return '$monthStr ${due.day}, $timeStr';
    }

    return '$monthStr ${due.day}, ${due.year}, $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final trimmedDescription = bounty.description.trim();
    final hasDescription = trimmedDescription.isNotEmpty;
    final isDatePastDue = bounty.dueAt != null &&
        bounty.dueAt!.isBefore(DateTime.now()) &&
        !bounty.isCompleted &&
        !bounty.isCancelled;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Meta Strip: Status + Token Reward
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BountyStatusChip(bounty: bounty),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BountyCoinWidget(size: 14),
                    const SizedBox(width: 5),
                    Text(
                      '$tokenAmount Tokens',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Hero Header: Category Icon + Title + Creator Attribution
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                alignment: Alignment.center,
                child: CategoryIconWidget(
                  category: formattedCategory,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bounty.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.35,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    InkWell(
                      onTap: onCreatorTap,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            UserAvatarWidget(
                              avatarId: creatorAvatar,
                              userName: posterName,
                              size: 18,
                              onTap: onCreatorTap,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Posted by ',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                posterName,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Description body without heavy divider/heading clutter
          if (hasDescription) ...[
            const SizedBox(height: 14),
            Text(
              trimmedDescription,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Clean Metadata Well: DUE & CATEGORY (no icons)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('DUE', style: _labelStyle),
                        const SizedBox(height: 4),
                        Text(
                          _formatDueDate(bounty.dueAt),
                          style: _valueStyle,
                        ),
                        if (isDatePastDue) ...[
                          const SizedBox(height: 2),
                          const Text(
                            'Past due',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const VerticalDivider(
                    width: 24,
                    thickness: 1,
                    color: Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('CATEGORY', style: _labelStyle),
                        const SizedBox(height: 4),
                        Text(
                          formattedCategory,
                          style: _valueStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
