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
      'assets/images/chore_bounty_app_logo.jpg',
      width: size,
      height: size,
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
