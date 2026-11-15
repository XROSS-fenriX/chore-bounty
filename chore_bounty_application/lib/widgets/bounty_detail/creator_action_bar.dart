import 'package:flutter/material.dart';
import '../../models/bounty.dart';

class CreatorActionBar extends StatelessWidget {
  const CreatorActionBar({
    super.key,
    required this.bounty,
    required this.onEdit,
    required this.onCancel,
    required this.onDelete,
  });

  final Bounty bounty;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  static const _primaryGreen = Color(0xFF1B8354);

  @override
  Widget build(BuildContext context) {
    if (bounty.isAvailable) {
      return Row(
        children: [
          _buildButton(
            label: 'Edit',
            icon: Icons.edit_outlined,
            bgColor: _primaryGreen,
            fgColor: Colors.white,
            onPressed: onEdit,
          ),
          const SizedBox(width: 10),
          _buildButton(
            label: 'Delete',
            icon: Icons.delete_outline_rounded,
            bgColor: const Color(0xFFFEF2F2),
            fgColor: const Color(0xFFDC2626),
            borderColor: const Color(0xFFFCA5A5),
            onPressed: onDelete,
          ),
        ],
      );
    }

    if (bounty.isTaken) {
      return Row(
        children: [
          _buildButton(
            label: 'Edit',
            icon: Icons.edit_outlined,
            bgColor: _primaryGreen,
            fgColor: Colors.white,
            onPressed: onEdit,
          ),
          const SizedBox(width: 10),
          _buildButton(
            label: 'Cancel',
            icon: Icons.cancel_outlined,
            bgColor: const Color(0xFFF8FAFC),
            fgColor: const Color(0xFF475569),
            borderColor: const Color(0xFFCBD5E1),
            onPressed: onCancel,
          ),
        ],
      );
    }

    if (bounty.isCancelled || bounty.isExpired) {
      return Row(
        children: [
          _buildButton(
            label: 'Delete',
            icon: Icons.delete_outline_rounded,
            bgColor: const Color(0xFFFEF2F2),
            fgColor: const Color(0xFFDC2626),
            borderColor: const Color(0xFFFCA5A5),
            onPressed: onDelete,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color fgColor,
    Color? borderColor,
    required VoidCallback onPressed,
  }) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    const padding = EdgeInsets.symmetric(horizontal: 12);
    final child = Text(
      label,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Expanded(
      child: SizedBox(
        height: 48,
        child: borderColor != null
            ? OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: fgColor,
                  backgroundColor: bgColor,
                  side: BorderSide(color: borderColor, width: 1.2),
                  padding: padding,
                  shape: shape,
                ),
                onPressed: onPressed,
                icon: Icon(icon, size: 17),
                label: child,
              )
            : ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: bgColor,
                  foregroundColor: fgColor,
                  elevation: 0,
                  padding: padding,
                  shape: shape,
                ),
                onPressed: onPressed,
                icon: Icon(icon, size: 17),
                label: child,
              ),
      ),
    );
  }
}
