import 'package:flutter/material.dart';

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
