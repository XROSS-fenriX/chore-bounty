import 'package:flutter/material.dart';
import '../../models/app_notification.dart';
import '../ui.dart';

class RedoRequestedDialog extends StatelessWidget {
  const RedoRequestedDialog({
    super.key,
    required this.redos,
    this.onViewChore,
    this.onClose,
  });

  final List<AppNotification> redos;
  final VoidCallback? onViewChore;
  final VoidCallback? onClose;

  static Future<void> show(
    BuildContext context,
    List<AppNotification> redos, {
    VoidCallback? onViewChore,
    VoidCallback? onClose,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => RedoRequestedDialog(
        redos: redos,
        onViewChore: onViewChore == null
            ? null
            : () {
                Navigator.of(dialogContext).pop();
                onViewChore();
              },
        onClose: () {
          Navigator.of(dialogContext).pop();
          onClose?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const amberAccent = AppModalDialog.warningAmber;
    const amberNoteBg = Color(0xFFFFFBEB);
    const amberNoteBorder = Color(0xFFFDE68A);

    final isSingle = redos.length <= 1;
    final first = redos.first;
    final actorName = first.actorName?.trim();
    final feedback = first.redoFeedback;
    final choreTitle = first.redoChoreTitle;
    final handleClose = onClose ?? () => Navigator.of(context).pop();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: AppModalDialog(
        title: 'Redo Requested',
        secondaryLabel: onViewChore != null ? 'Close' : null,
        onSecondary: onViewChore != null ? handleClose : null,
        primaryLabel: onViewChore != null ? 'View Chore' : 'Close',
        primaryColor: amberAccent,
        onPrimary: onViewChore ?? handleClose,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSingle) ...[
              Text(
                actorName != null && actorName.isNotEmpty
                    ? '$actorName requested a redo on "$choreTitle".'
                    : 'Your chore "$choreTitle" was returned for a redo.',
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: Color(0xFF475569),
                ),
              ),
              if (feedback != null && feedback.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: amberNoteBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: amberNoteBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 14,
                            color: amberAccent,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'MESSAGE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: amberAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        feedback,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              Text(
                '${redos.length} chores returned for redo',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 10),
              ...redos.take(3).map(
                (item) {
                  final note = item.redoFeedback;
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: amberNoteBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: amberNoteBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.redoChoreTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (note != null && note.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            note,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF475569),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              if (redos.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'and ${redos.length - 3} more',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
