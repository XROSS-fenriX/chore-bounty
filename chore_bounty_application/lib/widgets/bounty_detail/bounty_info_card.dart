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
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: Color(0xFF94A3B8),
  );

  static const _valueStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1E293B),
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
      padding: const EdgeInsets.all(18),
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
          // Header: Category Icon + Title/Status + Meta Line
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: CategoryIconWidget(
                  category: formattedCategory,
                  size: 38,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            bounty.title,
                            style: const TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        BountyStatusChip(bounty: bounty),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const BountyCoinWidget(size: 16),
                            const SizedBox(width: 5),
                            Text(
                              '$tokenAmount Tokens',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          '·',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        InkWell(
                          onTap: onCreatorTap,
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              UserAvatarWidget(
                                avatarId: creatorAvatar,
                                userName: posterName,
                                size: 18,
                                onTap: onCreatorTap,
                              ),
                              const SizedBox(width: 5),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 160),
                                child: Text(
                                  posterName,
                                  style: const TextStyle(
                                    fontSize: 13,
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
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Optional Description
          if (hasDescription) ...[
            const Divider(
              color: Color(0xFFE2E8F0),
              height: 28,
              thickness: 1,
            ),
            const Text('DESCRIPTION', style: _labelStyle),
            const SizedBox(height: 6),
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

          // Metadata Row: DUE & CATEGORY
          const Divider(
            color: Color(0xFFE2E8F0),
            height: 28,
            thickness: 1,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DUE', style: _labelStyle),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDueDate(bounty.dueAt),
                                style: _valueStyle,
                              ),
                              if (isDatePastDue) ...[
                                const SizedBox(height: 2),
                                const Text(
                                  'Past due',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CATEGORY', style: _labelStyle),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.tag_rounded,
                          size: 15,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            formattedCategory,
                            style: _valueStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
