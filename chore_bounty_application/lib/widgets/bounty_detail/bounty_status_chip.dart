import 'package:flutter/material.dart';
import '../../models/bounty.dart';

class BountyStatusChip extends StatelessWidget {
  const BountyStatusChip({
    super.key,
    required this.bounty,
  });

  final Bounty bounty;

  @override
  Widget build(BuildContext context) {
    final (String label, Color bgColor, Color textColor) = switch (true) {
      _ when bounty.isCancelled => (
          'Cancelled',
          const Color(0xFFFEF2F2),
          const Color(0xFFDC2626),
        ),
      _ when bounty.isCompleted => (
          'Completed',
          const Color(0xFFDCFCE7),
          const Color(0xFF15803D),
        ),
      _ when bounty.isSubmitted => (
          'Awaiting Review',
          const Color(0xFFEEF2FF),
          const Color(0xFF4338CA),
        ),
      _ when bounty.isTaken => (
          'Taken',
          const Color(0xFFFEF3C7),
          const Color(0xFFB45309),
        ),
      _ when bounty.isExpired => (
          'Past Due',
          const Color(0xFFFFF7ED),
          const Color(0xFFC2410C),
        ),
      _ => (
          'Available',
          const Color(0xFFECFDF5),
          const Color(0xFF1B8354),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
