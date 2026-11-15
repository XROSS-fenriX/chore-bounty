import 'package:flutter/material.dart';
import '../../models/app_notification.dart';
import '../bounty_form/bounty_category_icons.dart';

class CongratulationsDialog extends StatelessWidget {
  const CongratulationsDialog({
    super.key,
    required this.approvals,
    this.onViewLeaderboard,
    this.onClose,
  });

  final List<AppNotification> approvals;
  final VoidCallback? onViewLeaderboard;
  final VoidCallback? onClose;

  static Future<void> show(
    BuildContext context,
    List<AppNotification> approvals, {
    VoidCallback? onViewLeaderboard,
    VoidCallback? onClose,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CongratulationsDialog(
        approvals: approvals,
        onViewLeaderboard: () {
          Navigator.of(dialogContext).pop();
          onViewLeaderboard?.call();
        },
        onClose: () {
          Navigator.of(dialogContext).pop();
          onClose?.call();
        },
      ),
    );
  }

  int _extractTokens(AppNotification n) {
    if (n.tokens != null && n.tokens! > 0) return n.tokens!;
    final match = RegExp(r'\+?(\d+)\s+Tokens?', caseSensitive: false)
        .firstMatch(n.description);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? 0;
    }
    return 0;
  }

  String _extractTitle(AppNotification n) {
    if (n.bountyTitle != null && n.bountyTitle!.trim().isNotEmpty) {
      return n.bountyTitle!.trim();
    }
    final quoted = RegExp(r'"([^"]+)"').firstMatch(n.description);
    if (quoted != null && (quoted.group(1)?.trim().isNotEmpty ?? false)) {
      return quoted.group(1)!.trim();
    }
    return 'Chore';
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1B8354);
    final isSingle = approvals.length <= 1;
    final first = approvals.first;
    final totalTokens = approvals.fold<int>(0, (sum, n) => sum + _extractTokens(n));
    final titles = approvals.map(_extractTitle).toList();
    final approverName = first.actorName?.trim();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: primaryGreen,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              if (isSingle)
                Text(
                  'Your chore "${titles.first}" was approved.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                )
              else ...[
                Text(
                  '${approvals.length} chores approved',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                ...titles.take(3).map(
                      (t) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• $t',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                if (titles.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'and ${titles.length - 3} more',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
              ],
              if (totalTokens > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BountyCoinWidget(size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '+$totalTokens Tokens',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isSingle && approverName != null && approverName.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Approved by $approverName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onViewLeaderboard ?? () => Navigator.of(context).pop(),
                  child: const Text(
                    'View Leaderboard',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: onClose ?? () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
