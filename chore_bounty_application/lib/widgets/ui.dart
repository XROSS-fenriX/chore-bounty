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
    final radius = BorderRadius.circular(size * 0.24);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular((size * 0.24) - 1),
        child: Image.asset(
          'assets/images/chore_bounty_icon.png',
          width: size,
          height: size,
          cacheWidth: (size * 2).ceil(),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.emoji_events_rounded,
              size: size * 0.6,
              color: const Color(0xFFFFB52E),
            );
          },
        ),
      ),
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

class AppModalDialog extends StatelessWidget {
  const AppModalDialog({
    super.key,
    required this.title,
    required this.content,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryColor = const Color(0xFF1B8354),
    this.primaryForegroundColor = Colors.white,
    this.primaryBorderColor,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final Widget content;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final Color primaryColor;
  final Color primaryForegroundColor;
  final Color? primaryBorderColor;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  static const Color primaryGreen = Color(0xFF1B8354);
  static const Color dangerRed = Color(0xFFDC2626);
  static const Color warningAmber = Color(0xFFB45309);

  @override
  Widget build(BuildContext context) {
    final primaryButton = FilledButton(
      onPressed: onPrimary,
      style: FilledButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: primaryForegroundColor,
        elevation: 0,
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: primaryBorderColor == null
              ? BorderSide.none
              : BorderSide(color: primaryBorderColor!),
        ),
      ),
      child: Text(
        primaryLabel,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
          letterSpacing: -0.3,
        ),
      ),
      content: SizedBox(width: double.maxFinite, child: content),
      actions: [
        if (secondaryLabel != null)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSecondary ?? () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    elevation: 0,
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    secondaryLabel!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: primaryButton),
            ],
          )
        else
          SizedBox(width: double.infinity, child: primaryButton),
      ],
    );
  }
}

class ConfirmActionDialog {
  const ConfirmActionDialog._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String cancelLabel = 'Cancel',
    required String confirmLabel,
    Color confirmColor = AppModalDialog.primaryGreen,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppModalDialog(
        title: title,
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: Color(0xFF475569),
          ),
        ),
        secondaryLabel: cancelLabel,
        onSecondary: () => Navigator.pop(dialogContext, false),
        primaryLabel: confirmLabel,
        primaryColor: confirmColor,
        onPrimary: () => Navigator.pop(dialogContext, true),
      ),
    );
    return result == true;
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
    this.minLines,
    this.maxLines = 1,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.confirmOutlined = false,
    this.accentColor,
    this.confirmBackgroundColor,
    this.confirmForegroundColor,
    this.confirmBorderColor,
  });

  final String title;
  final String? subtitle;
  final String initialValue;
  final String? labelText;
  final String? hintText;
  final String confirmLabel;
  final int? minLines;
  final int maxLines;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final bool confirmOutlined;
  final Color? accentColor;
  final Color? confirmBackgroundColor;
  final Color? confirmForegroundColor;
  final Color? confirmBorderColor;

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
    final accentColor = widget.accentColor ?? AppModalDialog.primaryGreen;
    final confirmFg = widget.confirmForegroundColor ??
        (widget.confirmOutlined ? accentColor : Colors.white);
    final confirmBg = widget.confirmBackgroundColor ??
        (widget.confirmOutlined ? const Color(0xFFECFDF5) : accentColor);
    final confirmBorder = widget.confirmBorderColor ??
        (widget.confirmOutlined
            ? accentColor.withValues(alpha: 0.3)
            : null);

    return AppModalDialog(
      title: widget.title,
      secondaryLabel: 'Cancel',
      onSecondary: () => Navigator.pop(context),
      primaryLabel: widget.confirmLabel,
      primaryColor: confirmBg,
      primaryForegroundColor: confirmFg,
      primaryBorderColor: confirmBorder,
      onPrimary: () => Navigator.pop(context, _controller.text),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.subtitle != null) ...[
            Text(
              widget.subtitle!,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _controller,
            autofocus: widget.autofocus,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            textCapitalization: widget.textCapitalization,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              labelText: widget.labelText,
              labelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
              hintText: widget.hintText,
              hintStyle: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
        ],
      ),
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
