import 'package:flutter/material.dart';

import '../models/bounty.dart';

class GreenButton extends StatelessWidget {
  const GreenButton(
    this.text, {
    super.key,
    this.onPressed,
    this.loading = false,
    this.outlined = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final callback = loading ? null : onPressed;

    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(text, style: const TextStyle(fontWeight: FontWeight.w800));

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: outlined
          ? OutlinedButton(onPressed: callback, child: child)
          : FilledButton(onPressed: callback, child: child),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 180});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/welcome_hero_logo.png',
      width: size,
      height: size,
      cacheWidth: (size * 2).ceil(),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.emoji_events_rounded,
          size: size * 0.6,
          color: const Color(0xFFFFB52E),
        );
      },
    );
  }
}

class BountyTile extends StatelessWidget {
  const BountyTile({super.key, required this.bounty, required this.onTap});

  final Bounty bounty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFDDF5EA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            _icon(bounty.category),
            color: const Color(0xFF087D52),
            size: 29,
          ),
        ),
        title: Text(
          bounty.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '🪙 ${bounty.points}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (bounty.reward.isNotEmpty)
                Text(
                  '🎁 ${bounty.reward}',
                  style: const TextStyle(
                    color: Color(0xFF97421E),
                    fontSize: 12,
                  ),
                ),
              Text(
                bounty.creator.isEmpty
                    ? bounty.category
                    : 'Posted by ${bounty.creator}',
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

IconData _icon(String category) {
  switch (category.toLowerCase()) {
    case 'cleaning':
      return Icons.cleaning_services_rounded;
    case 'laundry':
      return Icons.local_laundry_service_rounded;
    case 'kitchen':
      return Icons.kitchen_rounded;
    case 'groceries':
      return Icons.shopping_basket_rounded;
    case 'maintenance':
      return Icons.handyman_rounded;
    default:
      return Icons.task_alt_rounded;
  }
}

class PageMenuHeader extends StatelessWidget {
  const PageMenuHeader({
    super.key,
    required this.title,
    this.onMenuTap,
    this.trailing,
  });

  final String title;
  final VoidCallback? onMenuTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.menu_rounded,
            color: Color(0xFF1E293B),
            size: 26,
          ),
          onPressed: onMenuTap ?? () => Scaffold.maybeOf(context)?.openDrawer(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

/// Formats a 1-based rank integer as an ordinal string (e.g. 1 -> "1st").
String formatOrdinalRank(int rank) {
  if (rank <= 0) return '—';
  final mod100 = rank % 100;
  if (mod100 >= 11 && mod100 <= 13) return '${rank}th';
  switch (rank % 10) {
    case 1:
      return '${rank}st';
    case 2:
      return '${rank}nd';
    case 3:
      return '${rank}rd';
    default:
      return '${rank}th';
  }
}

class PromptInputDialog extends StatefulWidget {
  const PromptInputDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.initialValue = '',
    this.labelText,
    this.hintText,
    this.confirmLabel = 'Save',
    this.maxLines = 1,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.confirmOutlined = false,
  });

  final String title;
  final String? subtitle;
  final String initialValue;
  final String? labelText;
  final String? hintText;
  final String confirmLabel;
  final int maxLines;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final bool confirmOutlined;

  @override
  State<PromptInputDialog> createState() => _PromptInputDialogState();
}

class _PromptInputDialogState extends State<PromptInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.subtitle != null) ...[
              Text(widget.subtitle!),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _controller,
              autofocus: widget.autofocus,
              maxLines: widget.maxLines,
              textCapitalization: widget.textCapitalization,
              decoration: InputDecoration(
                labelText: widget.labelText,
                hintText: widget.hintText,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (widget.confirmOutlined)
          OutlinedButton(
            onPressed: () => Navigator.pop(context, _controller.text),
            child: Text(widget.confirmLabel),
          )
        else
          FilledButton(
            onPressed: () => Navigator.pop(context, _controller.text),
            child: Text(widget.confirmLabel),
          ),
      ],
    );
  }
}

class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 32);
    path.quadraticBezierTo(size.width / 2, -12, size.width, 32);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
